import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_result.dart';

class GalleryItem extends Equatable {
  const GalleryItem({
    required this.path,
    required this.source,
    required this.sourceId,
    required this.classificationResult,
  });

  final String path;
  final DownloadSource source;
  final String sourceId;
  final ClassificationResult classificationResult;

  File get file => File(path);
  String get id => sourceId;
  String get trackingKey => buildTrackingKey(source, sourceId);
  String get storageFileStem => trackingKey;

  factory GalleryItem.fromFile(
    File file, {
    ClassificationResult? classificationResult,
  }) {
    final fileName = file.uri.pathSegments.last;
    final dotIndex = fileName.lastIndexOf('.');
    final trackingKey =
        dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);
    final parsed = parseTrackingKey(trackingKey);
    return GalleryItem(
      path: file.path,
      source: parsed.source,
      sourceId: parsed.sourceId,
      classificationResult:
          classificationResult ?? ClassificationResult.legacy(),
    );
  }

  GalleryItem copyWith({
    String? path,
    DownloadSource? source,
    String? sourceId,
    ClassificationResult? classificationResult,
  }) {
    return GalleryItem(
      path: path ?? this.path,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      classificationResult: classificationResult ?? this.classificationResult,
    );
  }

  @override
  List<Object?> get props => [path, source, sourceId, classificationResult];
}
