import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/lightshot_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/candidate_id_generator.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/download_source_engine.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class LightshotDownloadSource extends DownloadSourceEngine {
  LightshotDownloadSource(this._remoteDataSource);

  final LightshotRemoteDataSource _remoteDataSource;

  @override
  DownloadSource get source => DownloadSource.lightshot;

  @override
  CandidateIdGenerator createGenerator(DownloadRequest request) {
    final settings = request.lightshotSettings;
    final symbols = settings.useNewAddresses
        ? 'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ_-'
        : 'abcdefghijklmnopqrstuvwxyz1234567890';
    final length = settings.useNewAddresses ? 12 : 6;

    return settings.useRandomAddress
        ? RandomIdGenerator(symbols: symbols, length: length)
        : SequentialIdGenerator(
            symbols: symbols,
            length: length,
            startingId: settings.startingId,
          );
  }

  @override
  Future<ResolvedImage> resolveImage({
    required String sourceId,
    required ProxySettings proxySettings,
    required CancelToken cancelToken,
  }) async {
    final imageUrl = await _remoteDataSource.resolveImageUrl(
      pageUrl: Uri.parse('https://prnt.sc/$sourceId'),
      proxySettings: proxySettings,
      cancelToken: cancelToken,
    );
    return ResolvedImage(
      imageUrl: imageUrl,
      fileExtension: _extractFileExtension(imageUrl),
    );
  }

  @override
  Future<File> downloadImage({
    required String imageUrl,
    required String targetPath,
    required CancelToken cancelToken,
    required ProxySettings proxySettings,
  }) {
    return _remoteDataSource.downloadImage(
      imageUrl: imageUrl,
      targetPath: targetPath,
      cancelToken: cancelToken,
      proxySettings: proxySettings,
    );
  }

  String _extractFileExtension(String imageUrl) {
    final path = Uri.parse(imageUrl).path;
    final dotIndex = path.lastIndexOf('.');
    return dotIndex == -1 ? '.jpg' : path.substring(dotIndex);
  }
}
