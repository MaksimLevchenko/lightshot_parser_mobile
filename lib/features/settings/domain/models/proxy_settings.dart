import 'package:equatable/equatable.dart';

class ProxySettings extends Equatable {
  const ProxySettings({
    required this.enabled,
    required this.useAuthentication,
    required this.address,
    required this.port,
    required this.login,
    required this.password,
  });

  const ProxySettings.initial()
      : enabled = false,
        useAuthentication = false,
        address = '',
        port = '',
        login = '',
        password = '';

  final bool enabled;
  final bool useAuthentication;
  final String address;
  final String port;
  final String login;
  final String password;

  ProxySettings copyWith({
    bool? enabled,
    bool? useAuthentication,
    String? address,
    String? port,
    String? login,
    String? password,
  }) {
    return ProxySettings(
      enabled: enabled ?? this.enabled,
      useAuthentication: useAuthentication ?? this.useAuthentication,
      address: address ?? this.address,
      port: port ?? this.port,
      login: login ?? this.login,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'useAuthentication': useAuthentication,
      'address': address,
      'port': port,
      'login': login,
      'password': password,
    };
  }

  factory ProxySettings.fromJson(Map<String, dynamic> json) {
    return ProxySettings(
      enabled: (json['enabled'] as bool?) ?? false,
      useAuthentication: (json['useAuthentication'] as bool?) ?? false,
      address: (json['address'] as String?) ?? '',
      port: (json['port'] as String?) ?? '',
      login: (json['login'] as String?) ?? '',
      password: (json['password'] as String?) ?? '',
    );
  }

  factory ProxySettings.fromLegacyJson(Map<String, dynamic> json) {
    return ProxySettings(
      enabled: (json['useProxy'] as bool?) ?? false,
      useAuthentication: (json['useProxyAuth'] as bool?) ?? false,
      address: (json['proxyAddress'] as String?) ?? '',
      port: (json['proxyPort'] as String?) ?? '',
      login: (json['proxyLogin'] as String?) ?? '',
      password: (json['proxyPassword'] as String?) ?? '',
    );
  }

  String? toProxyString() {
    if (!enabled || address.isEmpty || port.isEmpty) {
      return null;
    }
    if (useAuthentication && login.isNotEmpty && password.isNotEmpty) {
      return 'PROXY $login:$password@$address:$port';
    }
    return 'PROXY $address:$port';
  }

  @override
  List<Object?> get props => [
        enabled,
        useAuthentication,
        address,
        port,
        login,
        password,
      ];
}
