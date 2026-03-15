import 'package:lightshot_parser_mobile/features/image_classification/data/models/model_spec.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/preprocessed_image_data.dart';

abstract class InferenceBackend {
  String get backendId;

  Future<void> initialize();

  Future<double> runModel({
    required ModelSpec modelSpec,
    required PreprocessedImageData input,
  });

  Future<void> dispose();
}
