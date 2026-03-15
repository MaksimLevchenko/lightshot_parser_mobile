import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/imgur_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/lightshot_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class FakeImgurResolverDataSource extends ImgurRemoteDataSource {
  FakeImgurResolverDataSource(this._responses);

  final Map<String, Response<dynamic>> _responses;

  @override
  Future<Response<dynamic>> sendRequestUri({
    required Uri uri,
    required ProxySettings proxySettings,
    CancelToken? cancelToken,
    String method = 'GET',
    Map<String, Object?>? headers,
    bool followRedirects = true,
    ResponseType? responseType,
  }) async {
    final response = _responses['$method $uri'];
    if (response == null) {
      throw StateError('No mocked response for $method $uri');
    }
    return response;
  }
}

void main() {
  late HttpServer server;
  late Directory tempDirectory;
  late Future<void> Function(HttpRequest request) handleRequest;

  setUp(() async {
    handleRequest = (_) async {};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await handleRequest(request);
    });
    tempDirectory = await Directory.systemTemp.createTemp(
      'lightshot_parser_mobile_test_',
    );
  });

  tearDown(() async {
    await server.close(force: true);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Uri buildUri(String path) {
    return Uri.parse('http://${server.address.host}:${server.port}$path');
  }

  for (final statusCode in [404, 410]) {
    test(
      'Lightshot resolveImageUrl maps HTTP $statusCode to NoPhotoException',
      () async {
        handleRequest = (request) async {
          request.response.statusCode = statusCode;
          await request.response.close();
        };

        final dataSource = LightshotRemoteDataSource();

        await expectLater(
          dataSource.resolveImageUrl(
            pageUrl: buildUri('/missing'),
            proxySettings: const ProxySettings.initial(),
          ),
          throwsA(isA<NoPhotoException>()),
        );
      },
    );
  }

  test('Imgur resolveImageUrl maps HTTP 410 to NoPhotoException', () async {
    handleRequest = (request) async {
      request.response.statusCode = 410;
      await request.response.close();
    };

    final dataSource = ImgurRemoteDataSource();

    await expectLater(
      dataSource.resolveImageUrl(
        pageUrl: buildUri('/removed'),
        proxySettings: const ProxySettings.initial(),
      ),
      throwsA(isA<NoPhotoException>()),
    );
  });

  test('Imgur resolveImageUrl rejects generic shell pages', () async {
    final pageUrl = Uri.parse('https://imgur.com/zzzzz');
    final dataSource = FakeImgurResolverDataSource({
      'GET $pageUrl': Response<String>(
        requestOptions: RequestOptions(path: pageUrl.toString()),
        statusCode: 200,
        data: '''
<!doctype html>
<html>
  <head>
    <link rel="canonical" href="https://imgur.com/">
    <meta property="og:url" content="https://imgur.com/">
    <meta property="og:image" content="https://s.imgur.com/images/logo-1200-630.png">
  </head>
</html>
''',
      ),
    });

    await expectLater(
      dataSource.resolveImageUrl(
        pageUrl: pageUrl,
        proxySettings: const ProxySettings.initial(),
      ),
      throwsA(isA<NoPhotoException>()),
    );
  });

  test('Imgur resolveImageUrl validates still image from meta tags', () async {
    final pageUrl = Uri.parse('https://imgur.com/abcde');
    final imageUrl = Uri.parse('https://i.imgur.com/abcde.jpg');
    final dataSource = FakeImgurResolverDataSource({
      'GET $pageUrl': Response<String>(
        requestOptions: RequestOptions(path: pageUrl.toString()),
        statusCode: 200,
        data: '''
<!doctype html>
<html>
  <head>
    <link rel="canonical" href="$pageUrl">
    <meta property="og:url" content="$pageUrl">
    <meta property="og:image" content="$imageUrl">
  </head>
</html>
''',
      ),
      'HEAD $imageUrl': Response<void>(
        requestOptions: RequestOptions(path: imageUrl.toString()),
        statusCode: 200,
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['image/png'],
        }),
      ),
    });

    final resolvedImageUrl = await dataSource.resolveImageUrl(
      pageUrl: pageUrl,
      proxySettings: const ProxySettings.initial(),
    );

    expect(resolvedImageUrl, 'https://i.imgur.com/abcde.png');
  });

  test('Imgur resolveImageUrl uses first still image from postDataJSON',
      () async {
    final pageUrl = Uri.parse('https://imgur.com/album1');
    final stillImageUrl = Uri.parse('https://i.imgur.com/still.jpg');
    final dataSource = FakeImgurResolverDataSource({
      'GET $pageUrl': Response<String>(
        requestOptions: RequestOptions(path: pageUrl.toString()),
        statusCode: 200,
        data: '''
<!doctype html>
<html>
  <head>
    <link rel="canonical" href="$pageUrl">
    <script>window.postDataJSON="{\\"id\\":\\"album1\\",\\"is_album\\":true,\\"media\\":[{\\"url\\":\\"https://i.imgur.com/animated.gif\\",\\"mime_type\\":\\"image/gif\\",\\"metadata\\":{\\"is_animated\\":true}},{\\"url\\":\\"$stillImageUrl\\",\\"mime_type\\":\\"image/jpeg\\",\\"metadata\\":{\\"is_animated\\":false}}]}"</script>
  </head>
</html>
''',
      ),
      'HEAD $stillImageUrl': Response<void>(
        requestOptions: RequestOptions(path: stillImageUrl.toString()),
        statusCode: 200,
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['image/jpeg'],
        }),
      ),
    });

    final imageUrl = await dataSource.resolveImageUrl(
      pageUrl: pageUrl,
      proxySettings: const ProxySettings.initial(),
    );

    expect(imageUrl, 'https://i.imgur.com/still.jpeg');
  });

  test('Imgur resolveImageUrl rejects removed placeholders', () async {
    final pageUrl = Uri.parse('https://imgur.com/abcde');
    final imageUrl = Uri.parse('https://i.imgur.com/abcde.jpg');
    final dataSource = FakeImgurResolverDataSource({
      'GET $pageUrl': Response<String>(
        requestOptions: RequestOptions(path: pageUrl.toString()),
        statusCode: 200,
        data: '''
<!doctype html>
<html>
  <head>
    <link rel="canonical" href="$pageUrl">
    <meta property="og:url" content="$pageUrl">
    <meta property="og:image" content="$imageUrl">
  </head>
</html>
''',
      ),
      'HEAD $imageUrl': Response<void>(
        requestOptions: RequestOptions(path: imageUrl.toString()),
        statusCode: 302,
        headers: Headers.fromMap({
          HttpHeaders.locationHeader: ['https://i.imgur.com/removed.png'],
        }),
      ),
    });

    await expectLater(
      dataSource.resolveImageUrl(
        pageUrl: pageUrl,
        proxySettings: const ProxySettings.initial(),
      ),
      throwsA(isA<NoPhotoException>()),
    );
  });

  test('Lightshot resolveImageUrl maps timeout to NoPhotoException', () async {
    handleRequest = (request) async {
      await Future<void>.delayed(const Duration(seconds: 9));
      request.response.statusCode = 200;
      request.response.write(
        '<html><body><img src="https://image.example/test.jpg"></body></html>',
      );
      await request.response.close();
    };

    final dataSource = LightshotRemoteDataSource();

    await expectLater(
      dataSource.resolveImageUrl(
        pageUrl: buildUri('/slow-page'),
        proxySettings: const ProxySettings.initial(),
      ),
      throwsA(isA<NoPhotoException>()),
    );
  });

  for (final statusCode in [404, 410]) {
    test(
      'downloadImage maps HTTP $statusCode to NoPhotoException',
      () async {
        handleRequest = (request) async {
          request.response.statusCode = statusCode;
          await request.response.close();
        };

        final dataSource = LightshotRemoteDataSource();
        final targetPath =
            '${tempDirectory.path}${Platform.pathSeparator}missing.jpg';

        await expectLater(
          dataSource.downloadImage(
            imageUrl: buildUri('/missing.jpg').toString(),
            targetPath: targetPath,
            cancelToken: CancelToken(),
            proxySettings: const ProxySettings.initial(),
          ),
          throwsA(isA<NoPhotoException>()),
        );
      },
    );
  }

  test('downloadImage maps timeout to NoPhotoException', () async {
    handleRequest = (request) async {
      request.response.headers.contentType = ContentType.binary;
      await request.response.flush();
      await Future<void>.delayed(const Duration(seconds: 9));
      request.response.add(const [1, 2, 3]);
      await request.response.close();
    };

    final dataSource = LightshotRemoteDataSource();
    final targetPath = '${tempDirectory.path}${Platform.pathSeparator}slow.jpg';

    await expectLater(
      dataSource.downloadImage(
        imageUrl: buildUri('/slow.jpg').toString(),
        targetPath: targetPath,
        cancelToken: CancelToken(),
        proxySettings: const ProxySettings.initial(),
      ),
      throwsA(isA<NoPhotoException>()),
    );
  });
}
