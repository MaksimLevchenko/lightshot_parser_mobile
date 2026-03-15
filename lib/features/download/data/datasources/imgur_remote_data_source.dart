import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/base_image_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class ImgurRemoteDataSource extends BaseImageRemoteDataSource {
  ImgurRemoteDataSource();

  final RegExp _ogImagePattern = RegExp(
    r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']''',
    caseSensitive: false,
  );
  final RegExp _twitterImagePattern = RegExp(
    r'''<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']''',
    caseSensitive: false,
  );
  final RegExp _directImagePattern = RegExp(
    r'''https://i\.imgur\.com/[^"'\s>]+''',
    caseSensitive: false,
  );
  final RegExp _supportedExtensionPattern = RegExp(
    r'\.(jpg|jpeg|png|webp)$',
    caseSensitive: false,
  );

  Future<String> resolveImageUrl({
    required Uri pageUrl,
    required ProxySettings proxySettings,
  }) async {
    final sourceCode = await fetchPageSource(
      pageUrl: pageUrl,
      proxySettings: proxySettings,
      treatNotFoundAsNoPhoto: true,
    );

    final imageUrl = _extractSupportedImageUrl(sourceCode);
    if (imageUrl == null) {
      throw const NoPhotoException();
    }

    return imageUrl;
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
    if (!await file.exists() || await file.length() == 0) {
      if (await file.exists()) {
        await file.delete();
      }
      throw const NoPhotoException();
    }
    return file;
  }

  String? _extractSupportedImageUrl(String sourceCode) {
    final candidates = <String?>[
      _ogImagePattern.firstMatch(sourceCode)?.group(1),
      _twitterImagePattern.firstMatch(sourceCode)?.group(1),
      _directImagePattern.firstMatch(sourceCode)?.group(0),
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeSupportedImageUrl(candidate);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  String? _normalizeSupportedImageUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return null;
    }
    final extension = _extractFileExtension(uri);
    if (extension == null) {
      return null;
    }
    if (extension == '.gif' || extension == '.gifv' || extension == '.mp4') {
      return null;
    }
    if (!_supportedExtensionPattern.hasMatch(extension)) {
      return null;
    }

    return uri.toString();
  }

  String? _extractFileExtension(Uri uri) {
    final path = uri.path.toLowerCase();
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      return null;
    }
    return path.substring(dotIndex);
  }
}
