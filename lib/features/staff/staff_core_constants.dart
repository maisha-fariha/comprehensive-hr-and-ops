import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Local design tokens shared by the 3 Staff-portal screens built in this
/// batch (Dashboard, Scheduling, Attendance). These were eyeballed from a
/// reference screenshot (no Figma MCP access at implementation time — the
/// account's monthly quota was exhausted, see the final report) and should
/// be reconciled against the real Figma file once quota resets.
///
/// Every value that already matched an existing `AppDimens`/`AppColors`
/// token was reused directly at the call site instead of being duplicated
/// here.
abstract final class StaffDimens {
  // Week/day chip (Scheduling).
  static const double dayChipWidth = 42;
  static const double dayChipNumberBoxSize = 32;

  // Shift-card facepile avatars (Scheduling).
  static const double shiftAvatarSize = 30;
  static const double shiftAvatarOverlap = 10;

  // Staffing progress bar height (Scheduling shift cards).
  static const double progressBarHeight = 5;

  // Alerts banner (Dashboard).
  static const double alertAccentBarWidth = 4;
  static const double alertNumberFontSize = 28;

  // Time Worked card (Attendance).
  static const double timerFontSize = 32;
  static const double selfieThumbnailSize = 40;
  static const double geofenceIconBoxSize = 38;

  const StaffDimens._();
}

/// Semantic staffing-health tiers for a Scheduling shift card's progress
/// bar, mirroring the HR Scheduling feature's `CoverageStatus` concept but
/// with a 3-way (not 2-way) split since the reference screenshot shows a
/// well-staffed (green), borderline (amber) and understaffed (red) shift
/// side by side.
enum StaffingLevel { high, medium, low }

class StaffingLevelStyle {
  final Color accent;
  final Color background;

  const StaffingLevelStyle({required this.accent, required this.background});
}

const Map<StaffingLevel, StaffingLevelStyle> staffingLevelStyles = {
  StaffingLevel.high: StaffingLevelStyle(
    accent: AppColors.activeGreen,
    background: AppColors.activeBackground,
  ),
  StaffingLevel.medium: StaffingLevelStyle(
    accent: AppColors.urgentAmber,
    background: AppColors.urgentBackground,
  ),
  StaffingLevel.low: StaffingLevelStyle(
    accent: AppColors.criticalRed,
    background: AppColors.criticalBackground,
  ),
};

/// A background/foreground color pairing used to tint a shift facepile's
/// initials avatar. Reused from existing semantic `AppColors` tokens (same
/// approach as the HR Attendance feature's `attendanceAvatarPalette`) so no
/// genuinely new colors are introduced just for avatar tinting.
class StaffAvatarPalette {
  final Color background;
  final Color foreground;

  const StaffAvatarPalette({required this.background, required this.foreground});
}

const List<StaffAvatarPalette> staffAvatarPalette = [
  StaffAvatarPalette(background: AppColors.nightBackground, foreground: AppColors.nightPurple),
  StaffAvatarPalette(background: AppColors.activeBackground, foreground: AppColors.activeGreen),
  StaffAvatarPalette(background: AppColors.infoBackground, foreground: AppColors.infoBlue),
  StaffAvatarPalette(background: AppColors.urgentBackground, foreground: AppColors.urgentAmber),
  StaffAvatarPalette(background: AppColors.criticalBackgroundSoft, foreground: AppColors.criticalRed),
];

/// TEMPORARY Material Icon stand-ins for glyphs that appear in the
/// reference screenshot but have no matching SVG already exported into
/// `assets/icons/dashboard`, `assets/icons/nav`, or `assets/icons/common`.
///
/// These MUST be swapped for real Figma-exported SVGs (rendered via
/// `AppSvgIcon`) once the Figma MCP quota resets — see the final report for
/// the full list and where each one is used.
abstract final class StaffMaterialIconFallback {
  /// Header back chevron (Scheduling + Attendance) is instead built by
  /// rotating the existing `AppAssets.chevronRight` SVG 180°, mirroring the
  /// HR Scheduling feature's `SchedulingAssets.monthChevron` convention —
  /// so no Material fallback is needed for it.

  /// Org-switcher "swap organization" glyph (Dashboard header pill).
  static const IconData orgSwitch = Icons.sync_rounded;

  /// Circular profile avatar glyph (Dashboard header + Attendance selfie
  /// thumbnail) — the reference shows a plain generic silhouette rather
  /// than initials.
  static const IconData personAvatar = Icons.person_rounded;

  /// "📍 Sunrise Home" location-pin glyph (Scheduling shift cards).
  static const IconData locationPin = Icons.location_on_rounded;

  /// "☕ Start Break" glyph (Attendance).
  static const IconData coffeeBreak = Icons.local_cafe_outlined;

  /// "➡ Clock Out" glyph (Attendance).
  static const IconData clockOutArrow = Icons.arrow_forward_rounded;

  const StaffMaterialIconFallback._();
}
