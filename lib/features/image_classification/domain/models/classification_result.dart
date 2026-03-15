import 'package:equatable/equatable.dart';

import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_scores.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_status.dart';

class ClassificationResult extends Equatable {
  const ClassificationResult({
    required this.status,
    required this.category,
    required this.confidence,
    required this.rawScores,
    required this.backend,
    required this.classifiedAt,
  });

  final ClassificationStatus status;
  final ClassificationCategory category;
  final double confidence;
  final ClassificationScores rawScores;
  final String backend;
  final DateTime? classifiedAt;

  bool get isPending => status == ClassificationStatus.pending;

  factory ClassificationResult.pending({
    required String backend,
  }) {
    return ClassificationResult(
      status: ClassificationStatus.pending,
      category: ClassificationCategory.unrecognized,
      confidence: 0,
      rawScores: const ClassificationScores.zero(),
      backend: backend,
      classifiedAt: null,
    );
  }

  factory ClassificationResult.completed({
    required ClassificationCategory category,
    required double confidence,
    required ClassificationScores rawScores,
    required String backend,
    required DateTime classifiedAt,
  }) {
    return ClassificationResult(
      status: ClassificationStatus.completed,
      category: category,
      confidence: confidence,
      rawScores: rawScores,
      backend: backend,
      classifiedAt: classifiedAt,
    );
  }

  factory ClassificationResult.unrecognized({
    required String backend,
    ClassificationScores rawScores = const ClassificationScores.zero(),
    DateTime? classifiedAt,
  }) {
    final resolvedClassifiedAt = classifiedAt ?? DateTime.now();
    return ClassificationResult.completed(
      category: ClassificationCategory.unrecognized,
      confidence: rawScores.maxScore,
      rawScores: rawScores,
      backend: backend,
      classifiedAt: resolvedClassifiedAt,
    );
  }

  factory ClassificationResult.legacy() {
    return ClassificationResult.unrecognized(
      backend: 'legacy',
      classifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  ClassificationResult copyWith({
    ClassificationStatus? status,
    ClassificationCategory? category,
    double? confidence,
    ClassificationScores? rawScores,
    String? backend,
    DateTime? classifiedAt,
  }) {
    return ClassificationResult(
      status: status ?? this.status,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      rawScores: rawScores ?? this.rawScores,
      backend: backend ?? this.backend,
      classifiedAt: classifiedAt ?? this.classifiedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        category,
        confidence,
        rawScores,
        backend,
        classifiedAt,
      ];
}
