import 'package:flutter/foundation.dart';

import 'family_attention_alert.dart';
import 'family_overview_stat.dart';

/// Aggregate root for everything shown on the Family Dashboard ("Home")
/// screen.
@immutable
class FamilyDashboardOverview {
  final String residenceName;
  final String dateLabel;
  final String greetingLine;
  final String greetingSubtitle;
  final String lastUpdatedLabel;
  final int unreadNotificationCount;
  final List<FamilyAttentionAlert> attentionAlerts;
  final List<FamilyOverviewStat> overviewStats;

  const FamilyDashboardOverview({
    required this.residenceName,
    required this.dateLabel,
    required this.greetingLine,
    required this.greetingSubtitle,
    required this.lastUpdatedLabel,
    required this.unreadNotificationCount,
    required this.attentionAlerts,
    required this.overviewStats,
  });
}
