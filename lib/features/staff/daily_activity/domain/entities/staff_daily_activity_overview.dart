import 'package:flutter/foundation.dart';

import 'staff_daily_activity_item.dart';
import 'staff_daily_activity_metrics.dart';

/// Aggregate for the Daily Activity screen.
@immutable
class StaffDailyActivityOverview {
  final StaffDailyActivityMetrics metrics;
  final List<StaffDailyActivityItem> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const StaffDailyActivityOverview({
    this.metrics = StaffDailyActivityMetrics.empty,
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  static const empty = StaffDailyActivityOverview();
}
