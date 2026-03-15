import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';

void main() {
  final backend = OnnxInferenceBackend();
  const nsfwSpec = ModelSpec(
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
  const documentsSpec = ModelSpec(
    key: 'documents',
    category: ClassificationCategory.documents,
    assetPath: 'assets/ml/models/documents.onnx',
    inputName: 'input',
    outputName: 'output',
    inputWidth: 224,
    inputHeight: 224,
  );

  test('nsfw logits return class zero probability', () async {
    final score = await backend.extractScoreForTesting(
      modelSpec: nsfwSpec,
      rawOutput: <dynamic>[4.0, 1.0],
      outputShape: const <int>[1, 2],
    );

    expect(score, closeTo(0.9526, 0.0001));
  });

  test('documents logits return class zero probability', () async {
    final score = await backend.extractScoreForTesting(
      modelSpec: documentsSpec,
      rawOutput: <dynamic>[2.0, 1.0],
      outputShape: const <int>[1, 2],
    );

    expect(score, closeTo(0.7311, 0.0001));
  });

  test('documents probabilities return class zero probability directly',
      () async {
    final score = await backend.extractScoreForTesting(
      modelSpec: documentsSpec,
      rawOutput: <dynamic>[0.82, 0.18],
      outputShape: const <int>[1, 2],
    );

    expect(score, 0.82);
  });

  test('documents scalar output throws descriptive exception', () async {
    expect(
      () => backend.extractScoreForTesting(
        modelSpec: documentsSpec,
        rawOutput: <dynamic>[0.82],
        outputShape: const <int>[1],
      ),
      throwsA(isA<OnnxInferenceException>()),
    );
  });
}
