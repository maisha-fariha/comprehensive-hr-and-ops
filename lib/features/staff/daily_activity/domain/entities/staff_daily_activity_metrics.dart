import 'package:flutter/foundation.dart';

/// KPI cards from `GET /client-activities` `meta.summary`.
@immutable
class StaffDailyActivityMetrics {
  final int todaysActivities;
  final int activeClients;
  final int staffEntries;
  final int pendingReview;

  const StaffDailyActivityMetrics({
    this.todaysActivities = 0,
    this.activeClients = 0,
    this.staffEntries = 0,
    this.pendingReview = 0,
  });

  static const empty = StaffDailyActivityMetrics();
}
