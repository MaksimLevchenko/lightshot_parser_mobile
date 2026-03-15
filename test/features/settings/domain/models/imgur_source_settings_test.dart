import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/imgur_source_settings.dart';

void main() {
  test('initial settings use multi-length whitelist defaults', () {
    const settings = ImgurSourceSettings.initial();

    expect(settings.candidateLengths, [5, 7]);
    expect(settings.idLength, 5);
  });

  test('fromJson migrates legacy idLength to candidateLengths', () {
    final settings = ImgurSourceSettings.fromJson(const {
      'idLength': 7,
      'useRandomAddress': false,
      'startingId': 'abcdefg',
    });

    expect(settings.candidateLengths, [7]);
    expect(settings.idLength, 7);
    expect(settings.useRandomAddress, isFalse);
    expect(settings.startingId, 'abcdefg');
  });

  test('copyWith normalizes candidate lengths', () {
    const settings = ImgurSourceSettings.initial();

    final updated = settings.copyWith(candidateLengths: [7, 5, 7, -1]);

    expect(updated.candidateLengths, [5, 7]);
    expect(updated.idLength, 5);
  });
}
