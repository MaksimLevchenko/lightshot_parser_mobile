class ModelThresholds {
  const ModelThresholds({
    required this.nsfwThreshold,
    required this.documentThreshold,
    required this.gameThreshold,
  });

  const ModelThresholds.defaults()
      : nsfwThreshold = 0.8,
        documentThreshold = 0.8,
        gameThreshold = 0.8;

  final double nsfwThreshold;
  final double documentThreshold;
  final double gameThreshold;
}
