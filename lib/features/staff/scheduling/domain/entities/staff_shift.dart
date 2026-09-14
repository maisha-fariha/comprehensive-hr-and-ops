import 'package:flutter/foundation.dart';

import '../../../staff_core_constants.dart';
import 'shift_avatar.dart';

/// A single card in "My Schedule"'s "My Shifts" list.
@immutable
class StaffShift {
  final String id;
  final String title;
  final bool isToday;
  final String dateTimeLabel;
  final String location;
  final List<ShiftAvatar> avatars;
  final int extraStaffCount;
  final int filled;
  final int total;
  /// Remaining open slots from API `openCount`, else `total - filled`.
  final int openSlots;
  final String roleTag;
  final String statusLabel;
  final StaffingLevel staffingLevel;
  final DateTime? startAt;

  const StaffShift({
    required this.id,
    required this.title,
    required this.isToday,
    required this.dateTimeLabel,
    required this.location,
    required this.avatars,
    required this.extraStaffCount,
    required this.filled,
    required this.total,
    required this.openSlots,
    required this.roleTag,
    required this.statusLabel,
    required this.staffingLevel,
    this.startAt,
  });
}
