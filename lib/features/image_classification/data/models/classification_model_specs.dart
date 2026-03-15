import 'package:lightshot_parser_mobile/features/image_classification/data/models/model_spec.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';

const ModelSpec nsfwClassificationModelSpec = ModelSpec(
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

const ModelSpec documentsClassificationModelSpec = ModelSpec(
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

const ModelSpec peopleClassificationModelSpec = ModelSpec(
  key: 'people',
  category: ClassificationCategory.people,
  assetPath: 'assets/ml/models/people_qdq.onnx',
  inputName: 'inputs',
  taskType: ModelTaskType.personDetector,
  numDetectionsOutputName: 'num_detections',
  detectionBoxesOutputName: 'detection_boxes',
  detectionScoresOutputName: 'detection_scores',
  detectionClassesOutputName: 'detection_classes',
);

const List<ModelSpec> cascadeClassificationModelSpecs = <ModelSpec>[
  nsfwClassificationModelSpec,
  documentsClassificationModelSpec,
  peopleClassificationModelSpec,
];
