import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  StoragePaths? _storagePaths;
  AppSettings _currentSettings = const AppSettings.initial();

  StoragePaths get storagePaths => _storagePaths!;
  AppSettings get currentSettings => _currentSettings;

  Future<AppSettings> ensureInitialized() async {
    _storagePaths ??= await _localDataSource.ensureStoragePaths();
    _currentSettings = await _localDataSource.loadSettings(_storagePaths!);
    return _currentSettings;
  }

  Future<AppSettings> reload() async {
    final paths = _storagePaths ?? await _localDataSource.ensureStoragePaths();
    _storagePaths = paths;
    _currentSettings = await _localDataSource.loadSettings(paths);
    return _currentSettings;
  }

  Future<void> save(AppSettings settings) async {
    final paths = _storagePaths ?? await _localDataSource.ensureStoragePaths();
    _storagePaths = paths;
    await _localDataSource.saveSettings(paths, settings);
    _currentSettings = settings;
  }
}
