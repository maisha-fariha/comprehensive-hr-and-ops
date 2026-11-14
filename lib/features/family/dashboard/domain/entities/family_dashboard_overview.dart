import 'package:flutter/foundation.dart';

import 'family_attention_alert.dart';
import 'family_glance_item.dart';
import 'family_next_appointment.dart';
import 'family_overview_stat.dart';
import 'family_quick_action.dart';
import 'family_recent_update.dart';
import 'family_shared_activity.dart';

/// Aggregate root for Family Overview (web `/family`).
@immutable
class FamilyDashboardOverview {
  final String residenceName;
  final String careFacilityName;
  final String dateLabel;
  final String greetingLine;
  final String greetingSubtitle;
  final String lastUpdatedLabel;
  final int unreadNotificationCount;
  final List<FamilyAttentionAlert> attentionAlerts;
  final List<FamilyOverviewStat> overviewStats;
  final FamilyNextAppointment? nextAppointment;
  final FamilyRecentUpdate? recentUpdate;
  final List<FamilyGlanceItem> glanceItems;
  final List<FamilyQuickAction> quickActions;
  /// Linked residents shown on web Overview ("Relative:").
  final List<({String id, String name, String residenceName, String? room, String status})>
      linkedClients;
  final String selectedClientId;
  final bool careJournalActiveToday;
  final String? careJournalLastNoted;
  final List<FamilySharedActivity> sharedActivities;

  const FamilyDashboardOverview({
    required this.residenceName,
    required this.careFacilityName,
    required this.dateLabel,
    required this.greetingLine,
    required this.greetingSubtitle,
    required this.lastUpdatedLabel,
    required this.unreadNotificationCount,
    required this.attentionAlerts,
    required this.overviewStats,
    this.nextAppointment,
    this.recentUpdate,
    this.glanceItems = const [],
    this.quickActions = const [],
    this.linkedClients = const [],
    this.selectedClientId = '',
    this.careJournalActiveToday = false,
    this.careJournalLastNoted,
    this.sharedActivities = const [],
  });

  ({String id, String name, String residenceName, String? room, String status})?
      get selectedClient {
    for (final c in linkedClients) {
      if (c.id == selectedClientId) return c;
    }
    return linkedClients.isEmpty ? null : linkedClients.first;
  }
}
