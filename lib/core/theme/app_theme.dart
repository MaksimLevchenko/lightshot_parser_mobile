import 'package:flutter/material.dart';

final class AppColors {
  static const Color seed = Colors.pink;
  static const Color surfaceTint = Color(0xFFF7E8EE);
  static const Color error = Colors.red;
  static const Color success = Colors.green;
  static const Color imageCard = Colors.white70;
}

final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.seed);
  return ThemeData.from(
    colorScheme: colorScheme,
    useMaterial3: true,
  ).copyWith(
    scaffoldBackgroundColor: AppColors.surfaceTint,
    cardTheme: const CardThemeData(
      clipBehavior: Clip.hardEdge,
      color: AppColors.imageCard,
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
