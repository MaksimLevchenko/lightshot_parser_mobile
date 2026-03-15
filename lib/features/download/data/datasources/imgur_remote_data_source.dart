import 'dart:convert';
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
    r'''<meta[^>]+name=["']twitter:image(?:\:src)?["'][^>]+content=["']([^"']+)["']''',
    caseSensitive: false,
  );
  final RegExp _ogUrlPattern = RegExp(
    r'''<meta[^>]+property=["']og:url["'][^>]+content=["']([^"']+)["']''',
    caseSensitive: false,
  );
  final RegExp _canonicalPattern = RegExp(
    r'''<link[^>]+rel=["']canonical["'][^>]+href=["']([^"']+)["']''',
    caseSensitive: false,
  );
  final RegExp _directImagePattern = RegExp(
    r'''https://i\.imgur\.com/[^"'\s>]+''',
    caseSensitive: false,
  );
  final RegExp _postDataJsonPattern = RegExp(
    r'''window\.postDataJSON\s*=\s*"((?:\\.|[^"\\])*)"''',
    caseSensitive: false,
  );

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

    final pagePayload = _parsePagePayload(
      pageUrl: pageUrl,
      sourceCode: sourceCode,
    );
    final candidate = _extractImageCandidate(pagePayload);
    if (candidate == null) {
      throw const NoPhotoException();
    }

    return _validateDirectImageUrl(
      imageCandidate: candidate,
      proxySettings: proxySettings,
      cancelToken: cancelToken,
    );
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

  _ImgurPagePayload _parsePagePayload({
    required Uri pageUrl,
    required String sourceCode,
  }) {
    final expectedId =
        pageUrl.pathSegments.isEmpty ? '' : pageUrl.pathSegments.last;
    final canonicalUrl = _canonicalPattern.firstMatch(sourceCode)?.group(1);
    final ogUrl = _ogUrlPattern.firstMatch(sourceCode)?.group(1);
    final pageData = _parsePostDataJson(sourceCode);
    final hasMatchingPageUrl = _matchesExpectedPath(canonicalUrl, expectedId) ||
        _matchesExpectedPath(ogUrl, expectedId) ||
        pageData?.id == expectedId;

    if (!hasMatchingPageUrl) {
      throw const NoPhotoException();
    }

    return _ImgurPagePayload(
      pageUrl: pageUrl,
      sourceCode: sourceCode,
      pageData: pageData,
    );
  }

  _ImgurImageCandidate? _extractImageCandidate(_ImgurPagePayload payload) {
    final pageData = payload.pageData;
    if (pageData != null) {
      if (pageData.isAlbum) {
        for (final media in pageData.media) {
          if (_supportsStillImage(
            url: media.url,
            mimeType: media.mimeType,
            isAnimated: media.isAnimated,
          )) {
            return _ImgurImageCandidate(
              imageUrl: media.url!,
              mimeType: media.mimeType,
              isAnimated: media.isAnimated,
            );
          }
        }
      }

      if (_supportsStillImage(
        url: pageData.imageUrl,
        mimeType: pageData.mimeType,
        isAnimated: pageData.isAnimated,
      )) {
        return _ImgurImageCandidate(
          imageUrl: pageData.imageUrl!,
          mimeType: pageData.mimeType,
          isAnimated: pageData.isAnimated,
        );
      }
    }

    final candidates = <String?>[
      _ogImagePattern.firstMatch(payload.sourceCode)?.group(1),
      _twitterImagePattern.firstMatch(payload.sourceCode)?.group(1),
      _directImagePattern.firstMatch(payload.sourceCode)?.group(0),
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeSupportedImageUrl(candidate);
      if (normalized != null) {
        return _ImgurImageCandidate(imageUrl: normalized);
      }
    }
    return null;
  }

  Future<String> _validateDirectImageUrl({
    required _ImgurImageCandidate imageCandidate,
    required ProxySettings proxySettings,
    CancelToken? cancelToken,
  }) async {
    final imageUri = Uri.parse(imageCandidate.imageUrl);
    final headResponse = await sendRequestUri(
      uri: imageUri,
      proxySettings: proxySettings,
      cancelToken: cancelToken,
      method: 'HEAD',
      headers: const {
        'Accept': 'image/*,*/*;q=0.8',
      },
      followRedirects: false,
    );

    final headValidation = _validateImageResponse(
      response: headResponse,
      fallbackUri: imageUri,
      imageCandidate: imageCandidate,
    );
    if (headValidation != null) {
      return headValidation;
    }

    final getResponse = await sendRequestUri(
      uri: imageUri,
      proxySettings: proxySettings,
      cancelToken: cancelToken,
      headers: const {
        'Accept': 'image/*,*/*;q=0.8',
      },
      followRedirects: false,
      responseType: ResponseType.stream,
    );

    final getValidation = _validateImageResponse(
      response: getResponse,
      fallbackUri: imageUri,
      imageCandidate: imageCandidate,
    );
    if (getValidation == null) {
      throw const NoPhotoException();
    }
    return getValidation;
  }

  _ImgurPageData? _parsePostDataJson(String sourceCode) {
    final match = _postDataJsonPattern.firstMatch(sourceCode);
    final encodedJson = match?.group(1);
    if (encodedJson == null || encodedJson.isEmpty) {
      return null;
    }

    try {
      final decodedJson = jsonDecode('"$encodedJson"') as String;
      final data = jsonDecode(decodedJson);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      return _ImgurPageData.fromJson(data);
    } on FormatException {
      return null;
    }
  }

  bool _matchesExpectedPath(String? url, String expectedId) {
    if (url == null || url.isEmpty || expectedId.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) {
      return false;
    }

    return uri.pathSegments.last == expectedId;
  }

  bool _supportsStillImage({
    required String? url,
    required String? mimeType,
    required bool isAnimated,
  }) {
    if (url == null || !_isDirectImgurImageUrl(url) || isAnimated) {
      return false;
    }
    if (mimeType != null) {
      final normalizedMimeType = mimeType.toLowerCase();
      if (!normalizedMimeType.startsWith('image/') ||
          normalizedMimeType == 'image/gif') {
        return false;
      }
    }

    return _normalizeSupportedImageUrl(url) != null;
  }

  String? _validateImageResponse({
    required Response<dynamic> response,
    required Uri fallbackUri,
    required _ImgurImageCandidate imageCandidate,
  }) {
    final redirectTarget = response.headers.value('location');
    if (redirectTarget != null && redirectTarget.isNotEmpty) {
      final redirectUri = Uri.tryParse(redirectTarget);
      if (_isRemovedPlaceholder(redirectUri)) {
        throw const NoPhotoException();
      }
      return null;
    }

    final statusCode = response.statusCode ?? 0;
    if (statusCode == 404 || statusCode == 410) {
      throw const NoPhotoException();
    }
    if (statusCode >= 400) {
      throw const CouldNotConnectException();
    }
    if (statusCode < 200 || statusCode >= 300) {
      return null;
    }

    final responseUri =
        response.realUri == Uri() ? fallbackUri : response.realUri;
    if (_isRemovedPlaceholder(responseUri)) {
      throw const NoPhotoException();
    }
    if (!_isDirectImgurImageUrl(responseUri.toString())) {
      throw const NoPhotoException();
    }

    final contentType = response.headers.value(Headers.contentTypeHeader);
    if (contentType == null) {
      return null;
    }

    final mimeType = contentType.split(';').first.trim().toLowerCase();
    if (!mimeType.startsWith('image/') || mimeType == 'image/gif') {
      throw const NoPhotoException();
    }
    if (imageCandidate.isAnimated) {
      throw const NoPhotoException();
    }

    final normalizedUrl = _normalizeValidatedImageUrl(
      uri: responseUri,
      mimeType: mimeType,
    );
    if (normalizedUrl == null) {
      throw const NoPhotoException();
    }
    return normalizedUrl;
  }

  String? _normalizeSupportedImageUrl(String? value) {
    if (value == null || value.isEmpty || !_isDirectImgurImageUrl(value)) {
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
    if (!_isSupportedStillImageExtension(extension)) {
      return null;
    }

    return _withoutQuery(uri).toString();
  }

  String? _normalizeValidatedImageUrl({
    required Uri uri,
    required String mimeType,
  }) {
    final replacementExtension = switch (mimeType) {
      'image/jpeg' => '.jpeg',
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ => null,
    };

    final currentExtension = _extractFileExtension(uri);
    final normalizedUri =
        replacementExtension != null && currentExtension != null
            ? _withoutQuery(
                uri.replace(
                  path:
                      '${uri.path.substring(0, uri.path.length - currentExtension.length)}$replacementExtension',
                ),
              )
            : _withoutQuery(uri);

    final normalized = normalizedUri.toString();
    return _normalizeSupportedImageUrl(normalized);
  }

  bool _isDirectImgurImageUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return false;
    }
    return uri.scheme.startsWith('http') &&
        uri.host.toLowerCase() == 'i.imgur.com';
  }

  bool _isSupportedStillImageExtension(String extension) {
    final normalizedExtension = extension.toLowerCase();
    return normalizedExtension == '.jpg' ||
        normalizedExtension == '.jpeg' ||
        normalizedExtension == '.png' ||
        normalizedExtension == '.webp';
  }

  bool _isRemovedPlaceholder(Uri? uri) {
    if (uri == null) {
      return false;
    }
    return uri.host.toLowerCase() == 'i.imgur.com' &&
        uri.path.toLowerCase().endsWith('/removed.png');
  }

  String? _extractFileExtension(Uri uri) {
    final path = uri.path.toLowerCase();
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      return null;
    }
    return path.substring(dotIndex);
  }

  Uri _withoutQuery(Uri uri) {
    if (!uri.hasQuery) {
      return uri;
    }
    return uri.replace(queryParameters: const <String, String>{}, fragment: '');
  }
}

