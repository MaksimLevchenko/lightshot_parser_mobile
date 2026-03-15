enum ClassificationCategory {
  nsfw,
  people,
  documents,
  notClassified,
  unrecognized;

  static ClassificationCategory fromStorage(String? value) {
    return ClassificationCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => ClassificationCategory.unrecognized,
    );
  }
}
