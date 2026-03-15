import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/imgur_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/lightshot_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/repositories/download_repository.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/imgur_download_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/lightshot_download_source.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_update.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/imgur_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/lightshot_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

import '../../../support/test_storage.dart';
import '../../../support/test_image_classifier_service.dart';

class FakeLightshotRemoteDataSource extends LightshotRemoteDataSource {
  FakeLightshotRemoteDataSource({
    required this.onResolveImageUrl,
    required this.onDownloadImage,
  });

  final Future<String> Function(
    Uri pageUrl,
    ProxySettings proxySettings,
    CancelToken? cancelToken,
  ) onResolveImageUrl;
  final Future<File> Function(
    String imageUrl,
    String targetPath,
    CancelToken cancelToken,
    ProxySettings proxySettings,
  ) onDownloadImage;

  @override
  Future<String> resolveImageUrl({
    required Uri pageUrl,
    required ProxySettings proxySettings,
    CancelToken? cancelToken,
  }) {
    return onResolveImageUrl(pageUrl, proxySettings, cancelToken);
  }

  @override
  Future<File> downloadImage({
    required String imageUrl,
    required String targetPath,
    required CancelToken cancelToken,
    required ProxySettings proxySettings,
  }) {
    return onDownloadImage(
      imageUrl,
      targetPath,
      cancelToken,
      proxySettings,
    );
  }
}

class FakeImgurRemoteDataSource extends ImgurRemoteDataSource {
  FakeImgurRemoteDataSource({
    required this.onResolveImageUrl,
    required this.onDownloadImage,
  });

  final Future<String> Function(
    Uri pageUrl,
    ProxySettings proxySettings,
    CancelToken? cancelToken,
  ) onResolveImageUrl;
  final Future<File> Function(
    String imageUrl,
    String targetPath,
    CancelToken cancelToken,
    ProxySettings proxySettings,
  ) onDownloadImage;

  @override
  Future<String> resolveImageUrl({
    required Uri pageUrl,
    required ProxySettings proxySettings,
    CancelToken? cancelToken,
  }) {
    return onResolveImageUrl(pageUrl, proxySettings, cancelToken);
  }

  @override
  Future<File> downloadImage({
    required String imageUrl,
    required String targetPath,
    required CancelToken cancelToken,
    required ProxySettings proxySettings,
  }) {
    return onDownloadImage(
      imageUrl,
      targetPath,
      cancelToken,
      proxySettings,
    );
  }
}

