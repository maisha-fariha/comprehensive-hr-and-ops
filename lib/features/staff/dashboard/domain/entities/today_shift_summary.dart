import 'package:flutter/foundation.dart';

/// The floating "Today's Shift" card overlapping the Staff Dashboard's
/// gradient header. Values come from `GET /mobile/home` → `shift` /
/// `attendance`.
@immutable
class TodayShiftSummary {
  final String statusLabel;
  final String dateLabel;
  final String timeRange;
  final bool onShift;

  /// Open punch. Clock out is only offered when this is true; a rostered
  /// shift that has not been clocked into stays a clock-in.
  final bool clockedIn;
  final bool onBreak;
  final String? shiftId;
  final String? residenceId;

  /// True once clock-in has opened (15 minutes before the shift) through
  /// the shift end, or the person is already clocked in.
  final bool clockOpen;

  /// Start of the shift shown on the card. Used when clock-in is not open yet.
  final DateTime? startsAt;

  /// Scheduled end of today's shift. Clock-out uses this for the web
  /// "Your shift runs until …" early-leave box.
  final DateTime? endsAt;

  const TodayShiftSummary({
    required this.statusLabel,
    required this.dateLabel,
    required this.timeRange,
    this.onShift = false,
    this.clockedIn = false,
    this.onBreak = false,
    this.shiftId,
    this.residenceId,
    this.clockOpen = false,
    this.startsAt,
    this.endsAt,
  });
}
