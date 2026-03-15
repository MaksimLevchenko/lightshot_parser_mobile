import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

class GalleryState extends Equatable {
  const GalleryState({
    required this.isLoading,
    required this.items,
    this.message,
    this.errorMessage,
  });

  const GalleryState.initial()
      : isLoading = true,
        items = const <GalleryItem>[],
        message = null,
        errorMessage = null;

  final bool isLoading;
  final List<GalleryItem> items;
  final String? message;
  final String? errorMessage;

  GalleryState copyWith({
    bool? isLoading,
    List<GalleryItem>? items,
    String? message,
    String? errorMessage,
    bool clearFeedback = false,
  }) {
    return GalleryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      message: clearFeedback ? null : message ?? this.message,
      errorMessage: clearFeedback ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, message, errorMessage];
}
