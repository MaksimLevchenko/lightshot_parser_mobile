import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/core/logging/app_logger.dart';
import 'package:lightshot_parser_mobile/features/bootstrap/presentation/cubit/bootstrap_state.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/services/notification_service.dart';

class BootstrapCubit extends Cubit<BootstrapState> {
  BootstrapCubit({
    required SettingsRepository settingsRepository,
    required GalleryRepository galleryRepository,
    required NotificationService notificationService,
    required ImageClassifierService imageClassifierService,
  })  : _settingsRepository = settingsRepository,
        _galleryRepository = galleryRepository,
        _notificationService = notificationService,
        _imageClassifierService = imageClassifierService,
        super(const BootstrapState.initial()) {
    initialize();
  }

  final SettingsRepository _settingsRepository;
  final GalleryRepository _galleryRepository;
  final NotificationService _notificationService;
  final ImageClassifierService _imageClassifierService;

  Future<void> initialize() async {
    emit(state.copyWith(status: BootstrapStatus.loading, clearError: true));
    try {
      await _settingsRepository.ensureInitialized();
      await _galleryRepository.ensureInitialized();
      try {
        await _imageClassifierService.warmUp();
      } on Object catch (error, stackTrace) {
        AppLogger.warning(
          'Image classification warmup failed',
          scope: 'bootstrap',
          error: error,
          stackTrace: stackTrace,
        );
      }
      try {
        await _notificationService.init();
      } on Object catch (error, stackTrace) {
        AppLogger.warning(
          'Notification initialization failed',
          scope: 'bootstrap',
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: BootstrapStatus.ready, clearError: true));
      if (_settingsRepository.currentSettings.isNeuralRecognitionEnabled) {
        unawaited(_resumePendingClassifications());
      }
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: BootstrapStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _resumePendingClassifications() async {
    try {
      await _galleryRepository.resumePendingClassifications(
        imageClassifierService: _imageClassifierService,
      );
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Resuming pending image classifications failed',
        scope: 'bootstrap',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
