import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class DownloadRequest extends Equatable {
  const DownloadRequest({
    required this.targetCount,
    required this.useNewAddresses,
    required this.useRandomAddress,
    required this.startingUrl,
    required this.proxySettings,
  });

  final int targetCount;
  final bool useNewAddresses;
  final bool useRandomAddress;
  final String startingUrl;
  final ProxySettings proxySettings;

  @override
  List<Object?> get props => [
        targetCount,
        useNewAddresses,
        useRandomAddress,
        startingUrl,
        proxySettings,
      ];
}
