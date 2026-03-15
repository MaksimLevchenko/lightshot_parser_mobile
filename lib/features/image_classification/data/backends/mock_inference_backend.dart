import 'package:lightshot_parser_mobile/features/image_classification/data/backends/inference_backend.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/model_spec.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/preprocessed_image_data.dart';

class MockInferenceBackend implements InferenceBackend {
  bool _isInitialized = false;

  @override
  String get backendId => 'mock';

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

    // TODO(onnx-runtime): Replace this deterministic stub with a real ONNX Runtime-backed backend.
    final modelSeed = _buildSeed(modelSpec.key);
    final combinedSeed =
        (input.signature * 37 + modelSeed * 17 + input.tensorElementCount) &
            0x7fffffff;
    return (combinedSeed % 1000) / 1000;
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }

  int _buildSeed(String value) {
    var hash = 19;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
