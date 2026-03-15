import 'dart:async';
import 'dart:io';

import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';

class GalleryRepository {
  GalleryRepository({
    required SettingsRepository settingsRepository,
    required GalleryLocalDataSource localDataSource,
  })  : _settingsRepository = settingsRepository,
        _localDataSource = localDataSource;

  final SettingsRepository _settingsRepository;
  final GalleryLocalDataSource _localDataSource;
  final StreamController<List<GalleryItem>> _itemsController =
      StreamController<List<GalleryItem>>.broadcast();

  Set<String> _trackedIds = <String>{};

  Stream<List<GalleryItem>> watch() => _itemsController.stream;
  Directory get photosDirectory =>
      _settingsRepository.storagePaths.photosDirectory;

  Future<void> ensureInitialized() async {
    _trackedIds = await _localDataSource.loadTrackedIds(
      _settingsRepository.storagePaths,
    );
    await refresh();
  }

  Future<List<GalleryItem>> load() {
    return _localDataSource.loadItems(_settingsRepository.storagePaths);
  }

  Future<void> refresh() async {
    final items = await load();
    if (!_itemsController.isClosed) {
      _itemsController.add(items);
    }
  }

  Future<bool> isProcessed(String trackingKey) async {
    if (_trackedIds.isEmpty) {
      _trackedIds = await _localDataSource.loadTrackedIds(
        _settingsRepository.storagePaths,
      );
    }
    return _trackedIds.contains(trackingKey);
  }

  Future<void> markProcessed(String trackingKey) async {
    if (_trackedIds.add(trackingKey)) {
      await _localDataSource.appendTrackedId(
        _settingsRepository.storagePaths,
        trackingKey,
      );
    }
  }

  Future<void> addDownloadedFile({
    required GalleryItem item,
  }) async {
    await markProcessed(item.trackingKey);
    await refresh();
  }

  Future<void> deleteItem(GalleryItem item) async {
    await _localDataSource.deleteItem(item);
    await refresh();
  }

  Future<void> clearImages() async {
    await _localDataSource.clearImages(_settingsRepository.storagePaths);
    _trackedIds = <String>{};
    await _localDataSource.overwriteTrackedIds(
      _settingsRepository.storagePaths,
      _trackedIds,
    );
    await refresh();
  }

  Future<void> rebuildIndex() async {
    final items = await load();
    _trackedIds = items.map((item) => item.trackingKey).toSet();
    await _localDataSource.overwriteTrackedIds(
      _settingsRepository.storagePaths,
      _trackedIds,
    );
    if (!_itemsController.isClosed) {
      _itemsController.add(items);
    }
  }

  Future<String> saveImageToDownloads(
      GalleryItem item, Directory downloadDir) async {
    final sourceFile = File(item.path);
    if (!await sourceFile.exists()) {
      throw const StorageException();
    }
    final fileName = item.path.split(Platform.pathSeparator).last;
    final targetPath = '${downloadDir.path}${Platform.pathSeparator}$fileName';
    await downloadDir.create(recursive: true);
    await _localDataSource.copyDownloadedFile(
      sourcePath: item.path,
      targetPath: targetPath,
    );
    return targetPath;
  }

  Future<void> dispose() async {
    await _localDataSource.close();
    await _itemsController.close();
  }
}
