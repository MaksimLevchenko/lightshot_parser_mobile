import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
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
    final scoresByCategory = <ClassificationCategory, double>{};

    for (final modelSpec in _defaultModelSpecs) {
      final preprocessedImage = _imagePreprocessor.preprocessDecodedImage(
        decodedImage: decodedImage,
        modelSpec: modelSpec,
      );
      final score = await _inferenceBackend.runModel(
        modelSpec: modelSpec,
        input: preprocessedImage,
      );
      scoresByCategory[modelSpec.category] = score;
    }

    final scores = ClassificationScores(
      nsfw: scoresByCategory[ClassificationCategory.nsfw] ?? 0,
      documents: scoresByCategory[ClassificationCategory.documents] ?? 0,
      games: scoresByCategory[ClassificationCategory.games] ?? 0,
    );

    return _cascadeClassifier.classify(
      scores: scores,
      thresholds: _modelThresholds,
      backend: _inferenceBackend.backendId,
      classifiedAt: DateTime.now(),
    );
  }

  Future<GalleryItem> classifyPendingGalleryItem({
    required GalleryItem item,
  }) async {
    try {
      final result = await classifyFile(imagePath: item.path);
      return item.copyWith(classificationResult: result);
    } on Object {
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

  List<ModelSpec> get _defaultModelSpecs {
    return const <ModelSpec>[
      // TODO(onnx-assets): Place the production models into assets/ml/models/ using the paths below.
      // TODO(model-config): Replace the placeholder input and output names after the real ONNX models are wired in.
      ModelSpec(
        key: 'nsfw',
        category: ClassificationCategory.nsfw,
        assetPath: 'assets/ml/models/nsfw.onnx',
        inputName: 'input',
        outputName: 'output',
        inputWidth: 224,
        inputHeight: 224,
      ),
      ModelSpec(
        key: 'documents',
        category: ClassificationCategory.documents,
        assetPath: 'assets/ml/models/documents.onnx',
        inputName: 'input',
        outputName: 'output',
        inputWidth: 224,
        inputHeight: 224,
      ),
      ModelSpec(
        key: 'games',
        category: ClassificationCategory.games,
        assetPath: 'assets/ml/models/games.onnx',
        inputName: 'input',
        outputName: 'output',
        inputWidth: 224,
        inputHeight: 224,
      ),
    ];
  }
}
