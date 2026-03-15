import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';

void main() {
  const classifier = CascadeClassifier();
  const thresholds = ModelThresholds(
    nsfwThreshold: 0.8,
    documentThreshold: 0.8,
    gameThreshold: 0.8,
  );

  test('nsfw score wins first cascade step', () {
    final result = classifier.classify(
      scores: const ClassificationScores(
        nsfw: 0.91,
        documents: 0.99,
        games: 0.99,
      ),
      thresholds: thresholds,
      backend: 'test',
      classifiedAt: DateTime(2026, 3, 15),
    );

    expect(result.category, ClassificationCategory.nsfw);
    expect(result.confidence, 0.91);
  });

  test('documents score wins when nsfw is below threshold', () {
    final result = classifier.classify(
      scores: const ClassificationScores(
        nsfw: 0.79,
        documents: 0.87,
        games: 0.99,
      ),
      thresholds: thresholds,
      backend: 'test',
      classifiedAt: DateTime(2026, 3, 15),
    );

    expect(result.category, ClassificationCategory.documents);
    expect(result.confidence, 0.87);
  });

  test('games score wins when previous stages are below threshold', () {
    final result = classifier.classify(
      scores: const ClassificationScores(
        nsfw: 0.4,
        documents: 0.7,
        games: 0.88,
      ),
      thresholds: thresholds,
      backend: 'test',
      classifiedAt: DateTime(2026, 3, 15),
    );

    expect(result.category, ClassificationCategory.games);
    expect(result.confidence, 0.88);
  });

  test('unrecognized is returned when no thresholds pass', () {
    final result = classifier.classify(
      scores: const ClassificationScores(
        nsfw: 0.4,
        documents: 0.5,
        games: 0.6,
      ),
      thresholds: thresholds,
      backend: 'test',
      classifiedAt: DateTime(2026, 3, 15),
    );

    expect(result.category, ClassificationCategory.unrecognized);
    expect(result.confidence, 0.6);
  });
}
