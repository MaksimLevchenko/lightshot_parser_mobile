import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

class PhotoViewerState extends Equatable {
  const PhotoViewerState({
    required this.items,
    required this.currentIndex,
    required this.isBusy,
    this.message,
    this.errorMessage,
  });

  const PhotoViewerState.initial({
    required this.items,
    required this.currentIndex,
  })  : isBusy = false,
        message = null,
        errorMessage = null;

  final List<GalleryItem> items;
  final int currentIndex;
  final bool isBusy;
  final String? message;
  final String? errorMessage;

  GalleryItem? get currentItem {
    if (items.isEmpty) {
      return null;
    }
    return items[currentIndex];
  }

  PhotoViewerState copyWith({
    List<GalleryItem>? items,
    int? currentIndex,
    bool? isBusy,
    String? message,
    String? errorMessage,
    bool clearFeedback = false,
  }) {
    return PhotoViewerState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      isBusy: isBusy ?? this.isBusy,
      message: clearFeedback ? null : message ?? this.message,
      errorMessage: clearFeedback ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        currentIndex,
        isBusy,
        message,
        errorMessage,
      ];
}
