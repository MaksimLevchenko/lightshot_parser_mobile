import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_package;
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';

void main() {
  late Directory tempDirectory;
  late ImagePreprocessor imagePreprocessor;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'image_classifier_service_test_',
    );
    imagePreprocessor = ImagePreprocessor();
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('stops after nsfw when nsfw threshold is reached', () async {
    final backend = _RecordingInferenceBackend(
      scoresByModelKey: <String, double>{
        'nsfw': 0.91,
        'documents': 0.97,
      },
    );
    final service = ImageClassifierService(
      imagePreprocessor: imagePreprocessor,
      inferenceBackend: backend,
      cascadeClassifier: const CascadeClassifier(),
      modelThresholds: const ModelThresholds(
        nsfwThreshold: 0.85,
        documentThreshold: 0.80,
      ),
    );
    final imagePath = await _createImageFile(tempDirectory);

    final result = await service.classifyFile(imagePath: imagePath);

    expect(result.category, ClassificationCategory.nsfw);
    expect(result.rawScores.nsfw, 0.91);
    expect(result.rawScores.documents, 0);
    expect(backend.modelKeysRun, <String>['nsfw']);
  });

  test('runs documents only when nsfw threshold is not reached', () async {
    final backend = _RecordingInferenceBackend(
      scoresByModelKey: <String, double>{
        'nsfw': 0.42,
        'documents': 0.88,
      },
    );
    final service = ImageClassifierService(
      imagePreprocessor: imagePreprocessor,
      inferenceBackend: backend,
      cascadeClassifier: const CascadeClassifier(),
      modelThresholds: const ModelThresholds(
        nsfwThreshold: 0.85,
        documentThreshold: 0.80,
      ),
    );
    final imagePath = await _createImageFile(tempDirectory);

    final result = await service.classifyFile(imagePath: imagePath);

    expect(result.category, ClassificationCategory.documents);
    expect(result.rawScores.nsfw, 0.42);
    expect(result.rawScores.documents, 0.88);
    expect(backend.modelKeysRun, <String>['nsfw', 'documents']);
  });

  test('returns unrecognized when both cascade steps are below thresholds',
      () async {
    final backend = _RecordingInferenceBackend(
      scoresByModelKey: <String, double>{
        'nsfw': 0.20,
        'documents': 0.35,
      },
    );
    final service = ImageClassifierService(
      imagePreprocessor: imagePreprocessor,
      inferenceBackend: backend,
      cascadeClassifier: const CascadeClassifier(),
      modelThresholds: const ModelThresholds(
        nsfwThreshold: 0.85,
        documentThreshold: 0.80,
      ),
    );
    final imagePath = await _createImageFile(tempDirectory);

    final result = await service.classifyFile(imagePath: imagePath);

    expect(result.category, ClassificationCategory.unrecognized);
    expect(result.rawScores.nsfw, 0.20);
    expect(result.rawScores.documents, 0.35);
    expect(backend.modelKeysRun, <String>['nsfw', 'documents']);
  });
}

class _RecordingInferenceBackend implements InferenceBackend {
  _RecordingInferenceBackend({
    required this.scoresByModelKey,
  });

  final Map<String, double> scoresByModelKey;
  final List<String> modelKeysRun = <String>[];

  bool _isInitialized = false;

  @override
  String get backendId => 'recording_test';

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<double> runModel({
    required ModelSpec modelSpec,
    required PreprocessedImageData input,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    modelKeysRun.add(modelSpec.key);
    return scoresByModelKey[modelSpec.key] ?? 0;
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}

Future<String> _createImageFile(Directory tempDirectory) async {
  final image = image_package.Image(width: 2, height: 2)
    ..setPixelRgb(0, 0, 255, 0, 0)
    ..setPixelRgb(1, 0, 0, 255, 0)
    ..setPixelRgb(0, 1, 0, 0, 255)
    ..setPixelRgb(1, 1, 255, 255, 255);
  final file = File('${tempDirectory.path}/sample.png');
  await file.writeAsBytes(image_package.encodePng(image), flush: true);
  return file.path;
}
