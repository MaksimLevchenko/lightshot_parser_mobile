import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/data/repositories/photo_actions_repository.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/presentation/cubit/photo_viewer_state.dart';

class PhotoViewerCubit extends Cubit<PhotoViewerState> {
  PhotoViewerCubit({
    required PhotoActionsRepository photoActionsRepository,
    required GalleryRepository galleryRepository,
    required List<GalleryItem> initialItems,
    required int initialIndex,
  })  : _photoActionsRepository = photoActionsRepository,
        _galleryRepository = galleryRepository,
        super(
          PhotoViewerState.initial(
            items: initialItems,
            currentIndex: initialIndex,
          ),
        );

  final PhotoActionsRepository _photoActionsRepository;
  final GalleryRepository _galleryRepository;

  void pageChanged(int index) {
    emit(state.copyWith(currentIndex: index, clearFeedback: true));
  }

  Future<void> shareCurrent(String shareText) async {
    final item = state.currentItem;
    if (item == null) {
      return;
    }
    emit(state.copyWith(isBusy: true, clearFeedback: true));
    try {
      await _photoActionsRepository.shareImage(item, shareText);
      emit(state.copyWith(isBusy: false, clearFeedback: true));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          isBusy: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> saveCurrent() async {
    final item = state.currentItem;
    if (item == null) {
      return;
    }
    emit(state.copyWith(isBusy: true, clearFeedback: true));
    try {
      final path = await _photoActionsRepository.saveImage(item);
      emit(
        state.copyWith(
          isBusy: false,
          feedback: PhotoViewerFeedback.saved,
          savedPath: path,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          isBusy: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> deleteCurrent() async {
    final item = state.currentItem;
    if (item == null) {
      return;
    }
    emit(state.copyWith(isBusy: true, clearFeedback: true));
    try {
      await _photoActionsRepository.deleteImage(item);
      final items = await _galleryRepository.load();
      final newIndex =
          items.isEmpty ? 0 : state.currentIndex.clamp(0, items.length - 1);
      emit(
        state.copyWith(
          isBusy: false,
          items: items,
          currentIndex: newIndex,
          feedback: PhotoViewerFeedback.deleted,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          isBusy: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }
}
