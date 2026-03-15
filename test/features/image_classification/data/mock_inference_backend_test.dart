import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';

void main() {
  test('mock backend returns deterministic score for same input', () async {
    final backend = MockInferenceBackend();
    const modelSpec = ModelSpec(
      key: 'games',
      category: ClassificationCategory.games,
      assetPath: 'assets/ml/models/games.onnx',
      inputName: 'input',
      outputName: 'output',
      inputWidth: 224,
      inputHeight: 224,
    );
    final input = PreprocessedImageData(
      tensor: Float32List.fromList(<double>[0.1, 0.2, 0.3]),
      width: 224,
      height: 224,
      channels: 3,
      signature: 123456,
    );

    final firstScore = await backend.runModel(
      modelSpec: modelSpec,
      input: input,
    );
    final secondScore = await backend.runModel(
      modelSpec: modelSpec,
      input: input,
    );

    expect(firstScore, secondScore);
    expect(firstScore, inInclusiveRange(0, 1));
  });
}
