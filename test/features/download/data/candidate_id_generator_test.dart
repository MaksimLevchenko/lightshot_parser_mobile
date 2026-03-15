import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/candidate_id_generator.dart';

void main() {
  test('imgur random generator uses requested length and allowed symbols', () {
    final generator = RandomIdGenerator(
      symbols: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
      length: 7,
    );

    final value = generator.current;

    expect(value, hasLength(7));
    expect(RegExp(r'^[a-zA-Z0-9]{7}$').hasMatch(value), isTrue);
  });

  test('imgur sequential generator increments mixed-case alphanumeric ids', () {
    final generator = SequentialIdGenerator(
      symbols: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
      length: 5,
      startingId: 'aaaZ9',
    );

    generator.moveNext();

    expect(generator.current, 'aaa0a');
  });

  test('imgur multi-length random generator uses configured lengths', () {
    final generator = MultiLengthRandomIdGenerator(
      symbols: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
      lengths: [5, 7],
    );

    final generatedLengths = <int>{};
    for (var index = 0; index < 200; index++) {
      generatedLengths.add(generator.current.length);
      generator.moveNext();
    }

    expect(generatedLengths, containsAll([5, 7]));
  });
}
