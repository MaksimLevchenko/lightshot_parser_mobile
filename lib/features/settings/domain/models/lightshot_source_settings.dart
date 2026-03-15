import 'package:equatable/equatable.dart';

class LightshotSourceSettings extends Equatable {
  const LightshotSourceSettings({
    required this.useNewAddresses,
    required this.useRandomAddress,
    required this.startingId,
  });

  const LightshotSourceSettings.initial()
      : useNewAddresses = false,
        useRandomAddress = true,
        startingId = '';

  final bool useNewAddresses;
  final bool useRandomAddress;
  final String startingId;

  int get idLength => useNewAddresses ? 12 : 6;

  LightshotSourceSettings copyWith({
    bool? useNewAddresses,
    bool? useRandomAddress,
    String? startingId,
  }) {
    return LightshotSourceSettings(
      useNewAddresses: useNewAddresses ?? this.useNewAddresses,
      useRandomAddress: useRandomAddress ?? this.useRandomAddress,
      startingId: startingId ?? this.startingId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useNewAddresses': useNewAddresses,
      'useRandomAddress': useRandomAddress,
      'startingId': useRandomAddress ? '' : startingId,
    };
  }

  factory LightshotSourceSettings.fromJson(Map<String, dynamic> json) {
    return LightshotSourceSettings(
      useNewAddresses: (json['useNewAddresses'] as bool?) ?? false,
      useRandomAddress: (json['useRandomAddress'] as bool?) ?? true,
      startingId: (json['startingId'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [useNewAddresses, useRandomAddress, startingId];
}
