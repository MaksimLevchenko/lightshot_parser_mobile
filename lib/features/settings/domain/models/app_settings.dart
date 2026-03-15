import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class AppSettings extends Equatable {
  const AppSettings({
    required this.wantedNumOfImages,
    required this.useNewAddresses,
    required this.useRandomAddress,
    required this.startingUrl,
    required this.proxySettings,
  });

  const AppSettings.initial()
      : wantedNumOfImages = 10,
        useNewAddresses = false,
        useRandomAddress = true,
        startingUrl = '',
        proxySettings = const ProxySettings.initial();

  final int wantedNumOfImages;
  final bool useNewAddresses;
  final bool useRandomAddress;
  final String startingUrl;
  final ProxySettings proxySettings;

  AppSettings copyWith({
    int? wantedNumOfImages,
    bool? useNewAddresses,
    bool? useRandomAddress,
    String? startingUrl,
    ProxySettings? proxySettings,
  }) {
    return AppSettings(
      wantedNumOfImages: wantedNumOfImages ?? this.wantedNumOfImages,
      useNewAddresses: useNewAddresses ?? this.useNewAddresses,
      useRandomAddress: useRandomAddress ?? this.useRandomAddress,
      startingUrl: startingUrl ?? this.startingUrl,
      proxySettings: proxySettings ?? this.proxySettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numOfImages': wantedNumOfImages,
      'newAddresses': useNewAddresses,
      'startingUrl': useRandomAddress ? '' : startingUrl,
      'useProxy': proxySettings.enabled,
      'useProxyAuth': proxySettings.useAuthentication,
      'proxyAddress': proxySettings.address,
      'proxyPort': proxySettings.port,
      'proxyLogin': proxySettings.login,
      'proxyPassword': proxySettings.password,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final startingUrl = (json['startingUrl'] as String?) ?? '';
    return AppSettings(
      wantedNumOfImages: (json['numOfImages'] as int?) ?? 10,
      useNewAddresses: (json['newAddresses'] as bool?) ?? false,
      useRandomAddress: startingUrl.isEmpty,
      startingUrl: startingUrl,
      proxySettings: ProxySettings(
        enabled: (json['useProxy'] as bool?) ?? false,
        useAuthentication: (json['useProxyAuth'] as bool?) ?? false,
        address: (json['proxyAddress'] as String?) ?? '',
        port: (json['proxyPort'] as String?) ?? '',
        login: (json['proxyLogin'] as String?) ?? '',
        password: (json['proxyPassword'] as String?) ?? '',
      ),
    );
  }

  @override
  List<Object?> get props => [
        wantedNumOfImages,
        useNewAddresses,
        useRandomAddress,
        startingUrl,
        proxySettings,
      ];
}
