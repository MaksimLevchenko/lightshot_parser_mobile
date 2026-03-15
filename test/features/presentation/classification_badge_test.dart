import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/widgets/classification_badge.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

void main() {
  Future<void> pumpBadge(
    WidgetTester tester,
    ClassificationResult result,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          S.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        theme: buildAppTheme(),
        home: Scaffold(
          body: Center(
            child: ClassificationBadge(classificationResult: result),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders loading label for pending classification',
      (tester) async {
    await pumpBadge(
      tester,
      ClassificationResult.pending(backend: 'mock'),
    );

    expect(find.text('Loading'), findsOneWidget);
  });

  testWidgets('renders localized category label for completed result',
      (tester) async {
    await pumpBadge(
      tester,
      ClassificationResult.completed(
        category: ClassificationCategory.games,
        confidence: 0.91,
        rawScores: const ClassificationScores(
          nsfw: 0.1,
          documents: 0.2,
          games: 0.91,
        ),
        backend: 'mock',
        classifiedAt: DateTime(2026, 3, 15),
      ),
    );

    expect(find.text('Games'), findsOneWidget);
  });
}
