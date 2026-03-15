import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/app_settings.dart';

void main() {
  group('AppSettings.fromJson', () {
    test('defaults neural recognition flag to true for old json', () {
      final settings = AppSettings.fromJson(<String, dynamic>{
        'wantedNumOfImages': 12,
        'selectedSource': DownloadSource.lightshot.name,
        'lightshot': <String, dynamic>{},
        'imgur': <String, dynamic>{},
        'proxy': <String, dynamic>{},
      });

      expect(settings.isNeuralRecognitionEnabled, isTrue);
    });

    test('reads neural recognition flag when present', () {
      final settings = AppSettings.fromJson(<String, dynamic>{
        'wantedNumOfImages': 12,
        'isNeuralRecognitionEnabled': false,
        'selectedSource': DownloadSource.lightshot.name,
        'lightshot': <String, dynamic>{},
        'imgur': <String, dynamic>{},
        'proxy': <String, dynamic>{},
      });

      expect(settings.isNeuralRecognitionEnabled, isFalse);
    });
  });
}