void main() {
  late TestStorageContext storageContext;
  late SettingsRepository settingsRepository;
  late GalleryRepository galleryRepository;

  setUp(() async {
    storageContext = await createTestStorageContext();
    settingsRepository = SettingsRepository(
      TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
    );
    await settingsRepository.ensureInitialized();
    galleryRepository = GalleryRepository(
      settingsRepository: settingsRepository,
      localDataSource: GalleryLocalDataSource(),
    );
    await galleryRepository.ensureInitialized();
  });

  tearDown(() async {
    await galleryRepository.dispose();
    await storageContext.dispose();
  });

  DownloadRequest buildRequest() {
    return const DownloadRequest(
      targetCount: 1,
      source: DownloadSource.lightshot,
      lightshotSettings: LightshotSourceSettings(
        useNewAddresses: false,
        useRandomAddress: false,
        startingId: 'aaaaaa',
      ),
      imgurSettings: ImgurSourceSettings.initial(),
      proxySettings: ProxySettings.initial(),
    );
  }

  test('successful download emits progress and completion', () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _, __) async =>
          'https://image.example/${pageUrl.pathSegments.first}.jpg',
      onDownloadImage: (imageUrl, targetPath, _, __) async {
        final file = File(targetPath);
        await file.create(recursive: true);
        await file.writeAsString('binary-data');
        return file;
      },
    );
    final repository = DownloadRepository(
      sources: [LightshotDownloadSource(remoteDataSource)],
      galleryRepository: galleryRepository,
      imageClassifierService: buildTestImageClassifierService(),
    );

    final updates = await repository.start(buildRequest()).toList();

    expect(
      updates.map((update) => update.type),
      [
        DownloadUpdateType.progress,
        DownloadUpdateType.progress,
        DownloadUpdateType.completed,
      ],
    );
    final items = await galleryRepository.load();
    expect(items, hasLength(1));
    expect(items.single.id, 'aaaaaa');
    expect(items.single.source, DownloadSource.lightshot);
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.lightshot, 'aaaaaa'),
      ),
      isTrue,
    );
  });

  test('no-photo page is marked processed and generator continues', () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _, __) async {
        if (pageUrl.pathSegments.first == 'aaaaaa') {
          throw const NoPhotoException();
        }
        return 'https://image.example/${pageUrl.pathSegments.first}.jpg';
      },
      onDownloadImage: (imageUrl, targetPath, _, __) async {
        final file = File(targetPath);
        await file.create(recursive: true);
        await file.writeAsString('binary-data');
        return file;
      },
    );
    final repository = DownloadRepository(
      sources: [LightshotDownloadSource(remoteDataSource)],
      galleryRepository: galleryRepository,
      imageClassifierService: buildTestImageClassifierService(),
    );

    final updates = await repository.start(buildRequest()).toList();

    expect(updates.last.type, DownloadUpdateType.completed);
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.lightshot, 'aaaaaa'),
      ),
      isTrue,
    );
    final items = await galleryRepository.load();
    expect(items.single.id, 'aaaaab');
  });

  test('download transport failure does not mark page as processed', () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _, __) async =>
          'https://image.example/${pageUrl.pathSegments.first}.jpg',
      onDownloadImage: (_, __, ___, ____) async {
        throw const DownloadTransportException();
      },
    );
    final repository = DownloadRepository(
      sources: [LightshotDownloadSource(remoteDataSource)],
      galleryRepository: galleryRepository,
      imageClassifierService: buildTestImageClassifierService(),
    );

    final updates = await repository.start(buildRequest()).toList();

    expect(
      updates.map((update) => update.type),
      [
        DownloadUpdateType.progress,
        DownloadUpdateType.failed,
      ],
    );
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.lightshot, 'aaaaaa'),
      ),
      isFalse,
    );
    expect(await galleryRepository.load(), isEmpty);
  });

  test('missing downloaded image is marked processed and generator continues',
      () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _, __) async =>
          'https://image.example/${pageUrl.pathSegments.first}.jpg',
      onDownloadImage: (imageUrl, targetPath, _, __) async {
        if (imageUrl.endsWith('/aaaaaa.jpg')) {
          throw const NoPhotoException();
        }

        final file = File(targetPath);
        await file.create(recursive: true);
        await file.writeAsString('binary-data');
        return file;
      },
    );
    final repository = DownloadRepository(
      sources: [LightshotDownloadSource(remoteDataSource)],
      galleryRepository: galleryRepository,
      imageClassifierService: buildTestImageClassifierService(),
    );

    final updates = await repository.start(buildRequest()).toList();

    expect(updates.last.type, DownloadUpdateType.completed);
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.lightshot, 'aaaaaa'),
      ),
      isTrue,
    );
    final items = await galleryRepository.load();
    expect(items.single.id, 'aaaaab');
  });

  test('cancel emits cancelled update', () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _, __) async =>
          'https://image.example/${pageUrl.pathSegments.first}.jpg',
      onDownloadImage: (imageUrl, targetPath, cancelToken, __) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (cancelToken.isCancelled) {
          throw const CancelledDownloadException();
        }
        final file = File(targetPath);
        await file.create(recursive: true);
        await file.writeAsString('binary-data');
        return file;
      },
    );
    final repository = DownloadRepository(
      sources: [LightshotDownloadSource(remoteDataSource)],
      galleryRepository: galleryRepository,
      imageClassifierService: buildTestImageClassifierService(),
    );

    final updatesFuture = repository.start(buildRequest()).toList();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.cancel();
    final updates = await updatesFuture;

    expect(updates.last.type, DownloadUpdateType.cancelled);
  });

  test('cancel during resolve emits cancelled update without downloading',
      () async {
    var downloadCalled = false;
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _, cancelToken) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (cancelToken?.isCancelled ?? false) {
          throw const CancelledDownloadException();
        }
        return 'https://image.example/${pageUrl.pathSegments.first}.jpg';
      },
      onDownloadImage: (imageUrl, targetPath, _, __) async {
        downloadCalled = true;
        final file = File(targetPath);
        await file.create(recursive: true);
        await file.writeAsString('binary-data');
        return file;
      },
    );
    final repository = DownloadRepository(
      sources: [LightshotDownloadSource(remoteDataSource)],
      galleryRepository: galleryRepository,
      imageClassifierService: buildTestImageClassifierService(),
    );

    final updatesFuture = repository.start(buildRequest()).toList();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.cancel();
    final updates = await updatesFuture;

    expect(updates.last.type, DownloadUpdateType.cancelled);
    expect(downloadCalled, isFalse);
  });

  test('imgur successful download uses source-scoped tracking key', () async {
    final remoteDataSource = FakeImgurRemoteDataSource(
      onResolveImageUrl: (pageUrl, _, __) async =>
          'https://i.imgur.com/${pageUrl.pathSegments.first}.png',
      onDownloadImage: (imageUrl, targetPath, _, __) async {
        final file = File(targetPath);
        await file.create(recursive: true);
        await file.writeAsString('binary-data');
        return file;
      },
    );
    final repository = DownloadRepository(
      sources: [ImgurDownloadSource(remoteDataSource)],
      galleryRepository: galleryRepository,
      imageClassifierService: buildTestImageClassifierService(),
    );
    const request = DownloadRequest(
      targetCount: 1,
      source: DownloadSource.imgur,
      lightshotSettings: LightshotSourceSettings.initial(),
      imgurSettings: ImgurSourceSettings(
        candidateLengths: [5],
        useRandomAddress: false,
        startingId: 'aaaaa',
      ),
      proxySettings: ProxySettings.initial(),
    );

    final updates = await repository.start(request).toList();

    expect(updates.last.type, DownloadUpdateType.completed);
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.imgur, 'aaaaa'),
      ),
      isTrue,
    );
    final items = await galleryRepository.load();
    expect(items.single.source, DownloadSource.imgur);
    expect(items.single.id, 'aaaaa');
  });

  test('lightshot and imgur tracking do not conflict', () async {
    await galleryRepository.markProcessed(
      buildTrackingKey(DownloadSource.lightshot, 'aaaaa'),
    );
    expect(
      await galleryRepository.isProcessed(
        buildTrackingKey(DownloadSource.imgur, 'aaaaa'),
      ),
      isFalse,
    );
  });

  test('downloaded image is visible with pending category before completion',
      () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _, __) async =>
          'https://image.example/${pageUrl.pathSegments.first}.png',
      onDownloadImage: (imageUrl, targetPath, _, __) async {
        final file = File(targetPath);
        await file.create(recursive: true);
        await _writePngBytes(file);
        return file;
      },
    );
    final repository = DownloadRepository(
      sources: [LightshotDownloadSource(remoteDataSource)],
      galleryRepository: galleryRepository,
      imageClassifierService: DelayedTestImageClassifierService(
        delay: const Duration(milliseconds: 500),
        onClassify: (GalleryItem item) {
          return item.copyWith(
            classificationResult: ClassificationResult.completed(
              category: ClassificationCategory.games,
              confidence: 0.92,
              rawScores: const ClassificationScores(
                nsfw: 0.1,
                documents: 0.3,
                games: 0.92,
              ),
              backend: 'mock',
              classifiedAt: DateTime(2026, 3, 15),
            ),
          );
        },
      ),
    );
    final updates = <DownloadUpdate>[];
    final completer = Completer<void>();

    repository.start(buildRequest()).listen(
          updates.add,
          onDone: () => completer.complete(),
        );

    await _waitForCondition(() async {
      final items = await galleryRepository.load();
      return items.isNotEmpty;
    });
    final pendingItems = await galleryRepository.load();

    expect(pendingItems.single.classificationResult.status,
        ClassificationStatus.pending);

    await completer.future;
    final completedItems = await galleryRepository.load();

    expect(updates.last.type, DownloadUpdateType.completed);
    expect(
      completedItems.single.classificationResult.category,
      ClassificationCategory.games,
    );
  });
}

Future<void> _writePngBytes(File file) async {
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

Future<void> _waitForCondition(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 2),
  Duration step = const Duration(milliseconds: 10),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (await condition()) {
      return;
    }
    await Future<void>.delayed(step);
  }
  fail('Timed out while waiting for condition');
}
