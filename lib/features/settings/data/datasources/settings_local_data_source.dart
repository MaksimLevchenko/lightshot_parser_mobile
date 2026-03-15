import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/app_settings.dart';

class SettingsLocalDataSource {
  Future<StoragePaths> ensureStoragePaths() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cacheDir = await getApplicationCacheDirectory();

    final photosDirectory = Directory('${cacheDir.path}/Photos');
    final databaseDirectory = Directory(appDocDir.path);
    final settingsDirectory = Directory('${appDocDir.path}/lightshot_parser');

    await photosDirectory.create(recursive: true);
    await databaseDirectory.create(recursive: true);
    await settingsDirectory.create(recursive: true);

    return StoragePaths(
      photosDirectory: photosDirectory,
      databaseDirectory: databaseDirectory,
      settingsDirectory: settingsDirectory,
    );
  }

  Future<AppSettings> loadSettings(StoragePaths paths) async {
    final file = File('${paths.settingsDirectory.path}/settings.json');
    if (!await file.exists()) {
      return const AppSettings.initial();
    }

    try {
      final jsonString = await file.readAsString();
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(jsonMap);
    } on Object {
      return const AppSettings.initial();
    }
  }

  Future<void> saveSettings(StoragePaths paths, AppSettings settings) async {
    final file = File('${paths.settingsDirectory.path}/settings.json');
    await file.create(recursive: true);
    await file.writeAsString(json.encode(settings.toJson()));
  }
}
