import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/features/download/data/repositories/download_repository.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_progress.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_update.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_event.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_state.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/services/notification_service.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  DownloadBloc({
    required DownloadRepository downloadRepository,
    required SettingsRepository settingsRepository,
    required NotificationService notificationService,
  })  : _downloadRepository = downloadRepository,
        _settingsRepository = settingsRepository,
        _notificationService = notificationService,
        super(const DownloadState.initial()) {
    on<DownloadRequested>(_onRequested);
    on<DownloadCancelled>(_onCancelled);
    on<DownloadUpdateReceived>(_onUpdateReceived);
    on<DownloadFeedbackCleared>(_onFeedbackCleared);

    _notificationSubscription = _notificationService.actions.listen((action) {
      if (action == NotificationAction.cancelDownload) {
        add(const DownloadCancelled());
      }
    });
  }

  final DownloadRepository _downloadRepository;
  final SettingsRepository _settingsRepository;
  final NotificationService _notificationService;

  StreamSubscription<DownloadUpdate>? _downloadSubscription;
  StreamSubscription<NotificationAction>? _notificationSubscription;

  Future<void> _onRequested(
    DownloadRequested event,
    Emitter<DownloadState> emit,
  ) async {
    if (state.isDownloading) {
      return;
    }

    final settings = _settingsRepository.currentSettings;
    final request = DownloadRequest(
      targetCount: settings.wantedNumOfImages,
      useNewAddresses: settings.useNewAddresses,
      useRandomAddress: settings.useRandomAddress,
      startingUrl: settings.startingUrl,
      proxySettings: settings.proxySettings,
    );

    emit(
      state.copyWith(
        status: DownloadStatus.inProgress,
        progress: DownloadProgress(
          downloadedCount: 0,
          totalCount: request.targetCount,
        ),
        clearFailure: true,
      ),
    );
    await _notificationService.showProgressBarNotification(
      title: 'downloading',
      body: '${0}/${request.targetCount}',
      maxValue: request.targetCount,
      progress: 0,
    );

    await _downloadSubscription?.cancel();
    _downloadSubscription = _downloadRepository.start(request).listen(
          (update) => add(DownloadUpdateReceived(update)),
        );
  }

  Future<void> _onCancelled(
    DownloadCancelled event,
    Emitter<DownloadState> emit,
  ) async {
    if (!state.isDownloading) {
      return;
    }
    await _downloadRepository.cancel();
  }

  Future<void> _onUpdateReceived(
    DownloadUpdateReceived event,
    Emitter<DownloadState> emit,
  ) async {
    final update = event.update;
    switch (update.type) {
      case DownloadUpdateType.progress:
        emit(
          state.copyWith(
            status: DownloadStatus.inProgress,
            progress: update.progress,
            clearFailure: true,
          ),
        );
        await _notificationService.showProgressBarNotification(
          title: 'downloading',
          body:
              '${update.progress.downloadedCount}/${update.progress.totalCount}',
          maxValue: update.progress.totalCount,
          progress: update.progress.downloadedCount,
        );
      case DownloadUpdateType.cancelled:
        await _notificationService.cancelNotification(0);
        emit(
          state.copyWith(
            status: DownloadStatus.cancelled,
            progress: update.progress,
            clearFailure: true,
          ),
        );
      case DownloadUpdateType.completed:
        await _notificationService.cancelNotification(0);
        await _notificationService.showNotification(
          title: 'completed',
          body: '${update.progress.downloadedCount}',
        );
        emit(
          state.copyWith(
            status: DownloadStatus.completed,
            progress: update.progress,
            clearFailure: true,
          ),
        );
      case DownloadUpdateType.failed:
        await _notificationService.cancelNotification(0);
        emit(
          state.copyWith(
            status: DownloadStatus.failure,
            progress: update.progress,
            failureCode: update.message,
            errorDetails: update.message,
          ),
        );
    }
  }

  void _onFeedbackCleared(
    DownloadFeedbackCleared event,
    Emitter<DownloadState> emit,
  ) {
    emit(
      state.copyWith(
        status: DownloadStatus.idle,
        progress: const DownloadProgress.initial(),
        clearFailure: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _downloadSubscription?.cancel();
    await _notificationSubscription?.cancel();
    return super.close();
  }
}
