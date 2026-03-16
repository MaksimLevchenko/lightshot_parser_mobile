import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'package:lightshot_parser_mobile/core/logging/app_logger.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/backends/inference_backend.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/model_spec.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/preprocessed_image_data.dart';

class OnnxInferenceBackend implements InferenceBackend {
  OnnxInferenceBackend({
    OnnxRuntime? runtime,
    Map<String, String>? modelPathOverridesByAssetPath,
  })  : _runtime = runtime ?? OnnxRuntime(),
        _modelPathOverridesByAssetPath =
            modelPathOverridesByAssetPath ?? const <String, String>{};

  static const int _cocoPersonClassId = 1;

  final OnnxRuntime _runtime;
  final Map<String, String> _modelPathOverridesByAssetPath;
  final Map<String, Future<OrtSession>> _sessionFutures =
      <String, Future<OrtSession>>{};

  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  String get backendId => 'onnx_runtime';

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _ensureNotDisposed();
    _isInitialized = true;
    AppLogger.info(
      'Initialized ONNX Runtime backend',
      scope: 'image_classification',
    );
  }

  @override
  Future<void> preloadModels(Iterable<ModelSpec> modelSpecs) async {
    if (!_isInitialized) {
      await initialize();
    }

    for (final modelSpec in modelSpecs) {
      AppLogger.info(
        'Warmup started for model ${modelSpec.key}',
        scope: 'image_classification',
      );
      await _getOrCreateSession(modelSpec);
      AppLogger.info(
        'Warmup completed for model ${modelSpec.key}',
        scope: 'image_classification',
      );
    }
  }

  @override
  Future<double> runModel({
    required ModelSpec modelSpec,
    required PreprocessedImageData input,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final session = await _getOrCreateSession(modelSpec);
    OrtValue? inputValue;
    Map<String, OrtValue>? outputs;

    AppLogger.info(
      'Running model ${modelSpec.key} from ${modelSpec.assetPath} '
      'task=${modelSpec.taskType.name} '
      'with input=${input.width}x${input.height} '
      'shape=${input.shape.join("x")} '
      'layout=${input.layout.name} '
      'dtype=${input.dataType.name}',
      scope: 'image_classification',
    );

    try {
      inputValue = await OrtValue.fromList(input.tensor, input.shape);
      outputs = await session.run(
        <String, OrtValue>{
          modelSpec.inputName: inputValue,
        },
      );

      final score = await _extractModelScore(
        modelSpec: modelSpec,
        outputs: outputs,
      );
      AppLogger.info(
        'Extracted score ${score.toStringAsFixed(4)} for model ${modelSpec.key}',
        scope: 'image_classification',
      );
      return score;
    } finally {
      if (outputs != null) {
        for (final value in outputs.values) {
          await value.dispose();
        }
      }
      if (inputValue != null) {
        await inputValue.dispose();
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    final pendingSessions =
        List<Future<OrtSession>>.from(_sessionFutures.values);
    _sessionFutures.clear();

    for (final futureSession in pendingSessions) {
      try {
        final session = await futureSession;
        await session.close();
      } on Object catch (error, stackTrace) {
        AppLogger.warning(
          'Failed to close ONNX session cleanly.',
          scope: 'image_classification',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _isInitialized = false;
    _isDisposed = true;
  }

  @visibleForTesting
  Future<double> extractScoreForTesting({
    required ModelSpec modelSpec,
    required List<dynamic> rawOutput,
    required List<int> outputShape,
  }) {
    return _extractScoreFromValues(
      modelSpec: modelSpec,
      rawOutput: rawOutput,
      outputShape: outputShape,
    );
  }

  Future<OrtSession> _getOrCreateSession(ModelSpec modelSpec) {
    _ensureNotDisposed();
    final existingFuture = _sessionFutures[modelSpec.assetPath];
    if (existingFuture != null) {
      return existingFuture;
    }

    final sessionFuture = _createSession(modelSpec);
    _sessionFutures[modelSpec.assetPath] = sessionFuture;
    return sessionFuture.catchError((Object error) {
      _sessionFutures.remove(modelSpec.assetPath);
      throw error;
    });
  }

  Future<OrtSession> _createSession(ModelSpec modelSpec) async {
    AppLogger.info(
      'Loading ONNX model ${modelSpec.key} from ${modelSpec.assetPath}',
      scope: 'image_classification',
    );
    final modelPathOverride = _modelPathOverridesByAssetPath[modelSpec.assetPath];
    if (modelPathOverride != null) {
      return _runtime.createSession(modelPathOverride);
    }
    return _runtime.createSessionFromAsset(modelSpec.assetPath);
  }

  Future<double> _extractScore({
    required ModelSpec modelSpec,
    required OrtValue outputValue,
  }) async {
    final rawOutput = await outputValue.asFlattenedList();
    return _extractScoreFromValues(
      modelSpec: modelSpec,
      rawOutput: rawOutput,
      outputShape: outputValue.shape,
    );
  }

  Future<double> _extractScoreFromValues({
    required ModelSpec modelSpec,
    required List<dynamic> rawOutput,
    required List<int> outputShape,
  }) async {
    if (modelSpec.taskType != ModelTaskType.binaryClassifier) {
      throw OnnxInferenceException(
        'extractScoreForTesting only supports binary classifier models. '
        'Model ${modelSpec.key} is ${modelSpec.taskType.name}.',
      );
    }

    final values = _coerceOutputValues(
      modelSpec: modelSpec,
      rawOutput: rawOutput,
      outputShape: outputShape,
    );
    AppLogger.info(
      'Model ${modelSpec.key} output shape=${_describeShape(outputShape)} '
      'values=${_previewValues(values)}',
      scope: 'image_classification',
    );

    return switch (modelSpec.key) {
      'nsfw' => _extractNsfwScore(
          modelSpec: modelSpec,
          values: values,
          outputShape: outputShape,
        ),
      'documents' => _extractDocumentsScore(
          modelSpec: modelSpec,
          values: values,
          outputShape: outputShape,
        ),
      _ => throw OnnxInferenceException(
          'Unsupported model key "${modelSpec.key}" for backend '
          '$backendId (${modelSpec.assetPath}).',
        ),
    };
  }

  Future<double> _extractModelScore({
    required ModelSpec modelSpec,
    required Map<String, OrtValue> outputs,
  }) async {
    return switch (modelSpec.taskType) {
      ModelTaskType.binaryClassifier => _extractClassifierModelScore(
          modelSpec: modelSpec,
          outputs: outputs,
        ),
      ModelTaskType.personDetector => _extractPersonDetectorModelScore(
          modelSpec: modelSpec,
          outputs: outputs,
        ),
      ModelTaskType.personDetectorYolo => _extractYoloPersonDetectorModelScore(
          modelSpec: modelSpec,
          outputs: outputs,
        ),
    };
  }

  Future<double> _extractClassifierModelScore({
    required ModelSpec modelSpec,
    required Map<String, OrtValue> outputs,
  }) async {
    final outputValue = outputs[modelSpec.outputName];
    if (outputValue == null) {
      throw OnnxInferenceException(
        'Missing output tensor "${modelSpec.outputName}" for model '
        '${modelSpec.key} (${modelSpec.assetPath}). '
        'Available outputs: ${outputs.keys.join(", ")}',
      );
    }

    return _extractScore(
      modelSpec: modelSpec,
      outputValue: outputValue,
    );
  }

  Future<double> _extractPersonDetectorModelScore({
    required ModelSpec modelSpec,
    required Map<String, OrtValue> outputs,
  }) async {
    final numDetectionsValue = _requireOutput(
      outputs: outputs,
      modelSpec: modelSpec,
      outputName: modelSpec.numDetectionsOutputName!,
    );
    final detectionBoxesValue = _requireOutput(
      outputs: outputs,
      modelSpec: modelSpec,
      outputName: modelSpec.detectionBoxesOutputName!,
    );
    final detectionScoresValue = _requireOutput(
      outputs: outputs,
      modelSpec: modelSpec,
      outputName: modelSpec.detectionScoresOutputName!,
    );
    final detectionClassesValue = _requireOutput(
      outputs: outputs,
      modelSpec: modelSpec,
      outputName: modelSpec.detectionClassesOutputName!,
    );

    AppLogger.info(
      'Detector outputs for ${modelSpec.key}: '
      '${modelSpec.numDetectionsOutputName}=${_describeShape(numDetectionsValue.shape)} '
      '${modelSpec.detectionBoxesOutputName}=${_describeShape(detectionBoxesValue.shape)} '
      '${modelSpec.detectionScoresOutputName}=${_describeShape(detectionScoresValue.shape)} '
      '${modelSpec.detectionClassesOutputName}=${_describeShape(detectionClassesValue.shape)}',
      scope: 'image_classification',
    );

    final numDetections = _coerceOutputValues(
      modelSpec: modelSpec,
      rawOutput: await numDetectionsValue.asFlattenedList(),
      outputShape: numDetectionsValue.shape,
    );
    final boxes = _coerceOutputValues(
      modelSpec: modelSpec,
      rawOutput: await detectionBoxesValue.asFlattenedList(),
      outputShape: detectionBoxesValue.shape,
    );
    final scores = _coerceOutputValues(
      modelSpec: modelSpec,
      rawOutput: await detectionScoresValue.asFlattenedList(),
      outputShape: detectionScoresValue.shape,
    );
    final classes = _coerceOutputValues(
      modelSpec: modelSpec,
      rawOutput: await detectionClassesValue.asFlattenedList(),
      outputShape: detectionClassesValue.shape,
    );

    final detectionCount = _resolveDetectionCount(
      modelSpec: modelSpec,
      numDetections: numDetections,
      boxes: boxes,
      scores: scores,
      classes: classes,
      boxesShape: detectionBoxesValue.shape,
      scoresShape: detectionScoresValue.shape,
      classesShape: detectionClassesValue.shape,
    );

    var personDetections = 0;
    var peopleScore = 0.0;
    for (var index = 0; index < detectionCount; index += 1) {
      final classId = classes[index].round();
      if (classId != _cocoPersonClassId) {
        continue;
      }

      personDetections += 1;
      final score = scores[index];
      if (score > peopleScore) {
        peopleScore = score;
      }
    }

    AppLogger.info(
      'Detector ${modelSpec.key} numDetections=$detectionCount '
      'personDetections=$personDetections '
      'peopleScore=${peopleScore.toStringAsFixed(4)}',
      scope: 'image_classification',
    );
    return peopleScore;
  }

  Future<double> _extractYoloPersonDetectorModelScore({
    required ModelSpec modelSpec,
    required Map<String, OrtValue> outputs,
  }) async {
    final outputValue = _requireOutput(
      outputs: outputs,
      modelSpec: modelSpec,
      outputName: modelSpec.outputName!,
    );
    final values = _coerceOutputValues(
      modelSpec: modelSpec,
      rawOutput: await outputValue.asFlattenedList(),
      outputShape: outputValue.shape,
    );
    final outputShape = outputValue.shape;

    if (outputShape.length != 3 ||
        outputShape[0] != 1 ||
        outputShape[1] != 84 ||
        outputShape[2] <= 0) {
      throw _unexpectedOutputException(
        modelSpec: modelSpec,
        outputShape: outputShape,
        values: values,
        reason: 'Expected YOLO output shape [1, 84, N].',
      );
    }

    final predictionCount = outputShape[2];
    final expectedValueCount = 84 * predictionCount;
    if (values.length != expectedValueCount) {
      throw _unexpectedOutputException(
        modelSpec: modelSpec,
        outputShape: outputShape,
        values: values,
        reason:
            'Unexpected YOLO output value count. Expected $expectedValueCount values.',
      );
    }

    var peopleScore = 0.0;
    for (var predictionIndex = 0;
        predictionIndex < predictionCount;
        predictionIndex += 1) {
      final personClassOffset = predictionCount * 4 + predictionIndex;
      final personScore = values[personClassOffset];
      if (personScore > peopleScore) {
        peopleScore = personScore;
      }
    }

    AppLogger.info(
      'YOLO detector ${modelSpec.key} predictionCount=$predictionCount '
      'peopleScore=${peopleScore.toStringAsFixed(4)}',
      scope: 'image_classification',
    );
    return peopleScore;
  }

  double _extractNsfwScore({
    required ModelSpec modelSpec,
    required List<double> values,
    required List<int> outputShape,
  }) {
    if (values.length != 2) {
      throw _unexpectedOutputException(
        modelSpec: modelSpec,
        outputShape: outputShape,
        values: values,
        reason: 'Expected binary logits output for NSFW model.',
      );
    }

    final probabilities = _softmax(values);
    return probabilities.first;
  }

  double _extractDocumentsScore({
    required ModelSpec modelSpec,
    required List<double> values,
    required List<int> outputShape,
  }) {
    if (values.length != 2) {
      throw _unexpectedOutputException(
        modelSpec: modelSpec,
        outputShape: outputShape,
        values: values,
        reason: 'Expected 2-class output for documents model.',
      );
    }

    if (_looksLikeProbabilityVector(values)) {
      return values.first;
    }

    final probabilities = _softmax(values);
    return probabilities.first;
  }

  OrtValue _requireOutput({
    required Map<String, OrtValue> outputs,
    required ModelSpec modelSpec,
    required String outputName,
  }) {
    final outputValue = outputs[outputName];
    if (outputValue != null) {
      return outputValue;
    }

    throw OnnxInferenceException(
      'Missing output tensor "$outputName" for model '
      '${modelSpec.key} (${modelSpec.assetPath}). '
      'Available outputs: ${outputs.keys.join(", ")}',
    );
  }

  int _resolveDetectionCount({
    required ModelSpec modelSpec,
    required List<double> numDetections,
    required List<double> boxes,
    required List<double> scores,
    required List<double> classes,
    required List<int> boxesShape,
    required List<int> scoresShape,
    required List<int> classesShape,
  }) {
    if (numDetections.isEmpty) {
      throw _unexpectedOutputException(
        modelSpec: modelSpec,
        outputShape: const <int>[],
        values: numDetections,
        reason: 'Detector returned empty num_detections output.',
      );
    }

    final requestedCount = numDetections.first.floor();
    if (requestedCount < 0) {
      throw _unexpectedOutputException(
        modelSpec: modelSpec,
        outputShape: const <int>[],
        values: numDetections,
        reason: 'Detector returned a negative num_detections value.',
      );
    }

    final availableBoxes = boxes.length ~/ 4;
    if (boxes.length % 4 != 0 ||
        scores.length < requestedCount ||
        classes.length < requestedCount ||
        availableBoxes < requestedCount) {
      final message = 'Unexpected detector output for model ${modelSpec.key} '
          '(${modelSpec.assetPath}). '
          'numDetections=$requestedCount '
          'boxesShape=${_describeShape(boxesShape)} '
          'scoresShape=${_describeShape(scoresShape)} '
          'classesShape=${_describeShape(classesShape)} '
          'boxes=${boxes.length} scores=${scores.length} classes=${classes.length}';
      AppLogger.error(
        message,
        scope: 'image_classification',
      );
      throw OnnxInferenceException(message);
    }

    return requestedCount;
  }

  List<double> _coerceOutputValues({
    required ModelSpec modelSpec,
    required List<dynamic> rawOutput,
    required List<int> outputShape,
  }) {
    if (rawOutput.isEmpty) {
      throw _unexpectedOutputException(
        modelSpec: modelSpec,
        outputShape: outputShape,
        values: const <double>[],
        reason: 'Output tensor is empty.',
      );
    }

    final values = <double>[];
    for (final value in rawOutput) {
      if (value is! num) {
        throw _unexpectedOutputException(
          modelSpec: modelSpec,
          outputShape: outputShape,
          values: values,
          reason:
              'Output tensor contains non-numeric value of type ${value.runtimeType}.',
        );
      }
      values.add(value.toDouble());
    }
    return values;
  }

  bool _looksLikeProbabilityVector(List<double> values) {
    const epsilon = 0.001;
    final hasOnlyValidProbabilities = values.every(
      (value) => value >= 0 && value <= 1,
    );
    if (!hasOnlyValidProbabilities) {
      return false;
    }

    final sum = values.fold<double>(0, (total, value) => total + value);
    return (sum - 1).abs() <= epsilon;
  }

  List<double> _softmax(List<double> values) {
    final maxValue = values.reduce(math.max);
    final exponents = values
        .map((value) => math.exp(value - maxValue))
        .toList(growable: false);
    final denominator = exponents.fold<double>(
      0,
      (total, value) => total + value,
    );
    return exponents
        .map((value) => value / denominator)
        .toList(growable: false);
  }

  OnnxInferenceException _unexpectedOutputException({
    required ModelSpec modelSpec,
    required List<int> outputShape,
    required List<double> values,
    required String reason,
  }) {
    final message = 'Unexpected output for model ${modelSpec.key} '
        '(${modelSpec.assetPath}), output "${modelSpec.outputName ?? modelSpec.detectionScoresOutputName}". '
        'Reason: $reason '
        'Shape=${_describeShape(outputShape)} '
        'ValueCount=${values.length} '
        'Values=${_previewValues(values)}';
    AppLogger.error(
      message,
      scope: 'image_classification',
    );
    return OnnxInferenceException(message);
  }

  String _describeShape(List<int> outputShape) {
    if (outputShape.isEmpty) {
      return '[]';
    }
    return '[${outputShape.join(", ")}]';
  }

  String _previewValues(List<double> values) {
    final preview = values.take(6).map(
          (value) => value.toStringAsFixed(4),
        );
    return '[${preview.join(", ")}${values.length > 6 ? ', ...' : ''}]';
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw const OnnxInferenceException(
        'ONNX inference backend has already been disposed.',
      );
    }
  }
}

class OnnxInferenceException implements Exception {
  const OnnxInferenceException(this.message);

  final String message;

  @override
  String toString() => 'OnnxInferenceException: $message';
}
