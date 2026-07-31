import 'package:flutter/foundation.dart';

import 'dashboard_enums.dart';

/// A single row in the "Today's Schedule" timeline, e.g. the morning shift
/// with its assigned staff count.
@immutable
class ScheduleShift {
  final String id;
  final ShiftPeriod period;
  final String name;
  final String timeRange;
  final int staffCount;

  /// Whether the connecting timeline divider should render below this row
  /// (true for every row except the last).
  final bool showTimelineDivider;

  const ScheduleShift({
    required this.id,
    required this.period,
    required this.name,
    required this.timeRange,
    required this.staffCount,
    this.showTimelineDivider = true,
  });
}
