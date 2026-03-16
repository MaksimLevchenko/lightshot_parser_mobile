import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:lightshot_parser_mobile/core/logging/app_logger.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/backends/inference_backend.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/backends/onnx_inference_backend.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/classification_model_specs.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/model_spec.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/preprocessing/image_preprocessor.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_scores.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/model_thresholds.dart';

class ClassificationExecutionResult {
  const ClassificationExecutionResult({
    required this.scores,
    required this.backendId,
    required this.executionPath,
    this.fallbackReason,
  });

  final ClassificationScores scores;
  final String backendId;
  final String executionPath;
  final String? fallbackReason;
}

abstract class ClassificationExecutionBackend {
  String get backendId;

  Future<void> initialize();

  Future<void> warmUp();

  Future<ClassificationExecutionResult> executeClassification({
    required String imagePath,
  });

  Future<void> dispose();
}

class LocalClassificationExecutionBackend
    implements ClassificationExecutionBackend {
  LocalClassificationExecutionBackend({
    required ImagePreprocessor imagePreprocessor,
    required InferenceBackend inferenceBackend,
    ModelThresholds modelThresholds = const ModelThresholds.defaults(),
  })  : _imagePreprocessor = imagePreprocessor,
        _inferenceBackend = inferenceBackend,
        _modelThresholds = modelThresholds;

  final ImagePreprocessor _imagePreprocessor;
  final InferenceBackend _inferenceBackend;
  final ModelThresholds _modelThresholds;

  @override
  String get backendId => _inferenceBackend.backendId;

  @override
  Future<void> initialize() {
    return _inferenceBackend.initialize();
  }

  @override
  Future<void> warmUp() async {
    await _inferenceBackend.initialize();
    await _inferenceBackend.preloadModels(cascadeClassificationModelSpecs);
  }

  @override
  Future<ClassificationExecutionResult> executeClassification({
    required String imagePath,
  }) async {
    await _inferenceBackend.initialize();
    final scores = await runCascadeClassification(
      imagePath: imagePath,
      imagePreprocessor: _imagePreprocessor,
      inferenceBackend: _inferenceBackend,
      modelThresholds: _modelThresholds,
    );
    return ClassificationExecutionResult(
      scores: scores,
      backendId: _inferenceBackend.backendId,
      executionPath: 'main_isolate',
    );
  }

  @override
  Future<void> dispose() {
    return _inferenceBackend.dispose();
  }
}

