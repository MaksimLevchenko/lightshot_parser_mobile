import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_state.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit(this._galleryRepository, this._imageClassifierService)
      : super(const GalleryState.initial()) {
    _subscription =
        _galleryRepository.watch().listen((List<GalleryItem> items) {
      emit(
        state.copyWith(
          isLoading: false,
          items: items,
        ),
      );
    });
    load();
  }

  final GalleryRepository _galleryRepository;
  final ImageClassifierService _imageClassifierService;
  StreamSubscription<List<GalleryItem>>? _subscription;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    try {
      await _galleryRepository.refresh();
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> clearImages() async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    try {
      await _galleryRepository.clearImages();
      emit(
        state.copyWith(
          isLoading: false,
          items: const [],
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> rebuildIndex() async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    try {
      await _galleryRepository.rebuildIndex();
      emit(
        state.copyWith(
          isLoading: false,
          feedback: GalleryFeedback.reindexed,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> reclassifyAllImages({
    bool disabledOnly = false,
  }) async {
    if (state.isReclassifying) {
      return;
    }

    emit(
      state.copyWith(
        isReclassifying: true,
        reclassificationProcessedCount: 0,
        reclassificationTotalCount: 0,
        clearFeedback: true,
      ),
    );
    try {
      await _galleryRepository.reclassifyAllImages(
        imageClassifierService: _imageClassifierService,
        disabledOnly: disabledOnly,
        onProgress: (processedCount, totalCount) {
          emit(
            state.copyWith(
              isReclassifying: true,
              reclassificationProcessedCount: processedCount,
              reclassificationTotalCount: totalCount,
              clearFeedback: true,
            ),
          );
        },
      );
      emit(
        state.copyWith(
          isReclassifying: false,
          feedback: GalleryFeedback.reclassified,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          isReclassifying: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  void setFilter(GalleryFilter filter) {
    if (state.selectedFilter == filter) {
      return;
    }
    emit(state.copyWith(selectedFilter: filter));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
