import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';

import '../../../support/test_storage.dart';

void main() {
  late TestStorageContext storageContext;
  late GalleryLocalDataSource localDataSource;
  late GalleryRepository galleryRepository;

  setUp(() async {
    storageContext = await createTestStorageContext();
    final settingsRepository = SettingsRepository(
      TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
    );
    await settingsRepository.ensureInitialized();
    localDataSource = GalleryLocalDataSource();
    galleryRepository = GalleryRepository(
      settingsRepository: settingsRepository,
      localDataSource: localDataSource,
    );
    await galleryRepository.ensureInitialized();
  });

  tearDown(() async {
    await galleryRepository.dispose();
    await storageContext.dispose();
  });

  test('clearImages removes files and resets tracked ids', () async {
    final file =
        File('${storageContext.storagePaths.photosDirectory.path}/abc123.jpg');
    await file.writeAsString('binary-data');
    await galleryRepository.markProcessed(
      buildTrackingKey(DownloadSource.lightshot, 'abc123'),
    );

    await galleryRepository.clearImages();

    final remainingFiles =
        await storageContext.storagePaths.photosDirectory.list().toList();
    expect(remainingFiles, isEmpty);
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.lightshot, 'abc123'),
      ),
      isFalse,
    );
  });

  test('rebuildIndex rewrites tracked ids from existing files', () async {
    await localDataSource.overwriteTrackedIds(
      storageContext.storagePaths,
      ['stale-id'],
    );
    await File(
      '${storageContext.storagePaths.photosDirectory.path}/lightshot@@fresh_a.jpg',
    ).writeAsString('a');
    await File(
      '${storageContext.storagePaths.photosDirectory.path}/imgur@@fresh_b.png',
    ).writeAsString('b');
    await File(
      '${storageContext.storagePaths.photosDirectory.path}/legacy_c.webp',
    ).writeAsString('c');

    await galleryRepository.rebuildIndex();

    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.lightshot, 'fresh_a'),
      ),
      isTrue,
    );
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.imgur, 'fresh_b'),
      ),
      isTrue,
    );
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.lightshot, 'legacy_c'),
      ),
      isTrue,
    );
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.lightshot, 'stale-id'),
      ),
      isFalse,
    );
  });

  test('legacy db.txt is migrated into sqlite storage', () async {
    final legacyFile =
        File('${storageContext.storagePaths.databaseDirectory.path}/db.txt');
    await legacyFile.writeAsString('legacy_one\nimgur@@legacy_two\n');

    final trackedIds = await localDataSource.loadTrackedIds(
      storageContext.storagePaths,
    );

    expect(
      trackedIds,
      {
        buildTrackingKey(DownloadSource.lightshot, 'legacy_one'),
        buildTrackingKey(DownloadSource.imgur, 'legacy_two'),
      },
    );
    expect(await legacyFile.exists(), isFalse);

    final persistedIds = await localDataSource.loadTrackedIds(
      storageContext.storagePaths,
    );
    expect(persistedIds, trackedIds);
  });
}