class IsolateClassificationExecutionBackend
    implements ClassificationExecutionBackend {
  IsolateClassificationExecutionBackend({
    required LocalClassificationExecutionBackend fallbackBackend,
    required ModelThresholds modelThresholds,
    required RootIsolateToken rootIsolateToken,
    ClassificationWorkerClient? workerClient,
  })  : _fallbackBackend = fallbackBackend,
        _modelThresholds = modelThresholds,
        _rootIsolateToken = rootIsolateToken,
        _workerClient = workerClient;

  final LocalClassificationExecutionBackend _fallbackBackend;
  final ModelThresholds _modelThresholds;
  final RootIsolateToken _rootIsolateToken;
  final ClassificationWorkerClient? _workerClient;

  ClassificationWorkerClient? _activeWorkerClient;
  String? _fallbackReason;
  bool _workerDisabled = false;

  @override
  String get backendId =>
      _workerDisabled ? _fallbackBackend.backendId : 'onnx_runtime_worker';

  @override
  Future<void> initialize() async {
    await _fallbackBackend.initialize();
    await _ensureWorkerInitialized();
  }

  @override
  Future<void> warmUp() async {
    final workerClient = await _ensureWorkerInitialized();
    if (workerClient == null) {
      await _fallbackBackend.warmUp();
      return;
    }
  }

  @override
  Future<ClassificationExecutionResult> executeClassification({
    required String imagePath,
  }) async {
    await _fallbackBackend.initialize();
    final workerClient = await _ensureWorkerInitialized();
    if (workerClient == null) {
      return _executeWithFallback(imagePath: imagePath);
    }

    try {
      final workerResult =
          await workerClient.classifyFile(imagePath: imagePath);
      return ClassificationExecutionResult(
        scores: workerResult.scores!,
        backendId: workerResult.backendId,
        executionPath: 'worker_isolate',
      );
    } on Object catch (error, stackTrace) {
      final reason =
          'Worker classification failed: ${error.runtimeType}: $error';
      AppLogger.warning(
        'Worker isolate classification failed. Falling back to main isolate.',
        scope: 'image_classification',
        error: error,
        stackTrace: stackTrace,
      );
      _fallbackReason = reason;
      await _disableWorker();
      return _executeWithFallback(imagePath: imagePath);
    }
  }

  @override
  Future<void> dispose() async {
    await _disableWorker();
    await _fallbackBackend.dispose();
  }

  Future<ClassificationExecutionResult> _executeWithFallback({
    required String imagePath,
  }) async {
    final result =
        await _fallbackBackend.executeClassification(imagePath: imagePath);
    return ClassificationExecutionResult(
      scores: result.scores,
      backendId: result.backendId,
      executionPath: 'main_isolate_fallback',
      fallbackReason: _fallbackReason,
    );
  }

  Future<ClassificationWorkerClient?> _ensureWorkerInitialized() async {
    if (_workerDisabled) {
      return null;
    }
    final existingClient = _activeWorkerClient;
    if (existingClient != null) {
      return existingClient;
    }

    final workerClient = _workerClient ??
        NativeClassificationWorkerClient(
          _rootIsolateToken,
          modelThresholds: _modelThresholds,
        );
    try {
      await workerClient.initialize();
      _activeWorkerClient = workerClient;
      _fallbackReason = null;
      AppLogger.info(
        'Initialized worker isolate classification backend.',
        scope: 'image_classification',
      );
      return workerClient;
    } on Object catch (error, stackTrace) {
      _fallbackReason =
          'Worker initialization failed: ${error.runtimeType}: $error';
      AppLogger.warning(
        'Worker isolate classification backend is unavailable. '
        'Main isolate fallback will be used.',
        scope: 'image_classification',
        error: error,
        stackTrace: stackTrace,
      );
      _workerDisabled = true;
      try {
        await workerClient.dispose();
      } on Object {
        // Ignore cleanup failures after initialization errors.
      }
      return null;
    }
  }

  Future<void> _disableWorker() async {
    _workerDisabled = true;
    final activeWorkerClient = _activeWorkerClient;
    _activeWorkerClient = null;
    if (activeWorkerClient != null) {
      await activeWorkerClient.dispose();
    }
  }
}

abstract class ClassificationWorkerClient {
  Future<void> initialize();

  Future<ClassificationWorkerSuccessResponse> classifyFile({
    required String imagePath,
  });

  Future<void> dispose();
}

class NativeClassificationWorkerClient implements ClassificationWorkerClient {
  NativeClassificationWorkerClient(
    this._rootIsolateToken, {
    required ModelThresholds modelThresholds,
  }) : _modelThresholds = modelThresholds;

  final RootIsolateToken _rootIsolateToken;
  final ModelThresholds _modelThresholds;

  Isolate? _isolate;
  SendPort? _workerSendPort;

  @override
  Future<void> initialize() async {
    if (_workerSendPort != null) {
      return;
    }

    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    _isolate = await Isolate.spawn<_WorkerBootstrapMessage>(
      _classificationWorkerMain,
      _WorkerBootstrapMessage(
        mainSendPort: receivePort.sendPort,
      ),
      onExit: exitPort.sendPort,
      errorsAreFatal: false,
    );

    final handshake = await receivePort.first;
    receivePort.close();
    if (handshake is! SendPort) {
      throw StateError('Worker isolate did not provide a SendPort.');
    }

    _workerSendPort = handshake;
    errorPort.listen((dynamic error) {
      AppLogger.warning(
        'Worker isolate emitted an uncaught error: $error',
        scope: 'image_classification',
      );
    });
    exitPort.listen((Object? _) {
      _workerSendPort = null;
      _isolate = null;
    });

    final modelPathsByAssetPath = await _materializeModelAssets();
    final response = await _sendRequest(
      ClassificationWorkerInitializeRequest(
        rootIsolateToken: _rootIsolateToken,
        modelPathsByAssetPath: modelPathsByAssetPath,
        modelThresholds: _modelThresholds,
      ),
    );
    response.throwIfFailure();
  }

