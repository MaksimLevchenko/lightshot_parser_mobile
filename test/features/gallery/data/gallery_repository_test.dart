import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';

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

  test('classification metadata persists from pending to completed', () async {
    final file = File(
      '${storageContext.storagePaths.photosDirectory.path}/lightshot@@classified.png',
    );
    await _writePngFile(file);
    final pendingItem = GalleryItem.fromFile(
      file,
      classificationResult: ClassificationResult.pending(backend: 'mock'),
    );

    await galleryRepository.addDownloadedFile(item: pendingItem);

    final pendingItems = await galleryRepository.load();
    expect(pendingItems.single.classificationResult.status,
        ClassificationStatus.pending);

    final completedItem = pendingItem.copyWith(
      classificationResult: ClassificationResult.completed(
        category: ClassificationCategory.games,
        confidence: 0.93,
        rawScores: const ClassificationScores(
          nsfw: 0.1,
          documents: 0.2,
          games: 0.93,
        ),
        backend: 'mock',
        classifiedAt: DateTime(2026, 3, 15),
      ),
    );

    await galleryRepository.updateClassification(item: completedItem);

    final completedItems = await galleryRepository.load();
    expect(
      completedItems.single.classificationResult.category,
      ClassificationCategory.games,
    );
    expect(
      completedItems.single.classificationResult.confidence,
      0.93,
    );
  });
}

Future<void> _writePngFile(File file) async {
  const bytes = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0xF8,
    0xCF,
    0xC0,
    0x00,
    0x00,
    0x03,
    0x01,
    0x01,
    0x00,
    0x18,
    0xDD,
    0x8D,
    0xB1,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];
  await file.writeAsBytes(bytes, flush: true);
}
