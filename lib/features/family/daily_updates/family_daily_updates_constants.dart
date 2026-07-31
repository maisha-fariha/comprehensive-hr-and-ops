import 'package:flutter/material.dart';

/// Design tokens used by the Family "Daily Updates" feature that are not
/// already covered by `lib/core/constants/app_colors.dart`/`app_dimens.dart`.
/// Kept local to this feature per the module boundary rules.
abstract final class FamilyDailyUpdatesColors {
  /// Tan/orange tone used for the "Meals" timeline entry's dot + icon box.
  static const Color mealsForeground = Color(0xFFB8763A);
  static const Color mealsBackground = Color(0xFFF7EDE1);

  /// Indigo/navy tone used for the "Sleep" timeline entry's dot + icon box.
  static const Color sleepForeground = Color(0xFF3B4B7C);
  static const Color sleepBackground = Color(0xFFEAEBF5);

  const FamilyDailyUpdatesColors._();
}
