param(
    [string]$Version,
    [string]$BuildNumber = "",
    [switch]$SkipAnalyze,
    [switch]$SkipInstaller
)

$ErrorActionPreference = "Stop"

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw $ErrorMessage
    }
}

function Get-PubspecVersion {
    $pubspecPath = Join-Path $PSScriptRoot "..\pubspec.yaml"
    $versionLine = Select-String -Path $pubspecPath -Pattern '^version:\s*(.+)$' | Select-Object -First 1
    if (-not $versionLine) {
        throw "Could not read version from pubspec.yaml"
    }

    $rawVersion = $versionLine.Matches[0].Groups[1].Value.Trim()
    if ($rawVersion.Contains("+")) {
        $parts = $rawVersion.Split("+", 2)
        return @{
            Name = $parts[0]
            Number = $parts[1]
        }
    }

    return @{
        Name = $rawVersion
        Number = ""
    }
}

function Resolve-InnoSetupPath {
    $candidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Assert-FileExists {
    param(
        [string]$Path,
        [string]$ErrorMessage
    )

    if (-not (Test-Path $Path)) {
        throw $ErrorMessage
    }
}

function Assert-AndroidSigningConfig {
    $keyPropertiesPath = Join-Path $repoRoot "android\key.properties"
    Assert-FileExists `
        -Path $keyPropertiesPath `
        -ErrorMessage "Missing android\key.properties. Create it from android\key.properties.example before running a release build."

    $keyProperties = @{}
    foreach ($line in Get-Content $keyPropertiesPath) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            continue
        }

        $pair = $line -split '=', 2
        if ($pair.Count -eq 2) {
            $keyProperties[$pair[0].Trim()] = $pair[1].Trim()
        }
    }

    foreach ($requiredKey in @("storePassword", "keyPassword", "keyAlias", "storeFile")) {
        if (-not $keyProperties.ContainsKey($requiredKey) -or [string]::IsNullOrWhiteSpace($keyProperties[$requiredKey])) {
            throw "android\key.properties is missing required '$requiredKey' value."
        }
    }

    $storeFilePath = $keyProperties["storeFile"]
    if (-not [System.IO.Path]::IsPathRooted($storeFilePath)) {
        $storeFilePath = Join-Path (Join-Path $repoRoot "android\app") $storeFilePath
    }

    $storeFilePath = [System.IO.Path]::GetFullPath($storeFilePath)

    Assert-FileExists `
        -Path $storeFilePath `
        -ErrorMessage "Android keystore file was not found at '$storeFilePath'."
}

function Get-DefaultBuildNumber {
    $now = Get-Date
    return "{0}{1:D3}{2:00}{3:00}" -f ($now.Year % 100), $now.DayOfYear, $now.Hour, $now.Minute
}

function Assert-BuildNumber {
    param(
        [string]$Value
    )

    if ($Value -notmatch '^\d+$') {
        throw "Build number '$Value' must contain digits only."
    }

    $numericValue = [int64]$Value
    if ($numericValue -gt 2100000000) {
        throw "Build number '$Value' is greater than the Android maximum allowed value of 2100000000."
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$innoConfigPath = Join-Path $repoRoot "inno_bundle.yaml"
$distDir = Join-Path $repoRoot "dist"
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$pubspecVersion = Get-PubspecVersion
$releaseVersion = if ([string]::IsNullOrWhiteSpace($Version)) { $pubspecVersion.Name } else { $Version }
$releaseBuildNumber = if ([string]::IsNullOrWhiteSpace($BuildNumber)) {
    if ([string]::IsNullOrWhiteSpace($pubspecVersion.Number)) {
        Get-DefaultBuildNumber
    } else {
        $pubspecVersion.Number
    }
} else {
    $BuildNumber
}
Assert-BuildNumber -Value $releaseBuildNumber

$releaseFolderName = "$releaseVersion+$releaseBuildNumber"
$releaseDir = Join-Path $distDir $releaseFolderName
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

Write-Host "Preparing release build for version $releaseVersion+$releaseBuildNumber"

Push-Location $repoRoot
try {
    Assert-AndroidSigningConfig
    Assert-FileExists `
        -Path $innoConfigPath `
        -ErrorMessage "Missing inno_bundle.yaml in the repository root."

    Invoke-CheckedCommand `
        -Command { flutter clean } `
        -ErrorMessage "flutter clean failed."
    Invoke-CheckedCommand `
        -Command { flutter pub get } `
        -ErrorMessage "flutter pub get failed."

    if (-not $SkipAnalyze) {
        Invoke-CheckedCommand `
            -Command { flutter analyze } `
            -ErrorMessage "flutter analyze failed."
    }

    Invoke-CheckedCommand `
        -Command { flutter build apk --release --build-name $releaseVersion --build-number $releaseBuildNumber } `
        -ErrorMessage "flutter build apk failed."
    Invoke-CheckedCommand `
        -Command { flutter build windows --release --build-name $releaseVersion --build-number $releaseBuildNumber } `
        -ErrorMessage "flutter build windows failed."

    $apkPath = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-release.apk"
    $portableDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
    $portableZip = Join-Path $releaseDir "LightshotParser-Windows-$releaseVersion-portable.zip"
    $versionedApk = Join-Path $releaseDir "LightshotParser-$releaseVersion.apk"

    Copy-Item $apkPath $versionedApk -Force
    if (Test-Path $portableZip) {
        Remove-Item $portableZip -Force
    }
    Compress-Archive -Path (Join-Path $portableDir "*") -DestinationPath $portableZip

    if (-not $SkipInstaller) {
        $isccPath = Resolve-InnoSetupPath
        if ($null -eq $isccPath) {
            throw "Inno Setup 6 was not found. Install it before building the Windows installer."
        }

        $installerBuildDir = Join-Path $repoRoot "build\windows\x64\installer\Release"
        if (Test-Path $installerBuildDir) {
            Remove-Item $installerBuildDir -Recurse -Force
        }

        Invoke-CheckedCommand `
            -Command {
                dart run inno_bundle `
                    --path $innoConfigPath `
                    --no-app `
                    --app-version $releaseVersion `
                    --no-install-inno `
                    --no-gen-app-id `
                    --no-gen-publisher `
                    --no-hf
            } `
            -ErrorMessage "dart run inno_bundle failed."

        $installerArtifact = Get-ChildItem $installerBuildDir -Filter "*-Installer.exe" |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1

        if ($null -eq $installerArtifact) {
            throw "inno_bundle completed without producing a Windows installer .exe file."
        }

        Copy-Item `
            $installerArtifact.FullName `
            (Join-Path $releaseDir $installerArtifact.Name) `
            -Force
    }

    Write-Host "Release artifacts are available in $releaseDir"
}
finally {
    Pop-Location
}
