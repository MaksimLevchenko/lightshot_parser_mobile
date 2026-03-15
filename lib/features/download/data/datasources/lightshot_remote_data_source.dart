import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/base_image_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class LightshotRemoteDataSource extends BaseImageRemoteDataSource {
  LightshotRemoteDataSource();
  final RegExp _imageUrlPattern = RegExp(r'https.*((png)|(jpg)|(jpeg))');

  Future<String> resolveImageUrl({
    required Uri pageUrl,
    required ProxySettings proxySettings,
    CancelToken? cancelToken,
  }) async {
    final sourceCode = await fetchPageSource(
      pageUrl: pageUrl,
      proxySettings: proxySettings,
      cancelToken: cancelToken,
      treatNotFoundAsNoPhoto: true,
    );
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

  @override
  Future<File> downloadImage({
    required String imageUrl,
    required String targetPath,
    required CancelToken cancelToken,
    required ProxySettings proxySettings,
  }) async {
    final file = await super.downloadImage(
      imageUrl: imageUrl,
      targetPath: targetPath,
      cancelToken: cancelToken,
      proxySettings: proxySettings,
    );
    if (await file.length() == 503) {
      await file.delete();
      throw const NoPhotoException();
    }
    return file;
  }
}
