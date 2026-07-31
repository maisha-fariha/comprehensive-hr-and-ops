import 'package:flutter/foundation.dart';

import 'scheduling_enums.dart';
import 'staff_avatar.dart';

/// A single detailed shift card in the Board tab's "Coverage Board" list.
@immutable
class BoardShift {
  final String id;
  final String periodLabel;
  final String timeRange;
  final int filled;
  final int total;
  final CoverageStatus status;
  final String statusLabel;
  final List<StaffAvatar> avatars;
  final int extraStaffCount;
  final List<String> roleChips;

  /// e.g. "2 RN needed".
  final String neededLabel;

  const BoardShift({
    required this.id,
    required this.periodLabel,
    required this.timeRange,
    required this.filled,
    required this.total,
    required this.status,
    required this.statusLabel,
    required this.avatars,
    required this.extraStaffCount,
    required this.roleChips,
    required this.neededLabel,
  });
}
