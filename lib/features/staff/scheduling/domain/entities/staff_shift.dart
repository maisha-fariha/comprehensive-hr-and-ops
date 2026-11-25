import 'package:flutter/foundation.dart';

import '../../../../../core/time/tenant_clock.dart';
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

  /// Raw API `status` (`published`, `cancelled`, …).
  final String apiStatus;
  final StaffingLevel staffingLevel;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? residenceId;
  final List<String> staffIds;

  /// Pending open-shift bids count when API includes `bids` / `bid_pending`.
  final int pendingBidCount;

  /// True when the signed-in staff already has a pending bid on this open shift.
  final bool ownBidPending;

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
    this.apiStatus = '',
    this.startAt,
    this.endAt,
    this.residenceId,
    this.staffIds = const [],
    this.pendingBidCount = 0,
    this.ownBidPending = false,
  });

  /// Web "Shifts you can swap" / Request swap: future start, not cancelled.
  ///
  /// Matches `cancelled !== status && new Date(startsAt) > Date.now()`.
  bool get canRequestSwap {
    final start = startAt;
    if (start == null || !start.isAfter(TenantClock.now())) return false;
    final status = apiStatus.toLowerCase();
    return status != 'cancelled' && status != 'canceled';
  }
}
