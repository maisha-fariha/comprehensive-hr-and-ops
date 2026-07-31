import 'package:gems_core/gems_core.dart';

import '../../domain/entities/family_attention_alert.dart';
import '../../domain/entities/family_dashboard_enums.dart';
import '../../domain/entities/family_dashboard_overview.dart';
import '../../domain/entities/family_overview_stat.dart';
import '../../domain/repositories/family_dashboard_repository.dart';

/// Local implementation of [FamilyDashboardRepository].
///
/// There is no backend endpoint for the Family dashboard summary yet, so
/// this returns the exact static content shown in the reference screenshot.
/// Replace the body of [getOverview] with a real `ApiService`/
/// `BaseRepository` call once an API contract exists - the domain layer and
/// every widget above it will keep working unchanged.
class FamilyDashboardRepositoryImpl implements FamilyDashboardRepository {
  @override
  Future<Result<FamilyDashboardOverview>> getOverview() async {
    return Result.success(
      const FamilyDashboardOverview(
        residenceName: 'Sunrise Home',
        dateLabel: 'Sunday · July 13',
        greetingLine: 'Good morning, Alex 👋',
        greetingSubtitle: "Room 207 | Here's what's happening today.",
        lastUpdatedLabel: 'Updated 9:41 AM',
        unreadNotificationCount: 2,
        attentionAlerts: [
          FamilyAttentionAlert(
            id: 'incident-room-4b',
            title: 'Open incident — Room 4B',
            subtitle: 'High severity · 20 min ago',
            severity: AlertSeverity.critical,
          ),
          FamilyAttentionAlert(
            id: 'night-shift-understaffed',
            title: 'Night shift understaffed',
            subtitle: 'Needs 2 more · starts 11:00 PM',
            severity: AlertSeverity.urgent,
          ),
        ],
        overviewStats: [
          FamilyOverviewStat(
            id: 'staff-on-duty',
            tag: StatTag.active,
            value: '12',
            label: 'Staff On Duty',
            helperText: '↑ +2 more than yesterday',
            isHelperTextPositive: true,
          ),
          FamilyOverviewStat(
            id: 'open-incidents',
            tag: StatTag.urgent,
            value: '3',
            label: 'Open Incidents',
            helperText: 'High priority',
          ),
          FamilyOverviewStat(
            id: 'medications-due',
            tag: StatTag.due,
            value: '2',
            label: 'Medications Due',
            helperText: 'Due by 6:00 PM',
          ),
          FamilyOverviewStat(
            id: 'updates-to-review',
            tag: StatTag.review,
            value: '3',
            label: 'Updates To Review',
            helperText: 'Awaiting your review',
          ),
        ],
      ),
    );
  }
}
