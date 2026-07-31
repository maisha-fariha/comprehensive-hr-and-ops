import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';

/// Icon references for the Attendance feature.
///
/// Every icon below is an *existing* Figma-exported SVG already registered
/// in [AppAssets] and shared with the Dashboard feature - no new SVGs were
/// added to `assets/icons/attendance/` because the Figma MCP tool-call
/// quota was exhausted before any could be exported (see
/// [AttendanceMaterialIconFallback] for the icons that still need real
/// exported SVGs once quota resets).
abstract final class AttendanceAssets {
  static const String onTime = AppAssets.checkCircle;
  static const String late = AppAssets.clock;
  static const String missed = AppAssets.circleError;
  static const String missedToday = AppAssets.crossCircle;
  static const String onDuty = AppAssets.users;
  static const String critical = AppAssets.alertTriangle;
  static const String calendar = AppAssets.navCalendar;
  static const String avgDelay = AppAssets.timer;
  static const String approachingLimit = AppAssets.approaching;


  const AttendanceAssets._();
}

/// TEMPORARY Material Icon stand-ins for glyphs that appear in the
/// reference screenshots but have no matching SVG already exported into
/// `assets/icons/dashboard`, `assets/icons/nav`, or `assets/icons/common`.
///
/// These MUST be swapped for real Figma-exported SVGs (rendered via
/// [AppSvgIcon]) once the Figma MCP quota resets - see the final report for
/// the full list and where each one is used.
abstract final class AttendanceMaterialIconFallback {
  /// Header hamburger / menu button.
  static const IconData menu = Icons.menu_rounded;

  /// "On Site · x ft" location pin (Today staff rows, Late arrival cards).
  static const IconData locationPin = Icons.location_on_outlined;

  /// Overflow "···" affordance shown instead of a clock-in time on a
  /// missed row in the "Today" tab.
  static const IconData overflowMenu = Icons.more_horiz_rounded;

  /// "No Clock-In" prohibition glyph (Today missed row + Missed tab pill).
  static const IconData noClockIn = Icons.block_rounded;

  /// "Needs Review" stat tile icon (Missed tab).
  static const IconData needsReview = Icons.visibility_outlined;

  /// "Avg Delay" stat tile icon (Late tab).
  static const IconData avgDelay = Icons.hourglass_bottom_rounded;

  /// "Approaching" (overtime limit) stat tile icon (OT tab).
  static const IconData approachingLimit = Icons.speed_rounded;

  const AttendanceMaterialIconFallback._();
}
