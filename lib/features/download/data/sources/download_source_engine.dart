import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/candidate_id_generator.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';

class ResolvedImage {
  const ResolvedImage({
    required this.imageUrl,
    required this.fileExtension,
  });

  final String imageUrl;
  final String fileExtension;
}

abstract class DownloadSourceEngine {
  DownloadSource get source;

  CandidateIdGenerator createGenerator(DownloadRequest request);

  Future<ResolvedImage> resolveImage({
    required String sourceId,
    required ProxySettings proxySettings,
    required CancelToken cancelToken,
  });

  Future<File> downloadImage({
    required String imageUrl,
    required String targetPath,
    required CancelToken cancelToken,
    required ProxySettings proxySettings,
  });

  String createTrackingKey(String sourceId) {
    return buildTrackingKey(source, sourceId);
  }
}
