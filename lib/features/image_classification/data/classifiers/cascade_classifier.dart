import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_result.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_scores.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/model_thresholds.dart';

class CascadeClassifier {
  const CascadeClassifier();

  ClassificationResult classify({
    required ClassificationScores scores,
    required ModelThresholds thresholds,
    required String backend,
    DateTime? classifiedAt,
  }) {
    final resolvedClassifiedAt = classifiedAt ?? DateTime.now();
    if (scores.nsfw >= thresholds.nsfwThreshold) {
      return ClassificationResult.completed(
        category: ClassificationCategory.nsfw,
        confidence: scores.nsfw,
        rawScores: scores,
        backend: backend,
        classifiedAt: resolvedClassifiedAt,
      );
    }
    if (scores.documents >= thresholds.documentThreshold) {
      return ClassificationResult.completed(
        category: ClassificationCategory.documents,
        confidence: scores.documents,
        rawScores: scores,
        backend: backend,
        classifiedAt: resolvedClassifiedAt,
      );
    }
    if (scores.people >= thresholds.peopleThreshold) {
      return ClassificationResult.completed(
        category: ClassificationCategory.people,
        confidence: scores.people,
        rawScores: scores,
        backend: backend,
        classifiedAt: resolvedClassifiedAt,
      );
    }

    return ClassificationResult.completed(
      category: ClassificationCategory.unrecognized,
      confidence: scores.maxScore,
      rawScores: scores,
      backend: backend,
      classifiedAt: resolvedClassifiedAt,
    );
  }
}