  @override
  Future<ClassificationWorkerSuccessResponse> classifyFile({
    required String imagePath,
  }) async {
    if (_workerSendPort == null) {
      throw StateError('Worker isolate is not initialized.');
    }

    final response = await _sendRequest(
      ClassificationWorkerRunRequest(imagePath: imagePath),
    );
    response.throwIfFailure();
    return response as ClassificationWorkerSuccessResponse;
  }

  @override
  Future<void> dispose() async {
    final workerSendPort = _workerSendPort;
    _workerSendPort = null;
    if (workerSendPort != null) {
      final receivePort = ReceivePort();
      workerSendPort.send(<String, Object?>{
        'type': 'dispose',
        'replyPort': receivePort.sendPort,
      });
      await receivePort.first.timeout(const Duration(seconds: 2));
      receivePort.close();
    }

    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  Future<ClassificationWorkerResponse> _sendRequest(
    ClassificationWorkerRequest request,
  ) async {
    final workerSendPort = _workerSendPort;
    if (workerSendPort == null) {
      throw StateError('Worker isolate is not initialized.');
    }

    final receivePort = ReceivePort();
    final message = request.toMessage(replyPort: receivePort.sendPort);
    workerSendPort.send(message);
    final responseMessage = await receivePort.first;
    receivePort.close();
    if (responseMessage is! Map<Object?, Object?>) {
      throw StateError('Worker isolate returned an unexpected response.');
    }
    return ClassificationWorkerResponse.fromMessage(responseMessage);
  }

  Future<Map<String, String>> _materializeModelAssets() async {
    final temporaryDirectory = await getTemporaryDirectory();
    final modelsDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}classification_models',
    );
    if (!await modelsDirectory.exists()) {
      await modelsDirectory.create(recursive: true);
    }

    final modelPathsByAssetPath = <String, String>{};
    for (final modelSpec in cascadeClassificationModelSpecs) {
      final fileName =
          '${modelSpec.key}_${modelSpec.assetPath.split('/').last}';
      final filePath =
          '${modelsDirectory.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      if (!await file.exists()) {
        final data = await rootBundle.load(modelSpec.assetPath);
        await file.writeAsBytes(
          data.buffer.asUint8List(),
          flush: true,
        );
      }
      modelPathsByAssetPath[modelSpec.assetPath] = filePath;
    }
    return modelPathsByAssetPath;
  }
}

sealed class ClassificationWorkerRequest {
  const ClassificationWorkerRequest();

  Map<String, Object?> toMessage({
    required SendPort replyPort,
  });
}

class ClassificationWorkerInitializeRequest
    extends ClassificationWorkerRequest {
  const ClassificationWorkerInitializeRequest({
    required this.rootIsolateToken,
    required this.modelPathsByAssetPath,
    required this.modelThresholds,
  });

  final RootIsolateToken rootIsolateToken;
  final Map<String, String> modelPathsByAssetPath;
  final ModelThresholds modelThresholds;

  @override
  Map<String, Object?> toMessage({
    required SendPort replyPort,
  }) {
    return <String, Object?>{
      'type': 'initialize',
      'rootIsolateToken': rootIsolateToken,
      'modelPathsByAssetPath': modelPathsByAssetPath,
      'modelThresholds': <String, double>{
        'nsfwThreshold': modelThresholds.nsfwThreshold,
        'documentThreshold': modelThresholds.documentThreshold,
      },
      'replyPort': replyPort,
    };
  }
}

