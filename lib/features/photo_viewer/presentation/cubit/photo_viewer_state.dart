import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

enum PhotoViewerFeedback {
  deleted,
  saved,
}

class PhotoViewerState extends Equatable {
  const PhotoViewerState({
    required this.items,
    required this.currentIndex,
    required this.isBusy,
    this.feedback,
    this.savedPath,
    this.errorMessage,
  });

  const PhotoViewerState.initial({
    required this.items,
    required this.currentIndex,
  })  : isBusy = false,
        feedback = null,
        savedPath = null,
        errorMessage = null;

  final List<GalleryItem> items;
  final int currentIndex;
  final bool isBusy;
  final PhotoViewerFeedback? feedback;
  final String? savedPath;
  final String? errorMessage;

  GalleryItem? get currentItem {
    if (items.isEmpty || currentIndex < 0 || currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex];
  }

  PhotoViewerState copyWith({
    List<GalleryItem>? items,
    int? currentIndex,
    bool? isBusy,
    PhotoViewerFeedback? feedback,
    String? savedPath,
    String? errorMessage,
    bool clearFeedback = false,
  }) {
    return PhotoViewerState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      isBusy: isBusy ?? this.isBusy,
      feedback: clearFeedback ? null : feedback ?? this.feedback,
      savedPath: clearFeedback ? null : savedPath ?? this.savedPath,
      errorMessage: clearFeedback ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        currentIndex,
        isBusy,
        feedback,
        savedPath,
        errorMessage,
      ];
}
