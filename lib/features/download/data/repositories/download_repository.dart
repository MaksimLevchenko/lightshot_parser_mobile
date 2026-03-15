import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/lightshot_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_progress.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_update.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

abstract class UrlGenerator {
  Uri get current;
  bool moveNext();
}

class SequentialUrlGenerator implements UrlGenerator {
  SequentialUrlGenerator({
    required bool useNewAddresses,
    required String startingUrl,
  })  : _symbols = useNewAddresses
            ? 'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ_-'
            : 'abcdefghijklmnopqrstuvwxyz1234567890',
        _length = useNewAddresses ? 12 : 6 {
    final seed = startingUrl;
    if (seed.length != _length ||
        seed.split('').any((char) => !_symbols.contains(char))) {
      _currentValue = List<String>.filled(_length, 'a').join();
    } else {
      _currentValue = seed;
    }
    _indexes =
        _currentValue.split('').map(_symbols.indexOf).toList(growable: false);
  }

  final String _symbols;
  final int _length;
  late List<int> _indexes;
  late String _currentValue;

  @override
  Uri get current => Uri.parse('https://prnt.sc/$_currentValue');

  @override
  bool moveNext() {
    final nextIndexes = List<int>.from(_indexes);
    nextIndexes[_length - 1] += 1;
    for (int index = _length - 1; index >= 0; index--) {
      if (nextIndexes[index] == _symbols.length) {
        nextIndexes[index] = 0;
        if (index > 0) {
          nextIndexes[index - 1] += 1;
        }
      }
    }
    _indexes = nextIndexes;
    _currentValue = _indexes.map((index) => _symbols[index]).join();
    return true;
  }
}

class RandomUrlGenerator implements UrlGenerator {
  RandomUrlGenerator({required bool useNewAddresses})
      : _symbols = useNewAddresses
            ? 'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ_-'
            : 'abcdefghijklmnopqrstuvwxyz1234567890',
        _length = useNewAddresses ? 12 : 6 {
    moveNext();
  }

  final String _symbols;
  final int _length;
  final Random _random = Random();
  late String _currentValue;

  @override
  Uri get current => Uri.parse('https://prnt.sc/$_currentValue');

  @override
  bool moveNext() {
    _currentValue = String.fromCharCodes(
      Iterable<int>.generate(
        _length,
        (_) => _symbols.codeUnitAt(_random.nextInt(_symbols.length)),
      ),
    );
    return true;
  }
}

class DownloadRepository {
  DownloadRepository({
    required LightshotRemoteDataSource remoteDataSource,
    required GalleryRepository galleryRepository,
  })  : _remoteDataSource = remoteDataSource,
        _galleryRepository = galleryRepository;

  final LightshotRemoteDataSource _remoteDataSource;
  final GalleryRepository _galleryRepository;

  CancelToken? _cancelToken;

  Stream<DownloadUpdate> start(DownloadRequest request) async* {
    _cancelToken = CancelToken();
    final generator = request.useRandomAddress
        ? RandomUrlGenerator(useNewAddresses: request.useNewAddresses)
        : SequentialUrlGenerator(
            useNewAddresses: request.useNewAddresses,
            startingUrl: request.startingUrl,
          );

    var downloadedCount = 0;
    yield DownloadUpdate(
      type: DownloadUpdateType.progress,
      progress: DownloadProgress(
        downloadedCount: downloadedCount,
        totalCount: request.targetCount,
      ),
    );

    while (downloadedCount < request.targetCount) {
      final pageUrl = generator.current;
      final pageId = pageUrl.pathSegments.first;

      if (await _galleryRepository.isUrlProcessed(pageId)) {
        generator.moveNext();
        continue;
      }

      try {
        final imageUrl = await _remoteDataSource.resolveImageUrl(
          pageUrl: pageUrl,
          proxySettings: request.proxySettings,
        );

        final extension = imageUrl.substring(imageUrl.lastIndexOf('.'));
        final downloadedFile = await _remoteDataSource.downloadImage(
          imageUrl: imageUrl,
          targetPath:
              '${_galleryRepository.photosDirectory.path}${Platform.pathSeparator}$pageId$extension',
          cancelToken: _cancelToken!,
          proxySettings: request.proxySettings,
        );
        await _galleryRepository.addDownloadedFile(
          file: downloadedFile,
          id: pageId,
        );
        downloadedCount += 1;
        yield DownloadUpdate(
          type: DownloadUpdateType.progress,
          progress: DownloadProgress(
            downloadedCount: downloadedCount,
            totalCount: request.targetCount,
          ),
          item: GalleryItem.fromFile(downloadedFile),
        );
      } on NoPhotoException {
        await _galleryRepository.markUrlProcessed(pageId);
      } on CancelledDownloadException {
        yield DownloadUpdate(
          type: DownloadUpdateType.cancelled,
          progress: DownloadProgress(
            downloadedCount: downloadedCount,
            totalCount: request.targetCount,
          ),
        );
        return;
      } on CouldNotConnectException {
        yield DownloadUpdate(
          type: DownloadUpdateType.failed,
          progress: DownloadProgress(
            downloadedCount: downloadedCount,
            totalCount: request.targetCount,
          ),
          message: request.proxySettings.enabled ? 'proxy' : 'vpn',
        );
        return;
      } on AppException catch (error) {
        yield DownloadUpdate(
          type: DownloadUpdateType.failed,
          progress: DownloadProgress(
            downloadedCount: downloadedCount,
            totalCount: request.targetCount,
          ),
          message: error.message,
        );
        return;
      } on Object catch (error) {
        yield DownloadUpdate(
          type: DownloadUpdateType.failed,
          progress: DownloadProgress(
            downloadedCount: downloadedCount,
            totalCount: request.targetCount,
          ),
          message: error.toString(),
        );
        return;
      }

      generator.moveNext();
    }

    yield DownloadUpdate(
      type: DownloadUpdateType.completed,
      progress: DownloadProgress(
        downloadedCount: downloadedCount,
        totalCount: request.targetCount,
      ),
    );
  }

  Future<void> cancel() async {
    _cancelToken?.cancel();
  }
}
