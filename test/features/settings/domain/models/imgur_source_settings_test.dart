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

  test('copyWith preserves selected length order while normalizing values', () {
    const settings = ImgurSourceSettings.initial();

    final updated = settings.copyWith(candidateLengths: [7, 5, 7, -1]);

    expect(updated.candidateLengths, [7, 5]);
    expect(updated.idLength, 7);
  });

  test('toJson and fromJson keep the selected length as the first candidate',
      () {
    const settings = ImgurSourceSettings(
      candidateLengths: [7, 5],
      useRandomAddress: false,
      startingId: 'abcdefg',
    );

    final restored = ImgurSourceSettings.fromJson(settings.toJson());

    expect(restored.candidateLengths, [7, 5]);
    expect(restored.idLength, 7);
  });
}
