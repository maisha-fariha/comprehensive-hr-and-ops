import 'package:flutter/foundation.dart';

/// The floating "Today's Shift" card overlapping the Staff Dashboard's
/// gradient header.
@immutable
class TodayShiftSummary {
  final String statusLabel;
  final String dateLabel;
  final String timeRange;

  const TodayShiftSummary({
    required this.statusLabel,
    required this.dateLabel,
    required this.timeRange,
  });
}
