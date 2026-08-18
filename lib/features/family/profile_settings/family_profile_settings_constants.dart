import 'package:flutter/material.dart';

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
  static const Color profileAvatarBackground = Color(0xFFEBCABF);
  static const Color profileAvatarForeground = Color(0xFF8D5F4D);

  /// Background/foreground for a linked-client "JD" avatar. Reuses the
  /// shared "info" blue tint, matching the reference screenshot exactly.
  static const Color linkedClientAvatarBackground = AppColors.infoBackground;
  static const Color linkedClientAvatarForeground = AppColors.infoBlue;

  /// Icon-box background/foreground shared by every "Preferences & Support"
  /// row. Reference uses a pale mint box with teal outline glyphs.
  static const Color preferenceIconBackground = Color(0xFFEFF6F4);
  static const Color preferenceIconForeground = Color(0xFF0E7C7B);

  static const String _moreIcons = 'assets/icons/family_more';

  /// Glyph shown inside a "Preferences & Support" row's icon box.
  /// All assets live under [assets/icons/family_more].
  static String preferenceIconAsset(FamilyPreferenceType type) {
    return switch (type) {
      FamilyPreferenceType.notifications => '$_moreIcons/notification.svg',
      FamilyPreferenceType.helpCenter => '$_moreIcons/help.svg',
      FamilyPreferenceType.contactSupport => '$_moreIcons/message.svg',
      FamilyPreferenceType.privacySecurity => '$_moreIcons/shield_outlined.svg',
    };
  }

  const FamilyProfileSettingsConstants._();
}
