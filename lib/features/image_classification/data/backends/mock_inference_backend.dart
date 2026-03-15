import 'package:lightshot_parser_mobile/features/image_classification/data/backends/inference_backend.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/model_spec.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/preprocessed_image_data.dart';

class MockInferenceBackend implements InferenceBackend {
  MockInferenceBackend({
    Map<String, double>? scoresByModelKey,
    double Function(ModelSpec modelSpec, PreprocessedImageData input)?
        scoreResolver,
  })  : _scoresByModelKey = scoresByModelKey ?? const <String, double>{},
        _scoreResolver = scoreResolver;

  final Map<String, double> _scoresByModelKey;
  final double Function(ModelSpec modelSpec, PreprocessedImageData input)?
      _scoreResolver;

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

    final configuredScore = _scoresByModelKey[modelSpec.key];
    if (configuredScore != null) {
      return _clampScore(configuredScore);
    }

    final resolvedScore = _scoreResolver?.call(modelSpec, input);
    if (resolvedScore != null) {
      return _clampScore(resolvedScore);
    }

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

  double _clampScore(double score) {
    if (score < 0) {
      return 0;
    }
    if (score > 1) {
      return 1;
    }
    return score;
  }
}
