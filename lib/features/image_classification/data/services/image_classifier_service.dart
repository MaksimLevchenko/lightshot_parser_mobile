import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:lightshot_parser_mobile/core/logging/app_logger.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/backends/inference_backend.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/backends/onnx_inference_backend.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/classifiers/cascade_classifier.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/preprocessing/image_preprocessor.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/services/classification_execution_backend.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_result.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_scores.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/model_thresholds.dart';

class ImageClassifierService {
  ImageClassifierService({
    required ImagePreprocessor imagePreprocessor,
    required InferenceBackend inferenceBackend,
    required CascadeClassifier cascadeClassifier,
    ModelThresholds modelThresholds = const ModelThresholds.defaults(),
    ClassificationExecutionBackend? executionBackend,
    RootIsolateToken? rootIsolateToken,
  })  : _cascadeClassifier = cascadeClassifier,
        _modelThresholds = modelThresholds,
        _executionBackend = executionBackend ??
            _buildExecutionBackend(
              imagePreprocessor: imagePreprocessor,
              inferenceBackend: inferenceBackend,
              modelThresholds: modelThresholds,
              rootIsolateToken: rootIsolateToken ?? RootIsolateToken.instance,
            );

  final CascadeClassifier _cascadeClassifier;
  final ModelThresholds _modelThresholds;
  final ClassificationExecutionBackend _executionBackend;
  Future<void> _classificationQueue = Future<void>.value();
  Future<void>? _warmUpFuture;

  String get backendId => _executionBackend.backendId;

  Future<void> warmUp() {
    return _warmUpFuture ??= _executionBackend.warmUp();
  }

  Future<ClassificationResult> classifyFile({
    required String imagePath,
  }) async {
    return _enqueueClassification<ClassificationResult>(() async {
      await warmUp();
      final executionResult =
          await _executionBackend.executeClassification(imagePath: imagePath);
      return _buildResult(
        scores: executionResult.scores,
        backendId: executionResult.backendId,
        executionPath: executionResult.executionPath,
        fallbackReason: executionResult.fallbackReason,
      );
    });
  }

  ClassificationResult _buildResult({
    required ClassificationScores scores,
    required String backendId,
    required String executionPath,
    String? fallbackReason,
  }) {
    final result = _cascadeClassifier.classify(
      scores: scores,
      thresholds: _modelThresholds,
      backend: backendId,
      classifiedAt: DateTime.now(),
    );
    AppLogger.info(
      'Classification completed with backend=$backendId '
      'executionPath=$executionPath '
      'nsfw=${scores.nsfw.toStringAsFixed(4)} '
      'people=${scores.people.toStringAsFixed(4)} '
      'documents=${scores.documents.toStringAsFixed(4)} '
      'category=${result.category.name}'
      '${fallbackReason == null ? '' : ' fallbackReason=$fallbackReason'}',
      scope: 'image_classification',
    );
    return result;
  }

  Future<GalleryItem> classifyPendingGalleryItem({
    required GalleryItem item,
  }) async {
    try {
      final result = await classifyFile(imagePath: item.path);
      return item.copyWith(classificationResult: result);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Classification failed for ${item.path}. Returning unrecognized fallback.',
        scope: 'image_classification',
        error: error,
        stackTrace: stackTrace,
      );
      return item.copyWith(
        classificationResult: ClassificationResult.unrecognized(
          backend: _executionBackend.backendId,
          classifiedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> dispose() {
    return _executionBackend.dispose();
  }

  Future<T> _enqueueClassification<T>(
    Future<T> Function() operation,
  ) {
    final completer = Completer<T>();
    _classificationQueue = _classificationQueue
        .catchError((Object _) {})
        .then((_) async {
      try {
        final result = await operation();
        completer.complete(result);
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  static ClassificationExecutionBackend _buildExecutionBackend({
    required ImagePreprocessor imagePreprocessor,
    required InferenceBackend inferenceBackend,
    required ModelThresholds modelThresholds,
    required RootIsolateToken? rootIsolateToken,
  }) {
    final localBackend = LocalClassificationExecutionBackend(
      imagePreprocessor: imagePreprocessor,
      inferenceBackend: inferenceBackend,
      modelThresholds: modelThresholds,
    );
    final canUseWorker = !kIsWeb &&
        rootIsolateToken != null &&
        inferenceBackend is OnnxInferenceBackend;
    if (!canUseWorker) {
      return localBackend;
    }

    return IsolateClassificationExecutionBackend(
      fallbackBackend: localBackend,
      modelThresholds: modelThresholds,
      rootIsolateToken: rootIsolateToken,
    );
  }
}
