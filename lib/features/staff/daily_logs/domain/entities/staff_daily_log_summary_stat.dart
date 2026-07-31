import 'package:flutter/foundation.dart';

import 'staff_daily_logs_enums.dart';

/// A single tile in the "3 stat tiles" row shown at the top of every Staff
/// Daily Logs tab, e.g. "12 Submitted Today" or "2 Flagged Notes".
@immutable
class StaffDailyLogSummaryStat {
  final StaffDailyLogStatTag tag;
  final String value;
  final String label;

  const StaffDailyLogSummaryStat({
    required this.tag,
    required this.value,
    required this.label,
  });
}
