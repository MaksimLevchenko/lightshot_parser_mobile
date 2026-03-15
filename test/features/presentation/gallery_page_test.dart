import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/pages/gallery_page.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/data/repositories/photo_actions_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

import '../../support/test_storage.dart';
import '../../support/test_image_classifier_service.dart';

void main() {
  late TestStorageContext storageContext;
  late SettingsRepository settingsRepository;
  late GalleryRepository galleryRepository;
  late PhotoActionsRepository photoActionsRepository;
  late ImageClassifierService imageClassifierService;
  late GalleryCubit galleryCubit;

  setUp(() async {
    storageContext = await createTestStorageContext();
    settingsRepository = SettingsRepository(
      TestSettingsLocalDataSource(storagePaths: storageContext.storagePaths),
    );
    await settingsRepository.ensureInitialized();
    imageClassifierService = buildTestImageClassifierService();
    galleryRepository = GalleryRepository(
      settingsRepository: settingsRepository,
      localDataSource: GalleryLocalDataSource(),
    );
    await galleryRepository.ensureInitialized();
    photoActionsRepository = PhotoActionsRepository(galleryRepository);

    final nsfwPath =
        '${storageContext.storagePaths.photosDirectory.path}/lightshot@@nsfw.png';
    final documentPath =
        '${storageContext.storagePaths.photosDirectory.path}/lightshot@@document.png';
    await _writeImageFile(nsfwPath);
    await _writeImageFile(documentPath);
    await galleryRepository.addDownloadedFile(
      item: GalleryItem.fromFile(
        File(nsfwPath),
        classificationResult: ClassificationResult.completed(
          category: ClassificationCategory.nsfw,
          confidence: 0.91,
          rawScores: const ClassificationScores.zero(),
          backend: 'mock',
          classifiedAt: DateTime(2026, 3, 15),
        ),
      ),
    );
    await galleryRepository.addDownloadedFile(
      item: GalleryItem.fromFile(
        File(documentPath),
        classificationResult: ClassificationResult.completed(
          category: ClassificationCategory.documents,
          confidence: 0.88,
          rawScores: const ClassificationScores.zero(),
          backend: 'mock',
          classifiedAt: DateTime(2026, 3, 15),
        ),
      ),
    );

    galleryCubit = GalleryCubit(galleryRepository, imageClassifierService);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });

  tearDown(() async {
    await galleryCubit.close();
    await galleryRepository.dispose();
    await imageClassifierService.dispose();
    await storageContext.dispose();
  });

  testWidgets('gallery filter shows only matching image types', (tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: galleryRepository),
          RepositoryProvider.value(value: photoActionsRepository),
        ],
        child: BlocProvider.value(
          value: galleryCubit,
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              S.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            theme: buildAppTheme(),
            home: const GalleryPage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('gallery-grid-item-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-grid-item-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gallery-filter-documents')));
    await tester.pump();

    expect(find.byKey(const ValueKey('gallery-grid-item-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-grid-item-1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('gallery-filter-unrecognized')));
    await tester.pump();

    expect(find.text('No images match the selected type'), findsOneWidget);
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
