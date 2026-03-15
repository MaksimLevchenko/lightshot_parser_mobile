enum ClassificationStatus {
  pending,
  completed,
  failed;

  static ClassificationStatus fromStorage(String? value) {
    return ClassificationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ClassificationStatus.completed,
    );
  }
}
