import 'dart:io';

import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_database_service.dart';

class GalleryLocalDataSource {
  GalleryLocalDataSource({
    GalleryDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? GalleryDatabaseService();

  final GalleryDatabaseService _databaseService;

  Future<Set<String>> loadTrackedIds(StoragePaths paths) async {
    return _databaseService.loadTrackedIds(paths);
  }

  Future<void> overwriteTrackedIds(
      StoragePaths paths, Iterable<String> ids) async {
    await _databaseService.replaceTrackedIds(paths, ids);
  }

  Future<void> overwriteTrackedItems(
    StoragePaths paths,
    Iterable<GalleryItem> items,
  ) async {
    await _databaseService.replaceTrackedItems(paths, items);
  }

  Future<void> appendTrackedId(StoragePaths paths, String id) async {
    await _databaseService.insertTrackedId(paths, id);
  }

  Future<void> upsertGalleryItem(StoragePaths paths, GalleryItem item) async {
    await _databaseService.upsertGalleryItem(paths, item);
  }

  Future<void> updateClassification(
    StoragePaths paths, {
    required GalleryItem item,
  }) async {
    await _databaseService.updateClassification(
      paths,
      trackingKey: item.trackingKey,
      classificationResult: item.classificationResult,
    );
  }

  Future<List<GalleryItem>> loadItems(StoragePaths paths) async {
    final storedItems = await _databaseService.loadStoredGalleryItems(paths);
    final entities = await paths.photosDirectory.list().toList();
    entities.sort((first, second) {
      final firstStat = first.statSync();
      final secondStat = second.statSync();
      return secondStat.modified.compareTo(firstStat.modified);
    });

    return entities.whereType<File>().map((file) {
      final fallbackItem = GalleryItem.fromFile(file);
      final storedItem = storedItems[fallbackItem.trackingKey];
      if (storedItem == null) {
        return fallbackItem;
      }
      return storedItem.copyWith(path: file.path);
    }).toList(growable: false);
  }

  Future<void> deleteItem(GalleryItem item) async {
    final file = File(item.path);
    if (await file.exists()) {
      await file.delete();
    } else {
      throw const StorageException('Image file not found');
    }
  }

  Future<void> clearImages(StoragePaths paths) async {
    final entities = await paths.photosDirectory.list().toList();
    for (final entity in entities) {
      await entity.delete(recursive: true);
    }
  }

  Future<void> copyDownloadedFile({
    required String sourcePath,
    required String targetPath,
  }) async {
    await File(sourcePath).copy(targetPath);
  }

  Future<void> close() async {
    await _databaseService.close();
  }
}
