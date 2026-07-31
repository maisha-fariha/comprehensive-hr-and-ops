import 'package:flutter/foundation.dart';

import 'attendance_enums.dart';

/// A single row in the "Today" tab's "Staff Status" list.
@immutable
class StaffStatusEntry {
  final String id;
  final String name;
  final String initials;
  final int avatarPaletteIndex;
  final StaffAttendanceStatus status;

  /// "On Site · 200 ft" for on-time/late staff, or "No clock in" when
  /// [status] is [StaffAttendanceStatus.missed].
  final String secondaryText;

  /// Clock-in timestamp, e.g. "7:01 AM". Null when [status] is
  /// [StaffAttendanceStatus.missed] (an overflow affordance is shown
  /// instead).
  final String? timeLabel;

  const StaffStatusEntry({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarPaletteIndex,
    required this.status,
    required this.secondaryText,
    this.timeLabel,
  });
}
