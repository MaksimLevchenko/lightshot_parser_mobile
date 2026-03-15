import 'package:flutter/material.dart';

final class AppColors {
  static const Color seed = Color(0xFFC85A54);
  static const Color accent = Color(0xFF2D6A73);
  static const Color surfaceTint = Color(0xFFF6EFE9);
  static const Color background = Color(0xFFF4EAE1);
  static const Color panel = Color(0xFFFFFBF7);
  static const Color panelStrong = Color(0xFFF1E2D4);
  static const Color outline = Color(0xFFD9C7B6);
  static const Color textMuted = Color(0xFF6E655D);
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2F7D32);
  static const Color warning = Color(0xFFAD6800);
  static const Color imageCard = Color(0xFFFFF8F2);
}

final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

final class AppRadius {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    surface: AppColors.panel,
    brightness: Brightness.light,
  );

  return ThemeData.from(
    colorScheme: colorScheme,
    useMaterial3: true,
  ).copyWith(
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.hardEdge,
      color: AppColors.imageCard,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.panelStrong,
      side: const BorderSide(color: AppColors.outline),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
    ),
    textTheme: ThemeData.light().textTheme.copyWith(
          headlineMedium: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.05,
            color: Colors.black87,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            height: 1.4,
            color: Colors.black87,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.black87,
          ),
          bodySmall: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: AppColors.textMuted,
          ),
        ),
  );
}
