import 'dart:math';

abstract class CandidateIdGenerator {
  String get current;
  bool moveNext();
}

class SequentialIdGenerator implements CandidateIdGenerator {
  SequentialIdGenerator({
    required String symbols,
    required int length,
    required String startingId,
  })  : _symbols = symbols,
        _length = length {
    if (startingId.length != _length ||
        startingId.split('').any((char) => !_symbols.contains(char))) {
      _currentValue = List<String>.filled(_length, 'a').join();
    } else {
      _currentValue = startingId;
    }
    _indexes =
        _currentValue.split('').map(_symbols.indexOf).toList(growable: false);
  }

  final String _symbols;
  final int _length;
  late List<int> _indexes;
  late String _currentValue;

  @override
  String get current => _currentValue;

  @override
  bool moveNext() {
    final nextIndexes = List<int>.from(_indexes);
    nextIndexes[_length - 1] += 1;
    for (int index = _length - 1; index >= 0; index--) {
      if (nextIndexes[index] == _symbols.length) {
        nextIndexes[index] = 0;
        if (index > 0) {
          nextIndexes[index - 1] += 1;
        }
      }
    }
    _indexes = nextIndexes;
    _currentValue = _indexes.map((index) => _symbols[index]).join();
    return true;
  }
}

class RandomIdGenerator implements CandidateIdGenerator {
  RandomIdGenerator({
    required String symbols,
    required int length,
  })  : _symbols = symbols,
        _length = length {
    moveNext();
  }

  final String _symbols;
  final int _length;
  final Random _random = Random();
  late String _currentValue;

  @override
  String get current => _currentValue;

  @override
  bool moveNext() {
    _currentValue = String.fromCharCodes(
      Iterable<int>.generate(
        _length,
        (_) => _symbols.codeUnitAt(_random.nextInt(_symbols.length)),
      ),
    );
    return true;
  }
}
