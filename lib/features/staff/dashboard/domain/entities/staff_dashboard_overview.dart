import 'package:flutter/foundation.dart';

import 'staff_overview_stat.dart';
import 'staff_quick_action.dart';
import 'today_shift_summary.dart';

/// Aggregate root for everything shown on the Staff Dashboard ("Home")
/// screen.
@immutable
class StaffDashboardOverview {
  final String organizationName;
  final String dateLabel;
  final String greetingLine;
  final String greetingSubtitle;
  final int unreadNotificationCount;
  final TodayShiftSummary todayShift;
  final List<StaffOverviewStat> overviewStats;
  final int alertCount;
  final String alertLabel;
  final List<StaffQuickAction> quickActions;

  const StaffDashboardOverview({
    required this.organizationName,
    required this.dateLabel,
    required this.greetingLine,
    required this.greetingSubtitle,
    required this.unreadNotificationCount,
    required this.todayShift,
    required this.overviewStats,
    required this.alertCount,
    required this.alertLabel,
    required this.quickActions,
  });
}
