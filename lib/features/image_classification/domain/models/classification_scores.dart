import 'package:equatable/equatable.dart';

import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';

class ClassificationScores extends Equatable {
  const ClassificationScores({
    required this.nsfw,
    this.people = 0,
    required this.documents,
  });

  const ClassificationScores.zero()
      : nsfw = 0,
        people = 0,
        documents = 0;

  final double nsfw;
  final double people;
  final double documents;

  double get maxScore {
    final values = <double>[nsfw, people, documents]..sort();
    return values.last;
  }

  double scoreFor(ClassificationCategory category) {
    return switch (category) {
      ClassificationCategory.nsfw => nsfw,
      ClassificationCategory.people => people,
      ClassificationCategory.documents => documents,
      ClassificationCategory.notClassified => 0,
      ClassificationCategory.unrecognized => maxScore,
    };
  }

  Map<String, double> toJson() {
    return <String, double>{
      'nsfw': nsfw,
      'people': people,
      'documents': documents,
    };
  }

  factory ClassificationScores.fromJson(Map<String, dynamic> json) {
    return ClassificationScores(
      nsfw: _asDouble(json['nsfw']),
      people: _asDouble(json['people']),
      documents: _asDouble(json['documents']),
    );
  }

  ClassificationScores copyWith({
    double? nsfw,
    double? people,
    double? documents,
  }) {
    return ClassificationScores(
      nsfw: nsfw ?? this.nsfw,
      people: people ?? this.people,
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
  List<Object?> get props => <Object?>[nsfw, people, documents];
}
