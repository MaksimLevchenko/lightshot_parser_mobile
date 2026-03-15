import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/imgur_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/lightshot_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class AppSettings extends Equatable {
  const AppSettings({
    required this.wantedNumOfImages,
    required this.isNeuralRecognitionEnabled,
    required this.selectedSource,
    required this.lightshot,
    required this.imgur,
    required this.proxySettings,
  });

  const AppSettings.initial()
      : wantedNumOfImages = 10,
        isNeuralRecognitionEnabled = true,
        selectedSource = DownloadSource.lightshot,
        lightshot = const LightshotSourceSettings.initial(),
        imgur = const ImgurSourceSettings.initial(),
        proxySettings = const ProxySettings.initial();

  final int wantedNumOfImages;
  final bool isNeuralRecognitionEnabled;
  final DownloadSource selectedSource;
  final LightshotSourceSettings lightshot;
  final ImgurSourceSettings imgur;
  final ProxySettings proxySettings;

  AppSettings copyWith({
    int? wantedNumOfImages,
    bool? isNeuralRecognitionEnabled,
    DownloadSource? selectedSource,
    LightshotSourceSettings? lightshot,
    ImgurSourceSettings? imgur,
    ProxySettings? proxySettings,
  }) {
    return AppSettings(
      wantedNumOfImages: wantedNumOfImages ?? this.wantedNumOfImages,
      isNeuralRecognitionEnabled:
          isNeuralRecognitionEnabled ?? this.isNeuralRecognitionEnabled,
      selectedSource: selectedSource ?? this.selectedSource,
      lightshot: lightshot ?? this.lightshot,
      imgur: imgur ?? this.imgur,
      proxySettings: proxySettings ?? this.proxySettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wantedNumOfImages': wantedNumOfImages,
      'isNeuralRecognitionEnabled': isNeuralRecognitionEnabled,
      'selectedSource': selectedSource.name,
      'lightshot': lightshot.toJson(),
      'imgur': imgur.toJson(),
      'proxy': proxySettings.toJson(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final selectedSourceName = json['selectedSource'] as String?;
    final selectedSource = DownloadSource.values.where(
      (source) => source.name == selectedSourceName,
    );
    if (json.containsKey('lightshot') ||
        json.containsKey('imgur') ||
        json.containsKey('proxy')) {
      return AppSettings(
        wantedNumOfImages: (json['wantedNumOfImages'] as int?) ??
            (json['numOfImages'] as int?) ??
            10,
        isNeuralRecognitionEnabled:
            (json['isNeuralRecognitionEnabled'] as bool?) ?? true,
        selectedSource: selectedSource.isEmpty
            ? DownloadSource.lightshot
            : selectedSource.first,
        lightshot: LightshotSourceSettings.fromJson(
          (json['lightshot'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
        ),
        imgur: ImgurSourceSettings.fromJson(
          (json['imgur'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
        ),
        proxySettings: ProxySettings.fromJson(
          (json['proxy'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
        ),
      );
    }

    final startingUrl = (json['startingUrl'] as String?) ?? '';
    return AppSettings(
      wantedNumOfImages: (json['numOfImages'] as int?) ?? 10,
      isNeuralRecognitionEnabled: true,
      selectedSource: DownloadSource.lightshot,
      lightshot: LightshotSourceSettings(
        useNewAddresses: (json['newAddresses'] as bool?) ?? false,
        useRandomAddress: startingUrl.isEmpty,
        startingId: startingUrl,
      ),
      imgur: const ImgurSourceSettings.initial(),
      proxySettings: ProxySettings.fromLegacyJson(json),
    );
  }

  @override
  List<Object?> get props => [
        wantedNumOfImages,
        isNeuralRecognitionEnabled,
        selectedSource,
        lightshot,
        imgur,
        proxySettings,
      ];
}
