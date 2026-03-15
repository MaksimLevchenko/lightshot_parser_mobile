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