class ClassificationWorkerRunRequest extends ClassificationWorkerRequest {
  const ClassificationWorkerRunRequest({
    required this.imagePath,
  });

  final String imagePath;

  @override
  Map<String, Object?> toMessage({
    required SendPort replyPort,
  }) {
    return <String, Object?>{
      'type': 'run',
      'imagePath': imagePath,
      'replyPort': replyPort,
    };
  }
}

sealed class ClassificationWorkerResponse {
  const ClassificationWorkerResponse();

  factory ClassificationWorkerResponse.fromMessage(
    Map<Object?, Object?> message,
  ) {
    final type = message['type'];
    if (type == 'success') {
      return ClassificationWorkerSuccessResponse.fromMessage(message);
    }
    if (type == 'failure') {
      return ClassificationWorkerFailureResponse.fromMessage(message);
    }
    throw StateError('Unknown worker response type: $type');
  }

  void throwIfFailure() {}
}

class ClassificationWorkerSuccessResponse extends ClassificationWorkerResponse {
  const ClassificationWorkerSuccessResponse({
    required this.backendId,
    this.scores,
  });

  factory ClassificationWorkerSuccessResponse.fromMessage(
    Map<Object?, Object?> message,
  ) {
    final scoresMap = message['scores'];
    final typedScoresMap =
        scoresMap == null ? null : Map<Object?, Object?>.from(scoresMap as Map);
    return ClassificationWorkerSuccessResponse(
      backendId: message['backendId']! as String,
      scores: typedScoresMap == null
          ? null
          : ClassificationScores(
              nsfw: typedScoresMap['nsfw']! as double,
              people: typedScoresMap['people']! as double,
              documents: typedScoresMap['documents']! as double,
            ),
    );
  }

  final String backendId;
  final ClassificationScores? scores;

  Map<String, Object?> toMessage() {
    return <String, Object?>{
      'type': 'success',
      'backendId': backendId,
      if (scores != null)
        'scores': <String, double>{
          'nsfw': scores!.nsfw,
          'people': scores!.people,
          'documents': scores!.documents,
        },
    };
  }

  @override
  void throwIfFailure() {
    if (scores == null) {
      return;
    }
  }
}

class ClassificationWorkerFailureResponse extends ClassificationWorkerResponse {
  const ClassificationWorkerFailureResponse({
    required this.message,
  });

  factory ClassificationWorkerFailureResponse.fromMessage(
    Map<Object?, Object?> message,
  ) {
    return ClassificationWorkerFailureResponse(
      message: message['message']! as String,
    );
  }

  final String message;

  Map<String, Object?> toMessage() {
    return <String, Object?>{
      'type': 'failure',
      'message': message,
    };
  }

  @override
  void throwIfFailure() {
    throw StateError(message);
  }
}

class _WorkerBootstrapMessage {
  const _WorkerBootstrapMessage({
    required this.mainSendPort,
  });

  final SendPort mainSendPort;
}

