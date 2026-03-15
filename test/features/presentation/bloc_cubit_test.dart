import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/lightshot_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/repositories/download_repository.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_progress.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_update.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_bloc.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_event.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_state.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_state.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_state.dart';
import 'package:lightshot_parser_mobile/services/notification_service.dart';

import '../../support/test_storage.dart';

class StubNotificationService extends NotificationService {
  final StreamController<NotificationAction> _controller =
      StreamController<NotificationAction>.broadcast();

  final List<int> cancelledIds = <int>[];
  final List<String> shownNotifications = <String>[];
  int progressNotificationCount = 0;

  @override
  Stream<NotificationAction> get actions => _controller.stream;

  Future<void> emitAction(NotificationAction action) async {
    _controller.add(action);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> showProgressBarNotification({
    int id = 0,
    required String title,
    required String body,
    required int maxValue,
    required int progress,
  }) async {
    progressNotificationCount += 1;
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> showNotification({
    int id = 1,
    required String title,
    required String body,
  }) async {
    shownNotifications.add('$title:$body');
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class StubDownloadRepository extends DownloadRepository {
  StubDownloadRepository()
      : super(
          remoteDataSource: LightshotRemoteDataSource(),
          galleryRepository: GalleryRepository(
            settingsRepository: SettingsRepository(
              TestSettingsLocalDataSource(
                storagePaths: StoragePaths(
                  photosDirectory: Directory(Directory.systemTemp.path),
                  databaseDirectory: Directory(Directory.systemTemp.path),
                  settingsDirectory: Directory(Directory.systemTemp.path),
                ),
              ),
            ),
            localDataSource: GalleryLocalDataSource(),
          ),
        );

  final StreamController<DownloadUpdate> updatesController =
      StreamController<DownloadUpdate>.broadcast();
  bool cancelCalled = false;

  @override
  Stream<DownloadUpdate> start(DownloadRequest request) {
    return updatesController.stream;
  }

  @override
  Future<void> cancel() async {
    cancelCalled = true;
  }
}

void main() {
  group('SettingsCubit', () {
    test('save updates repository and emits success', () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      final cubit = SettingsCubit(settingsRepository);

      cubit.setWantedNumOfImages(42);
      await cubit.save();

      expect(cubit.state.saveStatus, SettingsSaveStatus.success);
      expect(settingsRepository.currentSettings.wantedNumOfImages, 42);

      await cubit.close();
      await storageContext.dispose();
    });

    test('save emits failure when datasource throws', () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        FailingSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      final cubit = SettingsCubit(settingsRepository);

      await cubit.save();

      expect(cubit.state.saveStatus, SettingsSaveStatus.failure);

      await cubit.close();
      await storageContext.dispose();
    });
  });

  group('GalleryCubit', () {
    test('rebuildIndex emits typed feedback and clearFeedback resets it', () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      await File('${storageContext.storagePaths.photosDirectory.path}/img001.jpg')
          .writeAsString('binary-data');
      final repository = GalleryRepository(
        settingsRepository: settingsRepository,
        localDataSource: GalleryLocalDataSource(),
      );
      await repository.ensureInitialized();
      final cubit = GalleryCubit(repository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await cubit.rebuildIndex();
      expect(cubit.state.feedback, GalleryFeedback.reindexed);

      cubit.clearFeedback();
      expect(cubit.state.feedback, isNull);

      await cubit.close();
      await repository.dispose();
      await storageContext.dispose();
    });
  });

  group('DownloadBloc', () {
    test('completed updates drive final completed state and notification', () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      final notificationService = StubNotificationService();
      final downloadRepository = StubDownloadRepository();
      final bloc = DownloadBloc(
        downloadRepository: downloadRepository,
        settingsRepository: settingsRepository,
        notificationService: notificationService,
      );

      bloc.add(const DownloadRequested());
      await Future<void>.delayed(Duration.zero);
      downloadRepository.updatesController.add(
        const DownloadUpdate(
          type: DownloadUpdateType.progress,
          progress: DownloadProgress(downloadedCount: 1, totalCount: 1),
        ),
      );
      downloadRepository.updatesController.add(
        const DownloadUpdate(
          type: DownloadUpdateType.completed,
          progress: DownloadProgress(downloadedCount: 1, totalCount: 1),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.status, DownloadStatus.completed);
      expect(notificationService.progressNotificationCount, greaterThan(0));
      expect(notificationService.shownNotifications, contains('completed:1'));

      await bloc.close();
      await notificationService.dispose();
      await downloadRepository.updatesController.close();
      await storageContext.dispose();
    });

    test('notification cancel action calls repository cancel', () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      final notificationService = StubNotificationService();
      final downloadRepository = StubDownloadRepository();
      final bloc = DownloadBloc(
        downloadRepository: downloadRepository,
        settingsRepository: settingsRepository,
        notificationService: notificationService,
      );

      bloc.add(const DownloadRequested());
      await Future<void>.delayed(Duration.zero);
      await notificationService.emitAction(NotificationAction.cancelDownload);

      expect(downloadRepository.cancelCalled, isTrue);

      await bloc.close();
      await notificationService.dispose();
      await downloadRepository.updatesController.close();
      await storageContext.dispose();
    });

    test('failed update ends in failure state', () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      final notificationService = StubNotificationService();
      final downloadRepository = StubDownloadRepository();
      final bloc = DownloadBloc(
        downloadRepository: downloadRepository,
        settingsRepository: settingsRepository,
        notificationService: notificationService,
      );

      bloc.add(const DownloadRequested());
      await Future<void>.delayed(Duration.zero);
      downloadRepository.updatesController.add(
        const DownloadUpdate(
          type: DownloadUpdateType.failed,
          progress: DownloadProgress(downloadedCount: 0, totalCount: 1),
          message: 'proxy',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.status, DownloadStatus.failure);
      expect(bloc.state.failureCode, 'proxy');

      await bloc.close();
      await notificationService.dispose();
      await downloadRepository.updatesController.close();
      await storageContext.dispose();
    });
  });
}
