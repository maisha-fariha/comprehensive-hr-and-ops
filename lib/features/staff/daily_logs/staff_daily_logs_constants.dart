import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A background/foreground color pair used to tint an initials avatar or a
/// form-field icon circle.
class AvatarColorPair {
  final Color background;
  final Color foreground;

  const AvatarColorPair(this.background, this.foreground);
}

/// Design tokens used by the Staff Daily Logs feature that are NOT already
/// covered by `lib/core/constants`. These were eyeballed from reference
/// screenshots (no live Figma pixel access was available while building
/// this feature) - see the implementation report for details on what
/// should be re-verified once Figma access is restored.
abstract final class StaffDailyLogsConstants {
  /// Teal tint used for the tab bar's inactive-segment count pills
  /// (e.g. the "8" / "2" / "5" badges next to "My Clients" / "In Progress"
  /// / "Submitted").
  static const Color tabBadgeBackground = AppColors.quickActionCreateShiftBg;
  static const Color tabBadgeForeground = AppColors.secondaryTeal;

  /// Rose tint used for the "Behavior" form-field icon circle and as the
  /// 4th color in the avatar palette below (every other color in the
  /// palette reuses an existing `AppColors` pair).
  static const Color roseBackground = Color(0xFFFBE7F0);
  static const Color roseForeground = Color(0xFFC2478E);

  /// Cycled through by index for every list of client initials-avatars
  /// across the 3 Daily Logs tabs.
  static const List<AvatarColorPair> avatarPalette = [
    AvatarColorPair(AppColors.infoBackground, AppColors.infoBlue),
    AvatarColorPair(AppColors.urgentIconBackground, AppColors.urgentAmber),
    AvatarColorPair(AppColors.nightBackground, AppColors.nightPurple),
    AvatarColorPair(roseBackground, roseForeground),
    AvatarColorPair(AppColors.activeIconBackground, AppColors.activeGreen),
  ];

  const StaffDailyLogsConstants._();
}
