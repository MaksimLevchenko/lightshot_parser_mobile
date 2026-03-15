import 'dart:io';

import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/app_settings.dart';

class TestStorageContext {
  TestStorageContext({
    required this.rootDirectory,
    required this.storagePaths,
  });

  final Directory rootDirectory;
  final StoragePaths storagePaths;

  Future<void> dispose() async {
    if (await rootDirectory.exists()) {
      await rootDirectory.delete(recursive: true);
    }
  }
}

Future<TestStorageContext> createTestStorageContext() async {
  final rootDirectory = await Directory.systemTemp.createTemp('lpm_test_');
  final photosDirectory = Directory('${rootDirectory.path}/photos');
  final databaseDirectory = Directory('${rootDirectory.path}/database');
  final settingsDirectory = Directory('${rootDirectory.path}/settings');

  await photosDirectory.create(recursive: true);
  await databaseDirectory.create(recursive: true);
  await settingsDirectory.create(recursive: true);

  return TestStorageContext(
    rootDirectory: rootDirectory,
    storagePaths: StoragePaths(
      photosDirectory: photosDirectory,
      databaseDirectory: databaseDirectory,
      settingsDirectory: settingsDirectory,
    ),
  );
}

class TestSettingsLocalDataSource extends SettingsLocalDataSource {
  TestSettingsLocalDataSource({
    required this.storagePaths,
    this.initialSettings = const AppSettings.initial(),
  }) : _storedSettings = initialSettings;

  final StoragePaths storagePaths;
  final AppSettings initialSettings;

  AppSettings _storedSettings;

  @override
  Future<StoragePaths> ensureStoragePaths() async => storagePaths;

  @override
  Future<AppSettings> loadSettings(StoragePaths paths) async => _storedSettings;

  @override
  Future<void> saveSettings(StoragePaths paths, AppSettings settings) async {
    _storedSettings = settings;
  }
}

class FailingSettingsLocalDataSource extends TestSettingsLocalDataSource {
  FailingSettingsLocalDataSource({
    required super.storagePaths,
    super.initialSettings,
  });

  @override
  Future<void> saveSettings(StoragePaths paths, AppSettings settings) {
    throw const FileSystemException('save failed');
  }
}
