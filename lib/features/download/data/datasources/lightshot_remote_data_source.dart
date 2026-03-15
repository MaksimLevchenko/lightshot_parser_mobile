import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class LightshotRemoteDataSource {
  LightshotRemoteDataSource()
      : _client = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 7),
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0',
            },
          ),
        );

  final Dio _client;
  final RegExp _imageUrlPattern = RegExp(r'https.*((png)|(jpg)|(jpeg))');

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

  Future<String> resolveImageUrl({
    required Uri pageUrl,
    required ProxySettings proxySettings,
  }) async {
    _configureProxy(proxySettings);

    late final Response<dynamic> response;
    try {
      response = await _client.getUri(pageUrl);
    } on DioException {
      throw const CouldNotConnectException();
    }

    final sourceCode = response.data.toString();
    var imageStringUrl = _imageUrlPattern.stringMatch(sourceCode);
    if (imageStringUrl == null) {
      throw const NoPhotoException();
    }

    imageStringUrl = imageStringUrl.substring(0, imageStringUrl.indexOf('"'));
    if (!imageStringUrl.contains(_imageUrlPattern)) {
      throw const NoPhotoException();
    }

    return imageStringUrl;
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
    } on DioException {
      if (cancelToken.isCancelled) {
        throw const CancelledDownloadException();
      }
      throw const DownloadTransportException();
    }

    final file = File(targetPath);
    if (await file.length() == 503) {
      await file.delete();
      throw const NoPhotoException();
    }
    return file;
  }
}
