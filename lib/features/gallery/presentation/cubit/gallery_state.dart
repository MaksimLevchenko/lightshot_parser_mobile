import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

enum GalleryFeedback {
  reindexed,
}

class GalleryState extends Equatable {
  const GalleryState({
    required this.isLoading,
    required this.items,
    this.feedback,
    this.errorMessage,
  });

  const GalleryState.initial()
      : isLoading = true,
        items = const <GalleryItem>[],
        feedback = null,
        errorMessage = null;

  final bool isLoading;
  final List<GalleryItem> items;
  final GalleryFeedback? feedback;
  final String? errorMessage;

  GalleryState copyWith({
    bool? isLoading,
    List<GalleryItem>? items,
    GalleryFeedback? feedback,
    String? errorMessage,
    bool clearFeedback = false,
  }) {
    return GalleryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      feedback: clearFeedback ? null : feedback ?? this.feedback,
      errorMessage: clearFeedback ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, feedback, errorMessage];
}
