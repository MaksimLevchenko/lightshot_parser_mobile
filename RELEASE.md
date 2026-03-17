# Release Automation

This repository can build:

- Android release APK
- Windows portable release ZIP
- Windows installer EXE via `inno_bundle`

## Local release build

1. Create `android/key.properties` from `android/key.properties.example`.
2. Put the release keystore on disk and update `storeFile`.
3. Install Inno Setup 6.
4. Run:

```powershell
.\scripts\build_release.ps1
```

Optional:

```powershell
.\scripts\build_release.ps1 -Version 2.0.0 -BuildNumber 200
```

Artifacts are written to `dist/<version>+<buildNumber>/`.

The release script:

- validates Android signing before building;
- builds the Android APK;
- builds the Windows app bundle;
- creates a portable Windows ZIP;
- runs `dart run inno_bundle --path inno_bundle.yaml` to create the installer;
- copies all final artifacts into `dist/<version>+<buildNumber>/`.

Expected artifacts:

- `LightshotParser-<version>.apk`
- `LightshotParser-Windows-<version>-portable.zip`
- `*-Installer.exe`
