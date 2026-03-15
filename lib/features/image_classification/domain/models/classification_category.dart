enum ClassificationCategory {
  nsfw,
  documents,
  games,
  unrecognized;

  static ClassificationCategory fromStorage(String? value) {
    return ClassificationCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => ClassificationCategory.unrecognized,
    );
  }
}
