import 'dart:io';

import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

class GalleryLocalDataSource {
  Future<File> _dbFile(StoragePaths paths) async {
    final file = File('${paths.databaseDirectory.path}/db.txt');
    await file.create(recursive: true);
    return file;
  }

  Future<Set<String>> loadTrackedIds(StoragePaths paths) async {
    final file = await _dbFile(paths);
    final lines = await file.readAsLines();
    return lines.where((line) => line.trim().isNotEmpty).toSet();
  }

  Future<void> overwriteTrackedIds(
      StoragePaths paths, Iterable<String> ids) async {
    final file = await _dbFile(paths);
    final sortedIds = ids.toList()..sort();
    await file.writeAsString(
      sortedIds.isEmpty ? '' : '${sortedIds.join('\n')}\n',
      mode: FileMode.write,
    );
  }

  Future<void> appendTrackedId(StoragePaths paths, String id) async {
    final file = await _dbFile(paths);
    await file.writeAsString('$id\n', mode: FileMode.append);
  }

  Future<List<GalleryItem>> loadItems(StoragePaths paths) async {
    final entities = await paths.photosDirectory.list().toList();
    entities.sort((first, second) {
      final firstStat = first.statSync();
      final secondStat = second.statSync();
      return secondStat.modified.compareTo(firstStat.modified);
    });

    return entities
        .whereType<File>()
        .map(GalleryItem.fromFile)
        .toList(growable: false);
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
}
