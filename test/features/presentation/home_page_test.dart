import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/features/download/data/repositories/download_repository.dart';
import 'package:lightshot_parser_mobile/features/download/data/sources/download_source_engine.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_progress.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_request.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_update.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_bloc.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_event.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/pages/home_page.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/data/repositories/photo_actions_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/app_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/imgur_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/lightshot_source_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/proxy_settings.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';
import 'package:lightshot_parser_mobile/services/notification_service.dart';

import '../../support/test_storage.dart';
import '../../support/test_image_classifier_service.dart';

class StubNotificationService extends NotificationService {
  final StreamController<NotificationAction> _controller =
      StreamController<NotificationAction>.broadcast();

  @override
  Stream<NotificationAction> get actions => _controller.stream;

  @override
  Future<void> showProgressBarNotification({
    int id = 0,
    required String title,
    required String body,
    required int maxValue,
    required int progress,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> showNotification({
    int id = 1,
    required String title,
    required String body,
  }) async {}

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
          imageClassifierService: buildTestImageClassifierService(),
        );

  final StreamController<DownloadUpdate> updatesController =
      StreamController<DownloadUpdate>.broadcast();

  @override
  Stream<DownloadUpdate> start(DownloadRequest request) =>
      updatesController.stream;
}

void main() {
  late TestStorageContext storageContext;
  late SettingsRepository settingsRepository;
  late GalleryRepository galleryRepository;
  late PhotoActionsRepository photoActionsRepository;
  late GalleryCubit galleryCubit;
  late StubDownloadRepository downloadRepository;
  late StubNotificationService notificationService;
  late DownloadBloc downloadBloc;

  setUp(() async {
    storageContext = await createTestStorageContext();
  });

  tearDown(() async {
    await downloadBloc.close();
    await notificationService.dispose();
    await downloadRepository.updatesController.close();
    await galleryCubit.close();
    await galleryRepository.dispose();
    await storageContext.dispose();
  });

  Future<void> prepareApp({
    AppSettings settings = const AppSettings.initial(),
  }) async {
    settingsRepository = SettingsRepository(
      TestSettingsLocalDataSource(
        storagePaths: storageContext.storagePaths,
        initialSettings: settings,
      ),
    );
    await settingsRepository.ensureInitialized();
    galleryRepository = GalleryRepository(
      settingsRepository: settingsRepository,
      localDataSource: GalleryLocalDataSource(),
    );
    await galleryRepository.ensureInitialized();
    photoActionsRepository = PhotoActionsRepository(galleryRepository);
    galleryCubit = GalleryCubit(galleryRepository);
    downloadRepository = StubDownloadRepository();
    notificationService = StubNotificationService();
    downloadBloc = DownloadBloc(
      downloadRepository: downloadRepository,
      settingsRepository: settingsRepository,
      notificationService: notificationService,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  Future<void> pumpHomePage(
    WidgetTester tester, {
    required double width,
  }) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: settingsRepository),
          RepositoryProvider.value(value: galleryRepository),
          RepositoryProvider.value(value: photoActionsRepository),
          RepositoryProvider.value(value: notificationService),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: galleryCubit),
            BlocProvider.value(value: downloadBloc),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              S.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            theme: buildAppTheme(),
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 900)),
              child: SizedBox(
                width: width,
                height: 900,
                child: const HomePage(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('idle state shows configuration summary', (tester) async {
    await prepareApp(
      settings: const AppSettings(
        wantedNumOfImages: 42,
        selectedSource: DownloadSource.imgur,
        lightshot: LightshotSourceSettings.initial(),
        imgur: ImgurSourceSettings(
          candidateLengths: [7],
          useRandomAddress: false,
          startingId: 'start42',
        ),
        proxySettings: ProxySettings(
          enabled: true,
          useAuthentication: false,
          address: '127.0.0.1',
          port: '8080',
          login: '',
          password: '',
        ),
      ),
    );

    await pumpHomePage(tester, width: 900);

    expect(find.byKey(const ValueKey('home-hero')), findsOneWidget);
    expect(find.text('Imgur'), findsWidgets);
    expect(find.text('42'), findsWidgets);
    expect(find.text('Use proxy'), findsWidgets);
  });

  testWidgets('downloading state shows progress and cancel button',
      (tester) async {
    await prepareApp();
    await pumpHomePage(tester, width: 900);

    downloadBloc.add(const DownloadRequested());
    await tester.pump();
    downloadRepository.updatesController.add(
      const DownloadUpdate(
        type: DownloadUpdateType.progress,
        progress: DownloadProgress(downloadedCount: 2, totalCount: 10),
      ),
    );
    await tester.pump();

    expect(find.text('Cancel'), findsWidgets);
    expect(find.byKey(const ValueKey('download-progress-indicator')),
        findsOneWidget);
    expect(
        find.text('2 images out of 10 have been downloaded'), findsOneWidget);
  });

  testWidgets('empty gallery state exposes CTA', (tester) async {
    await prepareApp();
    await pumpHomePage(tester, width: 900);

    expect(find.text('There are no images'), findsOneWidget);
    expect(find.byKey(const ValueKey('empty-gallery-cta')), findsOneWidget);
  });

  testWidgets('recent gallery renders grid preview cards', (tester) async {
    await _writeImageFile(
        '${storageContext.storagePaths.photosDirectory.path}/lightshot@@one.png');
    await _writeImageFile(
        '${storageContext.storagePaths.photosDirectory.path}/imgur@@two.png');
    await prepareApp();
    await pumpHomePage(tester, width: 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('recent-gallery-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-preview-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-preview-1')), findsOneWidget);
  });

  testWidgets('layout switches between narrow and wide breakpoints',
      (tester) async {
    await prepareApp();
    await pumpHomePage(tester, width: 900);

    expect(find.byKey(const ValueKey('home-narrow-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-wide-layout')), findsNothing);

    await pumpHomePage(tester, width: 1300);

    expect(find.byKey(const ValueKey('home-wide-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-narrow-layout')), findsNothing);
  });
}

Future<void> _writeImageFile(String path) async {
  const bytes = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0xF8,
    0xCF,
    0xC0,
    0x00,
    0x00,
    0x03,
    0x01,
    0x01,
    0x00,
    0x18,
    0xDD,
    0x8D,
    0xB1,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];
  await File(path).writeAsBytes(bytes, flush: true);
}
