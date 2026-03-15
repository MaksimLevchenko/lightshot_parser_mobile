import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/features/download/data/repositories/download_repository.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/download_source_engine.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_progress.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_update.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_bloc.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_event.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_state.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_state.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_state.dart';
import 'package:lightshot_parser_mobile/services/notification_service.dart';

import '../../support/test_storage.dart';
import '../../support/test_image_classifier_service.dart';

SettingsRepository _buildStubSettingsRepository() {
  return SettingsRepository(
    TestSettingsLocalDataSource(
      storagePaths: StoragePaths(
        photosDirectory: Directory(Directory.systemTemp.path),
        databaseDirectory: Directory(Directory.systemTemp.path),
        settingsDirectory: Directory(Directory.systemTemp.path),
      ),
    ),
  );
}

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
          sources: const <DownloadSourceEngine>[],
          galleryRepository: GalleryRepository(
            settingsRepository: _buildStubSettingsRepository(),
            localDataSource: GalleryLocalDataSource(),
          ),
          imageClassifierService: buildTestImageClassifierService(),
          settingsRepository: _buildStubSettingsRepository(),
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

    test('setNeuralRecognitionEnabled updates draft and persists value',
        () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      final cubit = SettingsCubit(settingsRepository);

      cubit.setNeuralRecognitionEnabled(false);
      expect(cubit.state.draft.isNeuralRecognitionEnabled, isFalse);

      await cubit.save();

      expect(
        settingsRepository.currentSettings.isNeuralRecognitionEnabled,
        isFalse,
      );

      await cubit.close();
      await storageContext.dispose();
    });

    test('save emits failure when datasource throws', () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        FailingSettingsLocalDataSource(
            storagePaths: storageContext.storagePaths),
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
    test('rebuildIndex emits typed feedback and clearFeedback resets it',
        () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      await File(
              '${storageContext.storagePaths.photosDirectory.path}/img001.jpg')
          .writeAsString('binary-data');
      final repository = GalleryRepository(
        settingsRepository: settingsRepository,
        localDataSource: GalleryLocalDataSource(),
      );
      await repository.ensureInitialized();
      final classifier = buildTestImageClassifierService();
      final cubit = GalleryCubit(repository, classifier);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await cubit.rebuildIndex();
      expect(cubit.state.feedback, GalleryFeedback.reindexed);

      cubit.clearFeedback();
      expect(cubit.state.feedback, isNull);

      await cubit.close();
      await classifier.dispose();
      await repository.dispose();
      await storageContext.dispose();
    });

    test('reclassifyAllImages emits progress and completion feedback',
        () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      final file = File(
        '${storageContext.storagePaths.photosDirectory.path}/lightshot@@classified.png',
      );
      await file.writeAsBytes(const <int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      final repository = GalleryRepository(
        settingsRepository: settingsRepository,
        localDataSource: GalleryLocalDataSource(),
      );
      await repository.ensureInitialized();
      await repository.addDownloadedFile(item: GalleryItem.fromFile(file));
      final classifier = DelayedTestImageClassifierService(
        delay: const Duration(milliseconds: 10),
        onClassify: (item) => item.copyWith(
          classificationResult: ClassificationResult.unrecognized(
            backend: 'mock',
          ),
        ),
      );
      final cubit = GalleryCubit(repository, classifier);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final reclassifyFuture = cubit.reclassifyAllImages();
      unawaited(reclassifyFuture);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.isReclassifying, isTrue);
      expect(cubit.state.reclassificationTotalCount, 1);

      await reclassifyFuture;
      expect(cubit.state.isReclassifying, isFalse);
      expect(cubit.state.feedback, GalleryFeedback.reclassified);
      expect(cubit.state.reclassificationProcessedCount, 1);

      await cubit.close();
      await classifier.dispose();
      await repository.dispose();
      await storageContext.dispose();
    });

    test('setFilter exposes only matching items in visibleItems', () async {
      final storageContext = await createTestStorageContext();
      final settingsRepository = SettingsRepository(
        TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
      );
      await settingsRepository.ensureInitialized();
      final nsfwFile = File(
        '${storageContext.storagePaths.photosDirectory.path}/lightshot@@nsfw.png',
      );
      final documentFile = File(
        '${storageContext.storagePaths.photosDirectory.path}/lightshot@@document.png',
      );
      await nsfwFile.writeAsBytes(const <int>[0x01]);
      await documentFile.writeAsBytes(const <int>[0x02]);

      final repository = GalleryRepository(
        settingsRepository: settingsRepository,
        localDataSource: GalleryLocalDataSource(),
      );
      await repository.ensureInitialized();
      await repository.addDownloadedFile(
        item: GalleryItem.fromFile(
          nsfwFile,
          classificationResult: ClassificationResult.completed(
            category: ClassificationCategory.nsfw,
            confidence: 0.91,
            rawScores: const ClassificationScores.zero(),
            backend: 'mock',
            classifiedAt: DateTime(2026, 3, 15),
          ),
        ),
      );
      await repository.addDownloadedFile(
        item: GalleryItem.fromFile(
          documentFile,
          classificationResult: ClassificationResult.completed(
            category: ClassificationCategory.documents,
            confidence: 0.88,
            rawScores: const ClassificationScores.zero(),
            backend: 'mock',
            classifiedAt: DateTime(2026, 3, 15),
          ),
        ),
      );

      final classifier = buildTestImageClassifierService();
      final cubit = GalleryCubit(repository, classifier);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      cubit.setFilter(GalleryFilter.documents);

      expect(cubit.state.selectedFilter, GalleryFilter.documents);
      expect(cubit.state.visibleItems, hasLength(1));
      expect(
        cubit.state.visibleItems.single.classificationResult.category,
        ClassificationCategory.documents,
      );

      await cubit.close();
      await classifier.dispose();
      await repository.dispose();
      await storageContext.dispose();
    });
  });

  group('DownloadBloc', () {
    test('completed updates drive final completed state and notification',
        () async {
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
