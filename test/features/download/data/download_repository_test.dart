import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/lightshot_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/repositories/download_repository.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_update.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

import '../../../support/test_storage.dart';

class FakeLightshotRemoteDataSource extends LightshotRemoteDataSource {
  FakeLightshotRemoteDataSource({
    required this.onResolveImageUrl,
    required this.onDownloadImage,
  });

  final Future<String> Function(Uri pageUrl, ProxySettings proxySettings)
      onResolveImageUrl;
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
  }) {
    return onResolveImageUrl(pageUrl, proxySettings);
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
      useNewAddresses: false,
      useRandomAddress: false,
      startingUrl: 'aaaaaa',
      proxySettings: ProxySettings.initial(),
    );
  }

  test('successful download emits progress and completion', () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _) async =>
          'https://image.example/${pageUrl.pathSegments.first}.jpg',
      onDownloadImage: (imageUrl, targetPath, _, __) async {
        final file = File(targetPath);
        await file.create(recursive: true);
        await file.writeAsString('binary-data');
        return file;
      },
    );
    final repository = DownloadRepository(
      remoteDataSource: remoteDataSource,
      galleryRepository: galleryRepository,
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
    expect(await galleryRepository.isUrlProcessed('aaaaaa'), isTrue);
  });

  test('no-photo page is marked processed and generator continues', () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _) async {
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
      remoteDataSource: remoteDataSource,
      galleryRepository: galleryRepository,
    );

    final updates = await repository.start(buildRequest()).toList();

    expect(updates.last.type, DownloadUpdateType.completed);
    expect(await galleryRepository.isUrlProcessed('aaaaaa'), isTrue);
    final items = await galleryRepository.load();
    expect(items.single.id, 'aaaaab');
  });

  test('download transport failure does not mark page as processed', () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _) async =>
          'https://image.example/${pageUrl.pathSegments.first}.jpg',
      onDownloadImage: (_, __, ___, ____) async {
        throw const DownloadTransportException();
      },
    );
    final repository = DownloadRepository(
      remoteDataSource: remoteDataSource,
      galleryRepository: galleryRepository,
    );

    final updates = await repository.start(buildRequest()).toList();

    expect(
      updates.map((update) => update.type),
      [
        DownloadUpdateType.progress,
        DownloadUpdateType.failed,
      ],
    );
    expect(await galleryRepository.isUrlProcessed('aaaaaa'), isFalse);
    expect(await galleryRepository.load(), isEmpty);
  });

  test('cancel emits cancelled update', () async {
    final remoteDataSource = FakeLightshotRemoteDataSource(
      onResolveImageUrl: (pageUrl, _) async =>
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
      remoteDataSource: remoteDataSource,
      galleryRepository: galleryRepository,
    );

    final updatesFuture = repository.start(buildRequest()).toList();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.cancel();
    final updates = await updatesFuture;

    expect(updates.last.type, DownloadUpdateType.cancelled);
  });
}
