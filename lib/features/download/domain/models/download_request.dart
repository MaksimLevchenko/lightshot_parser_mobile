import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/imgur_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/lightshot_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class DownloadRequest extends Equatable {
  const DownloadRequest({
    required this.targetCount,
    required this.source,
    required this.lightshotSettings,
    required this.imgurSettings,
    required this.proxySettings,
  });

  final int targetCount;
  final DownloadSource source;
  final LightshotSourceSettings lightshotSettings;
  final ImgurSourceSettings imgurSettings;
  final ProxySettings proxySettings;

  @override
  List<Object?> get props => [
        targetCount,
        source,
        lightshotSettings,
        imgurSettings,
        proxySettings,
      ];
}
