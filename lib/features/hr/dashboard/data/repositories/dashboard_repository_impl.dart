import 'package:gems_core/gems_core.dart';

import '../../domain/entities/attention_alert.dart';
import '../../domain/entities/dashboard_enums.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/entities/overview_stat.dart';
import '../../domain/entities/quick_action.dart';
import '../../domain/entities/schedule_shift.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// Local implementation of [DashboardRepository].
///
/// There is no backend endpoint for the dashboard summary yet, so this
/// returns the exact static content shown in the Figma design. Replace the
/// body of [getOverview] with a real `ApiService`/`BaseRepository` call
/// (see `flutter_gems/lib/repositories/todo_repository.dart` for the
/// established pattern) once an API contract exists - the domain layer and
/// every widget above it will keep working unchanged.
class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<Result<DashboardOverview>> getOverview() async {
    return Result.success(
      const DashboardOverview(
        organizationName: 'Sunrise Home',
        dateLabel: "Sunday · July 13",
        greetingLine: 'Good morning, Alex 👋',
        greetingSubtitle: "Here's what's happening today.",
        lastUpdatedLabel: 'Updated 9:41 AM',
        unreadNotificationCount: 2,
        unresolvedAlertCount: 3,
        avatarInitials: 'AL',
        attentionAlerts: [
          AttentionAlert(
            id: 'incident-room-4b',
            title: 'Open incident — Room 4B',
            subtitle: 'High severity · 20 min ago',
            severity: AlertSeverity.critical,
          ),
          AttentionAlert(
            id: 'night-shift-understaffed',
            title: 'Night shift understaffed',
            subtitle: 'Needs 2 more · starts 11:00 PM',
            severity: AlertSeverity.urgent,
          ),
        ],
        overviewStats: [
          OverviewStat(
            id: 'staff-on-duty',
            tag: StatTag.active,
            value: '12',
            label: 'Staff On Duty',
            helperText: '↑ +2 more than yesterday',
            isHelperTextPositive: true,
          ),
          OverviewStat(
            id: 'open-incidents',
            tag: StatTag.urgent,
            value: '3',
            label: 'Open Incidents',
            helperText: 'High priority',
          ),
          OverviewStat(
            id: 'medications-due',
            tag: StatTag.due,
            value: '5',
            label: 'Medications Due',
            helperText: 'Due within 4 hours',
          ),
          OverviewStat(
            id: 'pending-approvals',
            tag: StatTag.review,
            value: '4',
            label: 'Pending Approvals',
            helperText: 'Requires your action',
          ),
          OverviewStat(
            id: 'tasks-due',
            tag: StatTag.today,
            value: '8',
            label: 'Tasks Due',
            helperText: 'Across all clients',
          ),
          OverviewStat(
            id: 'attendance-alerts',
            tag: StatTag.flagged,
            value: '2',
            label: 'Attendance Alerts',
            helperText: 'Needs attention',
          ),
        ],
        scheduleShifts: [
          ScheduleShift(
            id: 'morning-shift',
            period: ShiftPeriod.morning,
            name: 'Morning Shift',
            timeRange: '7:00 AM – 3:00 PM',
            staffCount: 12,
          ),
          ScheduleShift(
            id: 'evening-shift',
            period: ShiftPeriod.evening,
            name: 'Evening Shift',
            timeRange: '3:00 PM – 11:00 PM',
            staffCount: 9,
          ),
          ScheduleShift(
            id: 'night-shift',
            period: ShiftPeriod.night,
            name: 'Night Shift',
            timeRange: '11:00 PM – 7:00 AM',
            staffCount: 8,
            showTimelineDivider: false,
          ),
        ],
        quickActions: [
          QuickAction(type: QuickActionType.createShift, label: 'Create Shift'),
          QuickAction(type: QuickActionType.approve, label: 'Approve'),
          QuickAction(type: QuickActionType.logNote, label: 'Log Note'),
          QuickAction(type: QuickActionType.message, label: 'Message'),
        ],
      ),
    );
  }
}