class _ImgurPagePayload {
  const _ImgurPagePayload({
    required this.pageUrl,
    required this.sourceCode,
    required this.pageData,
  });

  final Uri pageUrl;
  final String sourceCode;
  final _ImgurPageData? pageData;
}

class _ImgurImageCandidate {
  const _ImgurImageCandidate({
    required this.imageUrl,
    this.mimeType,
    this.isAnimated = false,
  });

  final String imageUrl;
  final String? mimeType;
  final bool isAnimated;
}

class _ImgurPageData {
  const _ImgurPageData({
    required this.id,
    required this.imageUrl,
    required this.mimeType,
    required this.isAnimated,
    required this.isAlbum,
    required this.media,
  });

  factory _ImgurPageData.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_ImgurMediaItem.fromJson)
        .toList(growable: false);
    final cover = json['cover'];

    return _ImgurPageData(
      id: json['id'] as String? ?? '',
      imageUrl: json['url'] as String? ??
          (cover is Map<String, dynamic> ? cover['url'] as String? : null),
      mimeType: json['mime_type'] as String? ??
          (cover is Map<String, dynamic>
              ? cover['mime_type'] as String?
              : null),
      isAnimated: _readAnimatedFlag(json) ||
          (cover is Map<String, dynamic> && _readAnimatedFlag(cover)),
      isAlbum: json['is_album'] as bool? ?? false,
      media: media,
    );
  }

  final String id;
  final String? imageUrl;
  final String? mimeType;
  final bool isAnimated;
  final bool isAlbum;
  final List<_ImgurMediaItem> media;

  static bool _readAnimatedFlag(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    return json['animated'] as bool? ??
        (metadata is Map<String, dynamic>
            ? metadata['is_animated'] as bool? ?? false
            : false);
  }
}

class _ImgurMediaItem {
  const _ImgurMediaItem({
    required this.url,
    required this.mimeType,
    required this.isAnimated,
  });

  factory _ImgurMediaItem.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    return _ImgurMediaItem(
      url: json['url'] as String?,
      mimeType: json['mime_type'] as String?,
      isAnimated: json['animated'] as bool? ??
          (metadata is Map<String, dynamic>
              ? metadata['is_animated'] as bool? ?? false
              : false),
    );
  }

  final String? url;
  final String? mimeType;
  final bool isAnimated;
}
