import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/features/bootstrap/presentation/cubit/bootstrap_state.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/services/notification_service.dart';

class BootstrapCubit extends Cubit<BootstrapState> {
  BootstrapCubit({
    required SettingsRepository settingsRepository,
    required GalleryRepository galleryRepository,
    required NotificationService notificationService,
  })  : _settingsRepository = settingsRepository,
        _galleryRepository = galleryRepository,
        _notificationService = notificationService,
        super(const BootstrapState.initial()) {
    initialize();
  }

  final SettingsRepository _settingsRepository;
  final GalleryRepository _galleryRepository;
  final NotificationService _notificationService;

  Future<void> initialize() async {
    emit(state.copyWith(status: BootstrapStatus.loading, clearError: true));
    try {
      await _settingsRepository.ensureInitialized();
      await _galleryRepository.ensureInitialized();
      try {
        await _notificationService.init();
      } on Object catch (error) {
        debugPrint('Notification init failed: $error');
      }
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: BootstrapStatus.ready, clearError: true));
    } on Object catch (error) {
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
}
