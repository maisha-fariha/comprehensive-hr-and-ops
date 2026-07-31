import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Local design tokens for the Attendance feature that aren't already
/// covered by `lib/core/constants`. These were eyeballed from reference
/// screenshots (no Figma access at implementation time - see the
/// `figures/README` note in the final report) and should be reconciled
/// against the real Figma file once MCP quota resets.
abstract final class AttendanceDimens {
  // Stat tile row (4-up on "Today", 3-up on "Late"/"Missed"/"OT").
  static const double statTileHeight = 92;
  static const double statValueFontSize = 19;
  static const double statLabelFontSize = 10.5;

  // Segmented tab bar.
  static const double tabBarHeight = 40;
  static const double tabBarRadius = 13;

  // Header icon buttons (hamburger / calendar).
  static const double headerIconButtonSize = 38;

  // Cards (staff / late-arrival / missed / overtime).
  static const double avatarSize = 42;
  static const double progressBarHeight = 6;

  const AttendanceDimens._();
}

/// A background/foreground color pairing used to tint the initials avatar
/// shown on every Attendance list row/card.
class AttendanceAvatarPalette {
  final Color background;
  final Color foreground;

  const AttendanceAvatarPalette({required this.background, required this.foreground});
}

/// Rotating avatar palette reused from existing semantic color tokens
/// (`AppColors`) so no genuinely new colors are introduced just for
/// avatar tinting.
const List<AttendanceAvatarPalette> attendanceAvatarPalette = [
  AttendanceAvatarPalette(background: AppColors.nightBackground, foreground: AppColors.nightPurple),
  AttendanceAvatarPalette(background: AppColors.activeBackground, foreground: AppColors.activeGreen),
  AttendanceAvatarPalette(background: AppColors.infoBackground, foreground: AppColors.infoBlue),
  AttendanceAvatarPalette(background: AppColors.urgentBackground, foreground: AppColors.urgentAmber),
  AttendanceAvatarPalette(background: AppColors.criticalBackgroundSoft, foreground: AppColors.criticalRed),
];
