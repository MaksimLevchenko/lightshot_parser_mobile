import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';

enum GalleryFeedback {
  reindexed,
  reclassified,
}

enum GalleryFilter {
  all,
  nsfw,
  people,
  documents,
  notClassified,
  unrecognized;

  bool matches(GalleryItem item) {
    return switch (this) {
      GalleryFilter.all => true,
      GalleryFilter.nsfw =>
        item.classificationResult.category == ClassificationCategory.nsfw,
      GalleryFilter.people =>
        item.classificationResult.category == ClassificationCategory.people,
      GalleryFilter.documents =>
        item.classificationResult.category == ClassificationCategory.documents,
      GalleryFilter.notClassified => item.classificationResult.category ==
          ClassificationCategory.notClassified,
      GalleryFilter.unrecognized => item.classificationResult.category ==
          ClassificationCategory.unrecognized,
    };
  }
}

class GalleryState extends Equatable {
  const GalleryState({
    required this.isLoading,
    required this.items,
    required this.selectedFilter,
    required this.isReclassifying,
    required this.reclassificationProcessedCount,
    required this.reclassificationTotalCount,
    this.feedback,
    this.errorMessage,
  });

  const GalleryState.initial()
      : isLoading = true,
        items = const <GalleryItem>[],
        selectedFilter = GalleryFilter.all,
        isReclassifying = false,
        reclassificationProcessedCount = 0,
        reclassificationTotalCount = 0,
        feedback = null,
        errorMessage = null;

  final bool isLoading;
  final List<GalleryItem> items;
  final GalleryFilter selectedFilter;
  final bool isReclassifying;
  final int reclassificationProcessedCount;
  final int reclassificationTotalCount;
  final GalleryFeedback? feedback;
  final String? errorMessage;

  List<GalleryItem> get visibleItems => items
      .where((GalleryItem item) => selectedFilter.matches(item))
      .toList(growable: false);

  GalleryState copyWith({
    bool? isLoading,
    List<GalleryItem>? items,
    GalleryFilter? selectedFilter,
    bool? isReclassifying,
    int? reclassificationProcessedCount,
    int? reclassificationTotalCount,
    GalleryFeedback? feedback,
    String? errorMessage,
    bool clearFeedback = false,
  }) {
    return GalleryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isReclassifying: isReclassifying ?? this.isReclassifying,
      reclassificationProcessedCount:
          reclassificationProcessedCount ?? this.reclassificationProcessedCount,
      reclassificationTotalCount:
          reclassificationTotalCount ?? this.reclassificationTotalCount,
      feedback: clearFeedback ? null : feedback ?? this.feedback,
      errorMessage: clearFeedback ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        items,
        selectedFilter,
        isReclassifying,
        reclassificationProcessedCount,
        reclassificationTotalCount,
        feedback,
        errorMessage,
      ];
}
