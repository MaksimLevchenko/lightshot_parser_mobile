class ModelThresholds {
  const ModelThresholds({
    required this.nsfwThreshold,
    this.peopleThreshold = 0.5,
    required this.documentThreshold,
  });

  const ModelThresholds.defaults()
      : nsfwThreshold = 0.85,
        peopleThreshold = 0.5,
        documentThreshold = 0.8;

  final double nsfwThreshold;
  final double peopleThreshold;
  final double documentThreshold;
}
