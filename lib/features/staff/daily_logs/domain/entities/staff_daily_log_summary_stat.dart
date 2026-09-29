import 'package:flutter/foundation.dart';

import 'staff_daily_logs_enums.dart';

/// A single summary metric card (web Entries Logged / Days to Review / …).
@immutable
class StaffDailyLogSummaryStat {
  final StaffDailyLogStatTag tag;
  final String value;
  final String label;
  final String? subtitle;

  const StaffDailyLogSummaryStat({
    required this.tag,
    required this.value,
    required this.label,
    this.subtitle,
  });
}
