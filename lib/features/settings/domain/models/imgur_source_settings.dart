import 'package:equatable/equatable.dart';

class ImgurSourceSettings extends Equatable {
  const ImgurSourceSettings({
    required this.candidateLengths,
    required this.useRandomAddress,
    required this.startingId,
  });

  const ImgurSourceSettings.initial()
      : candidateLengths = const [5, 7],
        useRandomAddress = true,
        startingId = '';

  final List<int> candidateLengths;
  final bool useRandomAddress;
  final String startingId;

  int get idLength => candidateLengths.first;

  ImgurSourceSettings copyWith({
    List<int>? candidateLengths,
    bool? useRandomAddress,
    String? startingId,
  }) {
    final normalizedLengths = _normalizeCandidateLengths(
      candidateLengths ?? this.candidateLengths,
    );
    return ImgurSourceSettings(
      candidateLengths: normalizedLengths,
      useRandomAddress: useRandomAddress ?? this.useRandomAddress,
      startingId: startingId ?? this.startingId,
    );
  }

  Map<String, dynamic> toJson() {
    final normalizedLengths = _normalizeCandidateLengths(candidateLengths);
    return {
      'candidateLengths': normalizedLengths,
      'useRandomAddress': useRandomAddress,
      'startingId': useRandomAddress ? '' : startingId,
    };
  }

  factory ImgurSourceSettings.fromJson(Map<String, dynamic> json) {
    final rawCandidateLengths = json['candidateLengths'];
    final legacyLength = json['idLength'] as int?;

    return ImgurSourceSettings(
      candidateLengths: _normalizeCandidateLengths(
        rawCandidateLengths is List
            ? rawCandidateLengths.whereType<int>().toList(growable: false)
            : <int>[
                if (legacyLength != null) legacyLength,
              ],
      ),
      useRandomAddress: (json['useRandomAddress'] as bool?) ?? true,
      startingId: (json['startingId'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [candidateLengths, useRandomAddress, startingId];

  static List<int> _normalizeCandidateLengths(List<int> values) {
    final normalized = values.where((value) => value > 0).toSet().toList()
      ..sort();
    return normalized.isEmpty
        ? const [5, 7]
        : List<int>.unmodifiable(normalized);
  }
}
