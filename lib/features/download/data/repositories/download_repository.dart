import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/core/logging/app_logger.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/download_source_engine.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_progress.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_update.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

class DownloadRepository {
  DownloadRepository({
    required List<DownloadSourceEngine> sources,
    required GalleryRepository galleryRepository,
  })  : _sources = {
          for (final source in sources) source.source: source,
        },
        _galleryRepository = galleryRepository;

  final Map<DownloadSource, DownloadSourceEngine> _sources;
  final GalleryRepository _galleryRepository;

  CancelToken? _cancelToken;
  bool _cancelRequested = false;

  Stream<DownloadUpdate> start(DownloadRequest request) async* {
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    _cancelRequested = false;
    AppLogger.info(
      'Starting download: source=${request.source.name}, targetCount=${request.targetCount}',
      scope: 'download',
    );
    final source = _sources[request.source];
    if (source == null) {
      AppLogger.error(
        'Unsupported source: ${request.source.name}',
        scope: 'download',
      );
      yield DownloadUpdate(
        type: DownloadUpdateType.failed,
        progress: DownloadProgress(
          downloadedCount: 0,
          totalCount: request.targetCount,
        ),
        message: 'Unsupported source: ${request.source.name}',
      );
      return;
    }
    final generator = source.createGenerator(request);

    try {
      var downloadedCount = 0;
      yield DownloadUpdate(
        type: DownloadUpdateType.progress,
        progress: DownloadProgress(
          downloadedCount: downloadedCount,
          totalCount: request.targetCount,
        ),
      );

      while (downloadedCount < request.targetCount) {
        if (_shouldCancel(cancelToken)) {
          yield _buildCancelledUpdate(downloadedCount, request.targetCount);
          return;
        }

        final sourceId = generator.current;
        final trackingKey = source.createTrackingKey(sourceId);

        if (await _galleryRepository.isProcessed(trackingKey)) {
          if (_shouldCancel(cancelToken)) {
            yield _buildCancelledUpdate(downloadedCount, request.targetCount);
            return;
          }
          generator.moveNext();
          continue;
        }

        try {
          final resolvedImage = await source.resolveImage(
            sourceId: sourceId,
            proxySettings: request.proxySettings,
            cancelToken: cancelToken,
          );

          if (_shouldCancel(cancelToken)) {
            yield _buildCancelledUpdate(downloadedCount, request.targetCount);
            return;
          }

          final downloadedFile = await source.downloadImage(
            imageUrl: resolvedImage.imageUrl,
            targetPath:
                '${_galleryRepository.photosDirectory.path}${Platform.pathSeparator}$trackingKey${resolvedImage.fileExtension}',
            cancelToken: cancelToken,
            proxySettings: request.proxySettings,
          );
          final item = GalleryItem.fromFile(downloadedFile);
          await _galleryRepository.addDownloadedFile(item: item);
          downloadedCount += 1;
          yield DownloadUpdate(
            type: DownloadUpdateType.progress,
            progress: DownloadProgress(
              downloadedCount: downloadedCount,
              totalCount: request.targetCount,
            ),
            item: item,
          );
        } on NoPhotoException {
          await _galleryRepository.markProcessed(trackingKey);
        } on CancelledDownloadException {
          AppLogger.info('Download cancelled by user', scope: 'download');
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
        } on DownloadTransportException {
          yield DownloadUpdate(
            type: DownloadUpdateType.failed,
            progress: DownloadProgress(
              downloadedCount: downloadedCount,
              totalCount: request.targetCount,
            ),
            message: request.proxySettings.enabled ? 'proxy' : 'vpn',
          );
          return;
        } on AppException catch (error, stackTrace) {
          AppLogger.error(
            'Download failed with application error',
            scope: 'download',
            error: error,
            stackTrace: stackTrace,
          );
          yield DownloadUpdate(
            type: DownloadUpdateType.failed,
            progress: DownloadProgress(
              downloadedCount: downloadedCount,
              totalCount: request.targetCount,
            ),
            message: error.message,
          );
          return;
        } on Object catch (error, stackTrace) {
          AppLogger.error(
            'Download failed with unexpected error',
            scope: 'download',
            error: error,
            stackTrace: stackTrace,
          );
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
      AppLogger.info('Download completed successfully', scope: 'download');
    } finally {
      if (identical(_cancelToken, cancelToken)) {
        _cancelToken = null;
      }
      _cancelRequested = false;
    }
  }

  Future<void> cancel() async {
    AppLogger.info('Cancelling active download', scope: 'download');
    _cancelRequested = true;
    _cancelToken?.cancel();
  }

  bool _shouldCancel(CancelToken cancelToken) {
    return _cancelRequested || cancelToken.isCancelled;
  }

  DownloadUpdate _buildCancelledUpdate(int downloadedCount, int totalCount) {
    AppLogger.info('Download cancelled by user', scope: 'download');
    return DownloadUpdate(
      type: DownloadUpdateType.cancelled,
      progress: DownloadProgress(
        downloadedCount: downloadedCount,
        totalCount: totalCount,
      ),
    );
  }
}
