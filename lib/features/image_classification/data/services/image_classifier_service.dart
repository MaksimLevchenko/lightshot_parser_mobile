import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/core/logging/app_logger.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/backends/inference_backend.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/classifiers/cascade_classifier.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/model_spec.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/preprocessing/image_preprocessor.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_result.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_scores.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/model_thresholds.dart';

class ImageClassifierService {
  ImageClassifierService({
    required ImagePreprocessor imagePreprocessor,
    required InferenceBackend inferenceBackend,
    required CascadeClassifier cascadeClassifier,
    ModelThresholds modelThresholds = const ModelThresholds.defaults(),
  })  : _imagePreprocessor = imagePreprocessor,
        _inferenceBackend = inferenceBackend,
        _cascadeClassifier = cascadeClassifier,
        _modelThresholds = modelThresholds;

  final ImagePreprocessor _imagePreprocessor;
  final InferenceBackend _inferenceBackend;
  final CascadeClassifier _cascadeClassifier;
  final ModelThresholds _modelThresholds;

  String get backendId => _inferenceBackend.backendId;

  Future<ClassificationResult> classifyFile({
    required String imagePath,
  }) async {
    await _inferenceBackend.initialize();
    final decodedImage = await _imagePreprocessor.decodeFile(
      imagePath: imagePath,
    );

    final nsfwScore = await _runModel(
      decodedImage: decodedImage,
      modelSpec: _nsfwModelSpec,
    );
    if (nsfwScore >= _modelThresholds.nsfwThreshold) {
      return _buildResult(
        scores: ClassificationScores(
          nsfw: nsfwScore,
          people: 0,
          documents: 0,
        ),
      );
    }

    final documentsScore = await _runModel(
      decodedImage: decodedImage,
      modelSpec: _documentsModelSpec,
    );
    if (documentsScore >= _modelThresholds.documentThreshold) {
      return _buildResult(
        scores: ClassificationScores(
          nsfw: nsfwScore,
          people: 0,
          documents: documentsScore,
        ),
      );
    }

    final peopleScore = await _runModel(
      decodedImage: decodedImage,
      modelSpec: _peopleModelSpec,
    );
    return _buildResult(
      scores: ClassificationScores(
        nsfw: nsfwScore,
        people: peopleScore,
        documents: documentsScore,
      ),
    );
  }

  Future<double> _runModel({
    required DecodedImageData decodedImage,
    required ModelSpec modelSpec,
  }) async {
    final preprocessedImage = _imagePreprocessor.preprocessDecodedImage(
      decodedImage: decodedImage,
      modelSpec: modelSpec,
    );
    return _inferenceBackend.runModel(
      modelSpec: modelSpec,
      input: preprocessedImage,
    );
  }

  ClassificationResult _buildResult({
    required ClassificationScores scores,
  }) {
    final result = _cascadeClassifier.classify(
      scores: scores,
      thresholds: _modelThresholds,
      backend: _inferenceBackend.backendId,
      classifiedAt: DateTime.now(),
    );
    AppLogger.info(
      'Classification completed with backend=${_inferenceBackend.backendId} '
      'nsfw=${scores.nsfw.toStringAsFixed(4)} '
      'people=${scores.people.toStringAsFixed(4)} '
      'documents=${scores.documents.toStringAsFixed(4)} '
      'category=${result.category.name}',
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
          backend: _inferenceBackend.backendId,
          classifiedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> dispose() {
    return _inferenceBackend.dispose();
  }

  static const ModelSpec _nsfwModelSpec = ModelSpec(
    key: 'nsfw',
    category: ClassificationCategory.nsfw,
    assetPath: 'assets/ml/models/nsfw.onnx',
    inputName: 'input',
    outputName: 'logits',
    inputWidth: 384,
    inputHeight: 384,
    normalizationMean: <double>[0.5, 0.5, 0.5],
    normalizationStd: <double>[0.5, 0.5, 0.5],
  );

  static const ModelSpec _documentsModelSpec = ModelSpec(
    key: 'documents',
    category: ClassificationCategory.documents,
    assetPath: 'assets/ml/models/documents_float.onnx',
    inputName: 'input',
    outputName: 'output',
    inputWidth: 224,
    inputHeight: 224,
    normalizationMean: <double>[0, 0, 0],
    normalizationStd: <double>[1, 1, 1],
  );

  static const ModelSpec _peopleModelSpec = ModelSpec(
    key: 'people',
    category: ClassificationCategory.people,
    assetPath: 'assets/ml/models/people.onnx',
    inputName: 'inputs',
    taskType: ModelTaskType.personDetector,
    numDetectionsOutputName: 'num_detections',
    detectionBoxesOutputName: 'detection_boxes',
    detectionScoresOutputName: 'detection_scores',
    detectionClassesOutputName: 'detection_classes',
  );
}
