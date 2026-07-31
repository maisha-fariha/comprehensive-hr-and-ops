import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Outfit font weights as used across the Figma design.
abstract final class AppFontWeight {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  const AppFontWeight._();
}

/// Typography tokens built on the "Outfit" typeface bundled with the app.
/// Font sizes intentionally use the exact values measured from the Figma
/// design; wrap usages with [ResponsiveHelper.getResponsiveFontSize] where
/// device-adaptive scaling is required.
abstract final class AppTextStyles {
  static const String fontFamily = 'Outfit';

  static TextStyle base({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }

  // Section / card headings, e.g. "Today's Overview", "Today's Schedule"
  static final TextStyle heading3 = base(fontSize: 15.5, fontWeight: AppFontWeight.semiBold);

  // Greeting headline in the hero header, e.g. "Good morning, Alex"
  static final TextStyle greeting = base(
    fontSize: 26,
    fontWeight: AppFontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.4,
  );

  // Large stat numbers, e.g. "12", "3"
  static final TextStyle statValue = base(
    fontSize: 30,
    fontWeight: AppFontWeight.bold,
    color: AppColors.textHeading,
    letterSpacing: -0.6,
  );

  const AppTextStyles._();
}
