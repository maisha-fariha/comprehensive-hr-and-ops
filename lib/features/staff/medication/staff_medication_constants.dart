import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import 'domain/entities/staff_medication_enums.dart';

/// Design tokens specific to the Staff "Medication MAR" feature that don't
/// belong in `lib/core/constants` (which is shared across every feature and
/// must not be edited by this feature). Colors/spacing/radii that already
/// exist in `AppColors`/`AppDimens` are reused directly at call sites.
abstract final class StaffMedicationConstants {
  /// Background/foreground color pair for an initials avatar of a given
  /// [AvatarPalette]. Reuses existing `AppColors` status-tint pairs so no
  /// new color values are introduced.
  static ({Color background, Color foreground}) avatarStyle(AvatarPalette palette) {
    return switch (palette) {
      AvatarPalette.blue => (background: AppColors.infoBackground, foreground: AppColors.infoBlue),
      AvatarPalette.green => (background: AppColors.activeBackground, foreground: AppColors.activeGreen),
      AvatarPalette.amber => (background: AppColors.urgentBackground, foreground: AppColors.urgentAmber),
      AvatarPalette.purple => (background: AppColors.nightBackground, foreground: AppColors.nightPurple),
      AvatarPalette.red => (background: AppColors.criticalBackground, foreground: AppColors.criticalRed),
    };
  }

  /// "Tablet · Oral" / "Capsule · Oral" / "Injection · Subcut." label text
  /// for a given [MedicationRoute].
  static String routeLabel(MedicationRoute route) {
    return switch (route) {
      MedicationRoute.tabletOral => 'Tablet · Oral',
      MedicationRoute.capsuleOral => 'Capsule · Oral',
      MedicationRoute.injectionSubcut => 'Injection · Subcut.',
    };
  }

  /// Small glyph shown before a dose card's route label. Tablets reuse the
  /// existing `AppAssets.pill` SVG; capsule and injection/subcutaneous have
  /// no matching export in `assets/icons/{dashboard,common,nav}` and the
  /// Figma asset-download tool is unavailable this round (monthly quota
  /// exhausted), so `Icons.medication_outlined` (capsule) and
  /// `Icons.vaccines_rounded` (syringe) are used as Material placeholders —
  /// see the feature's implementation report.
  static ({String? svgAsset, IconData? materialIcon}) routeIcon(MedicationRoute route) {
    return switch (route) {
      MedicationRoute.tabletOral => (svgAsset: AppAssets.pill, materialIcon: null),
      MedicationRoute.capsuleOral => (svgAsset: null, materialIcon: Icons.medication_outlined),
      MedicationRoute.injectionSubcut => (svgAsset: null, materialIcon: Icons.vaccines_rounded),
    };
  }

  const StaffMedicationConstants._();
}
