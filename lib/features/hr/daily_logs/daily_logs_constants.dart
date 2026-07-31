import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A background/foreground color pair used to tint an initials avatar.
class AvatarColorPair {
  final Color background;
  final Color foreground;

  const AvatarColorPair(this.background, this.foreground);
}

/// Design tokens used by the Daily Logs feature that are NOT already covered
/// by `lib/core/constants`. These were eyeballed from reference screenshots
/// (no live Figma pixel access was available while building this screen) -
/// see the implementation report for details on what should be re-verified
/// once Figma access is restored.
abstract final class DailyLogsConstants {
  /// Dashed highlight border color used on the "Flagged Notes" summary tile.
  static const Color flaggedHighlightBorder = Color(0xFF3B82F6);

  /// Rose avatar tint (4th color in the initials-avatar palette; every other
  /// color in the palette below reuses an existing `AppColors` pair).
  static const Color avatarRoseBackground = Color(0xFFFBE7F0);
  static const Color avatarRoseForeground = Color(0xFFC2478E);

  /// Width of the colored accent bar on the left edge of a handover card.
  static const double handoverAccentBarWidth = 3;

  /// Cycled through by index for every list of initials-avatars (submitted
  /// logs, handover from/to). Reuses existing status colors wherever the
  /// tone already exists in `AppColors`.
  static const List<AvatarColorPair> avatarPalette = [
    AvatarColorPair(AppColors.infoBackground, AppColors.infoBlue),
    AvatarColorPair(AppColors.activeBackground, AppColors.activeGreen),
    AvatarColorPair(AppColors.nightBackground, AppColors.nightPurple),
    AvatarColorPair(avatarRoseBackground, avatarRoseForeground),
  ];

  const DailyLogsConstants._();
}
