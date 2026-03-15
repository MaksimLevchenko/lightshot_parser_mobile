import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/imgur_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/candidate_id_generator.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/download_source_engine.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class ImgurDownloadSource extends DownloadSourceEngine {
  ImgurDownloadSource(this._remoteDataSource);

  final ImgurRemoteDataSource _remoteDataSource;
  static const String _symbols =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  @override
  DownloadSource get source => DownloadSource.imgur;

  @override
  CandidateIdGenerator createGenerator(DownloadRequest request) {
    final settings = request.imgurSettings;
    return settings.useRandomAddress
        ? RandomIdGenerator(symbols: _symbols, length: settings.idLength)
        : SequentialIdGenerator(
            symbols: _symbols,
            length: settings.idLength,
            startingId: settings.startingId,
          );
  }

  @override
  Future<ResolvedImage> resolveImage({
    required String sourceId,
    required ProxySettings proxySettings,
  }) async {
    final imageUrl = await _remoteDataSource.resolveImageUrl(
      pageUrl: Uri.parse('https://imgur.com/$sourceId'),
      proxySettings: proxySettings,
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
