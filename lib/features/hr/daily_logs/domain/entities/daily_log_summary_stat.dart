import 'package:flutter/foundation.dart';

import 'daily_logs_enums.dart';

/// A single tile in the "3 stat tiles" row shown at the top of every Daily
/// Logs tab, e.g. "12 Submitted Today" or "2 Flagged Notes".
@immutable
class DailyLogSummaryStat {
  final DailyLogStatTag tag;
  final String value;
  final String label;

  /// Whether this tile should render the distinct dashed-border highlight
  /// treatment (only "Flagged Notes" on the Review tab, per the reference
  /// screenshot).
  final bool isHighlighted;

  const DailyLogSummaryStat({
    required this.tag,
    required this.value,
    required this.label,
    this.isHighlighted = false,
  });
}
