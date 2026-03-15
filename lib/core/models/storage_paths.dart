import 'dart:io';

class StoragePaths {
  const StoragePaths({
    required this.photosDirectory,
    required this.databaseDirectory,
    required this.settingsDirectory,
  });

  final Directory photosDirectory;
  final Directory databaseDirectory;
  final Directory settingsDirectory;
}
