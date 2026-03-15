import 'package:equatable/equatable.dart';

import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';

class ClassificationScores extends Equatable {
  const ClassificationScores({
    required this.nsfw,
    required this.documents,
    required this.games,
  });

  const ClassificationScores.zero()
      : nsfw = 0,
        documents = 0,
        games = 0;

  final double nsfw;
  final double documents;
  final double games;

  double get maxScore {
    final values = <double>[nsfw, documents, games]..sort();
    return values.last;
  }

  double scoreFor(ClassificationCategory category) {
    return switch (category) {
      ClassificationCategory.nsfw => nsfw,
      ClassificationCategory.documents => documents,
      ClassificationCategory.games => games,
      ClassificationCategory.unrecognized => maxScore,
    };
  }

  Map<String, double> toJson() {
    return <String, double>{
      'nsfw': nsfw,
      'documents': documents,
      'games': games,
    };
  }

  factory ClassificationScores.fromJson(Map<String, dynamic> json) {
    return ClassificationScores(
      nsfw: _asDouble(json['nsfw']),
      documents: _asDouble(json['documents']),
      games: _asDouble(json['games']),
    );
  }

  ClassificationScores copyWith({
    double? nsfw,
    double? documents,
    double? games,
  }) {
    return ClassificationScores(
      nsfw: nsfw ?? this.nsfw,
      documents: documents ?? this.documents,
      games: games ?? this.games,
    );
  }

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  @override
  List<Object?> get props => <Object?>[nsfw, documents, games];
}