Future<void> _classificationWorkerMain(
  _WorkerBootstrapMessage bootstrapMessage,
) async {
  final receivePort = ReceivePort();
  bootstrapMessage.mainSendPort.send(receivePort.sendPort);

  ImagePreprocessor? imagePreprocessor;
  OnnxInferenceBackend? inferenceBackend;
  var modelThresholds = const ModelThresholds.defaults();

  await for (final message in receivePort) {
    if (message is! Map<Object?, Object?>) {
      continue;
    }
    final replyPort = message['replyPort'];
    if (replyPort is! SendPort) {
      continue;
    }

    try {
      switch (message['type']) {
        case 'initialize':
          final rootIsolateToken =
              message['rootIsolateToken'] as RootIsolateToken;
          BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
          imagePreprocessor = ImagePreprocessor();
          inferenceBackend = OnnxInferenceBackend(
            modelPathOverridesByAssetPath: Map<String, String>.from(
              message['modelPathsByAssetPath']! as Map,
            ),
          );
          final thresholdValues = Map<Object?, Object?>.from(
            message['modelThresholds']! as Map,
          );
          modelThresholds = ModelThresholds(
            nsfwThreshold: thresholdValues['nsfwThreshold']! as double,
            documentThreshold: thresholdValues['documentThreshold']! as double,
          );
          await inferenceBackend.initialize();
          await inferenceBackend.preloadModels(cascadeClassificationModelSpecs);
          replyPort.send(
            const ClassificationWorkerSuccessResponse(
              backendId: 'onnx_runtime_worker',
            ).toMessage(),
          );
          break;
        case 'run':
          if (imagePreprocessor == null || inferenceBackend == null) {
            throw StateError('Worker isolate has not been initialized yet.');
          }
          final scores = await runCascadeClassification(
            imagePath: message['imagePath']! as String,
            imagePreprocessor: imagePreprocessor,
            inferenceBackend: inferenceBackend,
            modelThresholds: modelThresholds,
          );
          replyPort.send(
            ClassificationWorkerSuccessResponse(
              backendId: 'onnx_runtime_worker',
              scores: scores,
            ).toMessage(),
          );
          break;
        case 'dispose':
          if (inferenceBackend != null) {
            await inferenceBackend.dispose();
          }
          replyPort.send(
            const ClassificationWorkerSuccessResponse(
              backendId: 'onnx_runtime_worker',
            ).toMessage(),
          );
          receivePort.close();
          return;
        default:
          throw StateError('Unknown worker message type: ${message['type']}');
      }
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Worker isolate request failed.',
        scope: 'image_classification',
        error: error,
        stackTrace: stackTrace,
      );
      replyPort.send(
        ClassificationWorkerFailureResponse(
          message: '$error',
        ).toMessage(),
      );
    }
  }
}

Future<ClassificationScores> runCascadeClassification({
  required String imagePath,
  required ImagePreprocessor imagePreprocessor,
  required InferenceBackend inferenceBackend,
  required ModelThresholds modelThresholds,
}) async {
  final decodedImage = await imagePreprocessor.decodeFile(imagePath: imagePath);

  final nsfwScore = await _runModel(
    decodedImage: decodedImage,
    imagePreprocessor: imagePreprocessor,
    inferenceBackend: inferenceBackend,
    modelSpec: nsfwClassificationModelSpec,
  );
  if (nsfwScore >= modelThresholds.nsfwThreshold) {
    return ClassificationScores(
      nsfw: nsfwScore,
      people: 0,
      documents: 0,
    );
  }

  final documentsScore = await _runModel(
    decodedImage: decodedImage,
    imagePreprocessor: imagePreprocessor,
    inferenceBackend: inferenceBackend,
    modelSpec: documentsClassificationModelSpec,
  );
  if (documentsScore >= modelThresholds.documentThreshold) {
    return ClassificationScores(
      nsfw: nsfwScore,
      people: 0,
      documents: documentsScore,
    );
  }

  final peopleScore = await _runModel(
    decodedImage: decodedImage,
    imagePreprocessor: imagePreprocessor,
    inferenceBackend: inferenceBackend,
    modelSpec: peopleClassificationModelSpec,
  );
  return ClassificationScores(
    nsfw: nsfwScore,
    people: peopleScore,
    documents: documentsScore,
  );
}

Future<double> _runModel({
  required DecodedImageData decodedImage,
  required ImagePreprocessor imagePreprocessor,
  required InferenceBackend inferenceBackend,
  required ModelSpec modelSpec,
}) async {
  final preprocessedImage = imagePreprocessor.preprocessDecodedImage(
    decodedImage: decodedImage,
    modelSpec: modelSpec,
  );
  return inferenceBackend.runModel(
    modelSpec: modelSpec,
    input: preprocessedImage,
  );
}
