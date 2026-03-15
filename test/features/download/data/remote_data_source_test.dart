import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/imgur_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/lightshot_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

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
}
