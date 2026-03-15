import 'package:equatable/equatable.dart';

import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';

class ModelSpec extends Equatable {
  const ModelSpec({
    required this.key,
    required this.category,
    required this.assetPath,
    required this.inputName,
    required this.outputName,
    required this.inputWidth,
    required this.inputHeight,
  });

  final String key;
  final ClassificationCategory category;
  final String assetPath;
  final String inputName;
  final String outputName;
  final int inputWidth;
  final int inputHeight;

  @override
  List<Object?> get props => <Object?>[
        key,
        category,
        assetPath,
        inputName,
        outputName,
        inputWidth,
        inputHeight,
      ];
}
