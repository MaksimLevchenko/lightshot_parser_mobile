import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/core/logging/app_logger.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

abstract class BaseImageRemoteDataSource {
  BaseImageRemoteDataSource()
      : _client = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0',
            },
          ),
        );

  final Dio _client;

  @protected
  Future<Response<dynamic>> sendRequestUri({
    required Uri uri,
    required ProxySettings proxySettings,
    CancelToken? cancelToken,
    String method = 'GET',
    Map<String, Object?>? headers,
    bool followRedirects = true,
    ResponseType? responseType,
  }) async {
    _configureProxy(proxySettings);

    try {
      return await _client.requestUri(
        uri,
        options: Options(
          method: method,
          headers: headers,
          validateStatus: (_) => true,
          followRedirects: followRedirects,
          responseType: responseType,
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (error, stackTrace) {
      if (CancelToken.isCancel(error)) {
        throw const CancelledDownloadException();
      }
      if (_isTimeout(error)) {
        AppLogger.warning(
          'Request timed out and will be skipped: $method $uri',
          scope: 'network',
          error: error,
          stackTrace: stackTrace,
        );
        throw const NoPhotoException('Request timed out');
      }
      AppLogger.warning(
        'Failed to perform $method request: $uri',
        scope: 'network',
        error: error,
        stackTrace: stackTrace,
      );
      throw const CouldNotConnectException();
    }
  }

  @protected
  Future<String> fetchPageSource({
    required Uri pageUrl,
    required ProxySettings proxySettings,
    CancelToken? cancelToken,
    bool treatNotFoundAsNoPhoto = false,
  }) async {
    final response = await sendRequestUri(
      uri: pageUrl,
      proxySettings: proxySettings,
      cancelToken: cancelToken,
    );

    final statusCode = response.statusCode;
    if (treatNotFoundAsNoPhoto && _isMissingResourceStatus(statusCode)) {
      throw const NoPhotoException();
    }
    if ((statusCode ?? 200) >= 400) {
      throw const CouldNotConnectException();
    }

    return response.data.toString();
  }

  Future<File> downloadImage({
    required String imageUrl,
    required String targetPath,
    required CancelToken cancelToken,
    required ProxySettings proxySettings,
  }) async {
    _configureProxy(proxySettings);

    try {
      await _client.download(
        imageUrl,
        targetPath,
        cancelToken: cancelToken,
      );
    } on DioException catch (error, stackTrace) {
      if (cancelToken.isCancelled) {
        throw const CancelledDownloadException();
      }
      if (_isTimeout(error)) {
        await _deleteIfExists(targetPath);
        AppLogger.warning(
          'Image download timed out and will be skipped: $imageUrl',
          scope: 'network',
          error: error,
          stackTrace: stackTrace,
        );
        throw const NoPhotoException('Download timed out');
      }
      if (_isMissingResourceStatus(error.response?.statusCode)) {
        await _deleteIfExists(targetPath);
        throw const NoPhotoException();
      }
      AppLogger.warning(
        'Failed to download image: $imageUrl',
        scope: 'network',
        error: error,
        stackTrace: stackTrace,
      );
      throw const DownloadTransportException();
    }

    return File(targetPath);
  }

  void _configureProxy(ProxySettings proxySettings) {
    final proxy = proxySettings.toProxyString();
    _client.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        if (proxy != null) {
          client.findProxy = (_) => proxy;
        }
        return client;
      },
    );
  }

  bool _isMissingResourceStatus(int? statusCode) {
    return statusCode == 404 || statusCode == 410;
  }

  bool _isTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  Future<void> _deleteIfExists(String targetPath) async {
    final file = File(targetPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
