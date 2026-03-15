import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_state.dart';

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit(this._galleryRepository) : super(const GalleryState.initial()) {
    _subscription =
        _galleryRepository.watch().listen((List<GalleryItem> items) {
      emit(
        state.copyWith(
          isLoading: false,
          items: items,
          clearFeedback: true,
        ),
      );
    });
    load();
  }

  final GalleryRepository _galleryRepository;
  StreamSubscription<List<GalleryItem>>? _subscription;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    try {
      await _galleryRepository.refresh();
    } on Object catch (error) {
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
    } on Object catch (error) {
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
    } on Object catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
