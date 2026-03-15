import 'package:equatable/equatable.dart';

class ImgurSourceSettings extends Equatable {
  const ImgurSourceSettings({
    required this.idLength,
    required this.useRandomAddress,
    required this.startingId,
  });

  const ImgurSourceSettings.initial()
      : idLength = 7,
        useRandomAddress = true,
        startingId = '';

  final int idLength;
  final bool useRandomAddress;
  final String startingId;

  ImgurSourceSettings copyWith({
    int? idLength,
    bool? useRandomAddress,
    String? startingId,
  }) {
    return ImgurSourceSettings(
      idLength: idLength ?? this.idLength,
      useRandomAddress: useRandomAddress ?? this.useRandomAddress,
      startingId: startingId ?? this.startingId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idLength': idLength,
      'useRandomAddress': useRandomAddress,
      'startingId': useRandomAddress ? '' : startingId,
    };
  }

  factory ImgurSourceSettings.fromJson(Map<String, dynamic> json) {
    return ImgurSourceSettings(
      idLength: (json['idLength'] as int?) ?? 7,
      useRandomAddress: (json['useRandomAddress'] as bool?) ?? true,
      startingId: (json['startingId'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [idLength, useRandomAddress, startingId];
}
