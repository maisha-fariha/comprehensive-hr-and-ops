import 'package:flutter/foundation.dart';

import 'staff_client_log_entry.dart';
import 'staff_daily_log_summary_stat.dart';
import 'staff_day_log_entry.dart';
import 'staff_house_activity_entry.dart';

/// Aggregate for Staff Daily Logs (web tabs + filters).
@immutable
class StaffDailyLogsOverview {
  final List<StaffDailyLogSummaryStat> stats;
  final List<StaffClientLogEntry> toReview;
  final int toReviewTotal;
  final List<StaffClientLogEntry> missing;
  final int missingTotal;
  final List<StaffDayLogEntry> dayEntries;
  final String? dayClientName;
  final String? dayLogDateLabel;
  final List<StaffHouseActivityEntry> houseActivities;
  final int houseActivitiesTotal;
  final List<({String id, String name})> residents;

  const StaffDailyLogsOverview({
    this.stats = const [],
    this.toReview = const [],
    this.toReviewTotal = 0,
    this.missing = const [],
    this.missingTotal = 0,
    this.dayEntries = const [],
    this.dayClientName,
    this.dayLogDateLabel,
    this.houseActivities = const [],
    this.houseActivitiesTotal = 0,
    this.residents = const [],
  });

  static const empty = StaffDailyLogsOverview();
}
