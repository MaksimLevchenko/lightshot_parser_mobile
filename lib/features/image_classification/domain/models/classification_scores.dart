import 'package:equatable/equatable.dart';

import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';

class ClassificationScores extends Equatable {
  const ClassificationScores({
    required this.nsfw,
    required this.documents,
  });

  const ClassificationScores.zero()
      : nsfw = 0,
        documents = 0;

  final double nsfw;
  final double documents;

  double get maxScore {
    final values = <double>[nsfw, documents]..sort();
    return values.last;
  }

  double scoreFor(ClassificationCategory category) {
    return switch (category) {
      ClassificationCategory.nsfw => nsfw,
      ClassificationCategory.documents => documents,
      ClassificationCategory.unrecognized => maxScore,
    };
  }

  Map<String, double> toJson() {
    return <String, double>{
      'nsfw': nsfw,
      'documents': documents,
    };
  }

  factory ClassificationScores.fromJson(Map<String, dynamic> json) {
    return ClassificationScores(
      nsfw: _asDouble(json['nsfw']),
      documents: _asDouble(json['documents']),
    );
  }

  ClassificationScores copyWith({
    double? nsfw,
    double? documents,
  }) {
    return ClassificationScores(
      nsfw: nsfw ?? this.nsfw,
      documents: documents ?? this.documents,
    );
  }

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  @override
  List<Object?> get props => <Object?>[nsfw, documents];
}
