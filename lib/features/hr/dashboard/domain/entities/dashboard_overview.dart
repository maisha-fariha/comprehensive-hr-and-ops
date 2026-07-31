import 'package:flutter/foundation.dart';

import 'attention_alert.dart';
import 'overview_stat.dart';
import 'quick_action.dart';
import 'schedule_shift.dart';

/// Aggregate root for everything shown on the HR/Manager Dashboard screen.
@immutable
class DashboardOverview {
  final String organizationName;
  final String dateLabel;
  final String greetingLine;
  final String greetingSubtitle;
  final String lastUpdatedLabel;
  final int unreadNotificationCount;
  final int unresolvedAlertCount;
  final String avatarInitials;
  final List<AttentionAlert> attentionAlerts;
  final List<OverviewStat> overviewStats;
  final List<ScheduleShift> scheduleShifts;
  final List<QuickAction> quickActions;

  const DashboardOverview({
    required this.organizationName,
    required this.dateLabel,
    required this.greetingLine,
    required this.greetingSubtitle,
    required this.lastUpdatedLabel,
    required this.unreadNotificationCount,
    required this.unresolvedAlertCount,
    required this.avatarInitials,
    required this.attentionAlerts,
    required this.overviewStats,
    required this.scheduleShifts,
    required this.quickActions,
  });
}
