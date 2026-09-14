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
  final bool onBreak;
  final String? shiftId;
  final String? residenceId;

  const TodayShiftSummary({
    required this.statusLabel,
    required this.dateLabel,
    required this.timeRange,
    this.onShift = false,
    this.onBreak = false,
    this.shiftId,
    this.residenceId,
  });
}
