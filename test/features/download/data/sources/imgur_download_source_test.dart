import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/imgur_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/imgur_download_source.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/imgur_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/lightshot_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

void main() {
  test('random imgur generator uses the selected id length', () {
    final source = ImgurDownloadSource(ImgurRemoteDataSource());
    const request = DownloadRequest(
      targetCount: 1,
      source: DownloadSource.imgur,
      lightshotSettings: LightshotSourceSettings.initial(),
      imgurSettings: ImgurSourceSettings(
        candidateLengths: [7, 5],
        useRandomAddress: true,
        startingId: '',
      ),
      proxySettings: ProxySettings.initial(),
    );

    final generator = source.createGenerator(request);

    for (var index = 0; index < 25; index++) {
      expect(generator.current, hasLength(7));
      generator.moveNext();
    }
  });
}
