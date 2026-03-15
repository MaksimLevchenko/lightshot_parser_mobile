import 'package:equatable/equatable.dart';

import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';

enum ModelTaskType {
  binaryClassifier,
  personDetector,
}

class ModelSpec extends Equatable {
  const ModelSpec({
    required this.key,
    required this.category,
    required this.assetPath,
    required this.inputName,
    this.taskType = ModelTaskType.binaryClassifier,
    this.outputName,
    this.inputWidth,
    this.inputHeight,
    this.numDetectionsOutputName,
    this.detectionBoxesOutputName,
    this.detectionScoresOutputName,
    this.detectionClassesOutputName,
    this.normalizationMean = const <double>[0, 0, 0],
    this.normalizationStd = const <double>[1, 1, 1],
  }) : assert(
          taskType == ModelTaskType.binaryClassifier
              ? outputName != null && inputWidth != null && inputHeight != null
              : numDetectionsOutputName != null &&
                  detectionBoxesOutputName != null &&
                  detectionScoresOutputName != null &&
                  detectionClassesOutputName != null,
          'ModelSpec is missing required configuration for the selected task type.',
        );

  final String key;
  final ClassificationCategory category;
  final String assetPath;
  final String inputName;
  final ModelTaskType taskType;
  final String? outputName;
  final int? inputWidth;
  final int? inputHeight;
  final String? numDetectionsOutputName;
  final String? detectionBoxesOutputName;
  final String? detectionScoresOutputName;
  final String? detectionClassesOutputName;
  final List<double> normalizationMean;
  final List<double> normalizationStd;

  bool get usesFixedInputSize => taskType == ModelTaskType.binaryClassifier;

  @override
  List<Object?> get props => <Object?>[
        key,
        category,
        assetPath,
        inputName,
        taskType,
        outputName,
        inputWidth,
        inputHeight,
        numDetectionsOutputName,
        detectionBoxesOutputName,
        detectionScoresOutputName,
        detectionClassesOutputName,
        normalizationMean,
        normalizationStd,
      ];
}
