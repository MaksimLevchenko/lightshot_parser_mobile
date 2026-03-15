import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:lightshot_parser_mobile/app/app.dart';
import 'package:lightshot_parser_mobile/core/logging/app_bloc_observer.dart';
import 'package:lightshot_parser_mobile/core/logging/app_logger.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/imgur_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/lightshot_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/repositories/download_repository.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/imgur_download_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/lightshot_download_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/data/repositories/photo_actions_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/services/notification_service.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      Bloc.observer = AppBlocObserver();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'Unhandled Flutter framework error',
          scope: 'flutter',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        AppLogger.error(
          'Unhandled platform error',
          scope: 'flutter',
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      };

      runApp(const AppBootstrap());
    },
    (error, stackTrace) {
      AppLogger.error(
        'Unhandled zone error',
        scope: 'flutter',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final SettingsRepository _settingsRepository;
  late final GalleryRepository _galleryRepository;
  late final DownloadRepository _downloadRepository;
  late final PhotoActionsRepository _photoActionsRepository;
  late final NotificationService _notificationService;
  late final ImageClassifierService _imageClassifierService;

  @override
  void initState() {
    super.initState();
    _settingsRepository = SettingsRepository(SettingsLocalDataSource());
    _galleryRepository = GalleryRepository(
      settingsRepository: _settingsRepository,
      localDataSource: GalleryLocalDataSource(),
    );
    _imageClassifierService = ImageClassifierService(
      imagePreprocessor: ImagePreprocessor(),
      inferenceBackend: OnnxInferenceBackend(),
      cascadeClassifier: const CascadeClassifier(),
      rootIsolateToken: RootIsolateToken.instance,
    );
    _downloadRepository = DownloadRepository(
      sources: [
        LightshotDownloadSource(LightshotRemoteDataSource()),
        ImgurDownloadSource(ImgurRemoteDataSource()),
      ],
      galleryRepository: _galleryRepository,
      imageClassifierService: _imageClassifierService,
      settingsRepository: _settingsRepository,
    );
    _photoActionsRepository = PhotoActionsRepository(_galleryRepository);
    _notificationService = NotificationService();
  }

  @override
  Future<void> dispose() async {
    await _galleryRepository.dispose();
    await _imageClassifierService.dispose();
    await _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return App(
      settingsRepository: _settingsRepository,
      galleryRepository: _galleryRepository,
      downloadRepository: _downloadRepository,
      photoActionsRepository: _photoActionsRepository,
      notificationService: _notificationService,
      imageClassifierService: _imageClassifierService,
    );
  }
}
