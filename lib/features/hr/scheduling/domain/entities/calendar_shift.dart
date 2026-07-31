import 'package:flutter/foundation.dart';

import 'scheduling_enums.dart';
import 'staff_avatar.dart';

/// A single shift card in the Calendar tab's daily timeline, e.g. the
/// "Morning Shift" block running 7:00 AM – 3:00 PM.
@immutable
class CalendarShift {
  final String id;
  final String startTime;
  final String startPeriod;
  final String name;
  final String timeRange;
  final int filled;
  final int total;
  final CoverageStatus status;
  final List<StaffAvatar> avatars;
  final String namesSummary;

  /// e.g. "2 open · RN" — null when the shift has no unfilled roles left
  /// to call out (e.g. the Night shift in the Figma design).
  final String? openPositionsLabel;

  /// Whether the connecting timeline divider should render below this row
  /// (true for every row except the last).
  final bool showTimelineDivider;

  const CalendarShift({
    required this.id,
    required this.startTime,
    required this.startPeriod,
    required this.name,
    required this.timeRange,
    required this.filled,
    required this.total,
    required this.status,
    required this.avatars,
    required this.namesSummary,
    this.openPositionsLabel,
    this.showTimelineDivider = true,
  });
}
