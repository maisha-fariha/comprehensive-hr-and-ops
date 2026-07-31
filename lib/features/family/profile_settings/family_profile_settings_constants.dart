import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import 'domain/entities/family_preference_item.dart';

/// Design tokens specific to the Family "Profile & Settings" feature that
/// don't belong in `lib/core/constants` (which is shared across every
/// feature and must not be edited by this feature). Colors already present
/// in `AppColors` are reused directly rather than introducing new values,
/// except for the profile avatar tint below which has no close existing
/// match.
abstract final class FamilyProfileSettingsConstants {
  /// Background/foreground for the own-profile "EJ" avatar. The reference
  /// screenshot's salmon/pink tone doesn't closely match any existing
  /// `AppColors` status pair, and the exact Figma value can't be sampled
  /// this round (MCP quota exhausted), so this is a close visual
  /// approximation kept local to this feature.
  static const Color profileAvatarBackground = Color(0xFFF7DCD4);
  static const Color profileAvatarForeground = Color(0xFFC1604A);

  /// Background/foreground for a linked-client "JD" avatar. Reuses the
  /// shared "info" blue tint, matching the reference screenshot exactly.
  static const Color linkedClientAvatarBackground = AppColors.infoBackground;
  static const Color linkedClientAvatarForeground = AppColors.infoBlue;

  /// Icon-box background/foreground shared by every "Preferences & Support"
  /// row. Reuses the shared "active" mint/teal tint.
  static const Color preferenceIconBackground = AppColors.activeIconBackground;
  static const Color preferenceIconForeground = AppColors.secondaryTeal;

  /// Glyph shown inside a "Preferences & Support" row's icon box.
  ///
  /// [FamilyPreferenceType.notifications] and [FamilyPreferenceType.contactSupport]
  /// reuse the existing `AppAssets.bell`/`AppAssets.messageCircle` SVGs.
  /// [FamilyPreferenceType.helpCenter] and [FamilyPreferenceType.privacySecurity]
  /// have no matching export under `assets/icons/{dashboard,common,nav}`
  /// and the Figma asset-download tool is unavailable this round (monthly
  /// quota exhausted), so `Icons.help_outline_rounded` and
  /// `Icons.shield_outlined` are used as Material placeholders — see the
  /// feature's implementation report for the full list of substitutions.
  static ({String? svgAsset, IconData? materialIcon}) preferenceIcon(FamilyPreferenceType type) {
    return switch (type) {
      FamilyPreferenceType.notifications => (svgAsset: AppAssets.bell, materialIcon: null),
      FamilyPreferenceType.helpCenter => (svgAsset: null, materialIcon: Icons.help_outline_rounded),
      FamilyPreferenceType.contactSupport => (svgAsset: AppAssets.messageCircle, materialIcon: null),
      FamilyPreferenceType.privacySecurity => (svgAsset: null, materialIcon: Icons.shield_outlined),
    };
  }

  const FamilyProfileSettingsConstants._();
}
