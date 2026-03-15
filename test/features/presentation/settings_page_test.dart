import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/app_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/utils/settings_page_texts.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

import '../../support/test_storage.dart';
import '../../support/test_image_classifier_service.dart';

class StubGalleryRepository extends GalleryRepository {
  StubGalleryRepository({
    required super.settingsRepository,
  })  : _itemsController = StreamController<List<GalleryItem>>.broadcast(),
        super(
          localDataSource: GalleryLocalDataSource(),
        );

  final StreamController<List<GalleryItem>> _itemsController;

  @override
  Stream<List<GalleryItem>> watch() => _itemsController.stream;

  @override
  Future<void> ensureInitialized() async {
    await refresh();
  }

  @override
  Future<void> refresh() async {
    if (!_itemsController.isClosed) {
      _itemsController.add(const <GalleryItem>[]);
    }
  }

  @override
  Future<void> clearImages() async {
    await refresh();
  }

  @override
  Future<void> rebuildIndex() async {
    await refresh();
  }

  @override
  Future<void> reclassifyAllImages({
    required ImageClassifierService imageClassifierService,
    void Function(int processedCount, int totalCount)? onProgress,
    bool disabledOnly = false,
  }) async {
    onProgress?.call(0, 2);
    onProgress?.call(1, 2);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    onProgress?.call(2, 2);
    await refresh();
  }

  @override
  Future<void> dispose() async {
    await _itemsController.close();
  }
}

void main() {
  late TestStorageContext storageContext;
  late SettingsRepository settingsRepository;
  late GalleryRepository galleryRepository;
  late SettingsCubit settingsCubit;
  late GalleryCubit galleryCubit;
  late ImageClassifierService imageClassifierService;

  setUp(() async {
    storageContext = await createTestStorageContext();
  });

  tearDown(() async {
    await settingsCubit.close();
    await galleryCubit.close();
    await galleryRepository.dispose();
    await imageClassifierService.dispose();
    await storageContext.dispose();
  });

  Future<void> preparePage({
    AppSettings settings = const AppSettings.initial(),
  }) async {
    settingsRepository = SettingsRepository(
      TestSettingsLocalDataSource(
        storagePaths: storageContext.storagePaths,
        initialSettings: settings,
      ),
    );
    await settingsRepository.ensureInitialized();
    imageClassifierService = buildTestImageClassifierService();
    galleryRepository = StubGalleryRepository(
      settingsRepository: settingsRepository,
    );
    await galleryRepository.ensureInitialized();
    settingsCubit = SettingsCubit(settingsRepository);
    galleryCubit = GalleryCubit(galleryRepository, imageClassifierService);
  }

  Future<void> pumpSettingsPage(
    WidgetTester tester, {
    required double width,
    double height = 1200,
  }) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: settingsRepository),
          RepositoryProvider.value(value: galleryRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: settingsCubit),
            BlocProvider.value(value: galleryCubit),
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
            home: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('renders stacked cards on narrow screens', (tester) async {
    await preparePage();
    await pumpSettingsPage(tester, width: 420);

    expect(
        find.byKey(const ValueKey('settings-mobile-layout')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-desktop-layout')),
      findsNothing,
    );
  });

  testWidgets('renders two-column layout on wide screens', (tester) async {
    await preparePage();
    await pumpSettingsPage(tester, width: 1280);

    expect(
      find.byKey(const ValueKey('settings-desktop-layout')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('general-settings-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-settings-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('proxy-settings-card')), findsOneWidget);
  });

  testWidgets('selected source switches between Lightshot and Imgur cards',
      (tester) async {
    await preparePage();
    await pumpSettingsPage(tester, width: 1100);

    expect(
        find.byKey(const ValueKey('lightshot-settings-group')), findsOneWidget);
    expect(find.byKey(const ValueKey('imgur-settings-group')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-source-field')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Imgur').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('imgur-settings-group')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('lightshot-settings-group')), findsNothing);
    expect(settingsRepository.currentSettings.selectedSource,
        DownloadSource.imgur);
  });

  testWidgets('proxy section expands and saves immediately', (tester) async {
    await preparePage();
    await pumpSettingsPage(tester, width: 1100);

    expect(find.byKey(const ValueKey('settings-proxy-address-field')),
        findsNothing);

    await tester
        .ensureVisible(find.byKey(const ValueKey('proxy-settings-card')));
    await tester.tap(find.text('Use proxy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('settings-proxy-address-field')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('settings-proxy-port-field')),
        findsOneWidget);
    expect(settingsCubit.state.draft.proxySettings.enabled, isTrue);
    expect(settingsRepository.currentSettings.proxySettings.enabled, isFalse);
  });

  testWidgets('maintenance actions require confirmation', (tester) async {
    await preparePage();
    await pumpSettingsPage(tester, width: 1100);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('maintenance-clear-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('maintenance-clear-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text(SettingsPageTexts.confirmClearTitle(
          tester.element(find.byType(SettingsPage)))),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('valid text input autosaves after debounce', (tester) async {
    await preparePage();
    await pumpSettingsPage(tester, width: 1100);

    await tester.enterText(
      find.byKey(const ValueKey('settings-wanted-num-field')),
      '42',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));

    expect(settingsRepository.currentSettings.wantedNumOfImages, 42);
  });

  testWidgets('neural recognition switch updates persisted setting',
      (tester) async {
    await preparePage();
    await pumpSettingsPage(tester, width: 1100);

    await tester
        .tap(find.byKey(const ValueKey('settings-neural-recognition-switch')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(settingsCubit.state.draft.isNeuralRecognitionEnabled, isFalse);
    expect(
      settingsRepository.currentSettings.isNeuralRecognitionEnabled,
      isFalse,
    );
  });

  testWidgets('reclassification action shows progress and completion feedback',
      (tester) async {
    await preparePage();
    await pumpSettingsPage(tester, width: 1100);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('maintenance-reclassify-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester
        .tap(find.byKey(const ValueKey('maintenance-reclassify-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Reclassify all images'), findsWidgets);

    await tester.tap(find.text('Reclassify all images').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('1 of 2'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(find.text('Image recognition updated'), findsOneWidget);
  });

  testWidgets('invalid text input does not overwrite persisted settings',
      (tester) async {
    await preparePage();
    await pumpSettingsPage(tester, width: 1100);

    await tester.enterText(
      find.byKey(const ValueKey('settings-wanted-num-field')),
      '0',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));

    expect(settingsRepository.currentSettings.wantedNumOfImages, 10);
  });
}
