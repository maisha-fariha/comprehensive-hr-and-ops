import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Application-wide Material 3 theme. This is the single place feature
/// modules should pull shared styling from, so new screens automatically
/// stay visually consistent with the Figma design system.
abstract final class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.secondaryTeal,
      brightness: Brightness.light,
      primary: AppColors.secondaryTeal,
      onPrimary: Colors.white,
      secondary: AppColors.primaryNavy,
      surface: AppColors.surfaceWhite,
      error: AppColors.criticalRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      fontFamily: AppTextStyles.fontFamily,
      splashFactory: InkRipple.splashFactory,
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: AppTextStyles.base(fontSize: 20, fontWeight: AppFontWeight.semiBold),
        titleMedium: AppTextStyles.base(fontSize: 15.5, fontWeight: AppFontWeight.semiBold),
        bodyLarge: AppTextStyles.base(fontSize: 14, fontWeight: AppFontWeight.regular),
        bodyMedium: AppTextStyles.base(
          fontSize: 12,
          fontWeight: AppFontWeight.regular,
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      splashColor: AppColors.secondaryTeal.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
    );
  }

  const AppTheme._();
}
