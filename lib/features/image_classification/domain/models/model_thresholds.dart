class ModelThresholds {
  const ModelThresholds({
    required this.nsfwThreshold,
    required this.documentThreshold,
  });

  const ModelThresholds.defaults()
      : nsfwThreshold = 0.85,
        documentThreshold = 0.8;

  final double nsfwThreshold;
  final double documentThreshold;
}
