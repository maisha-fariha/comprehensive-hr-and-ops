import 'package:gems_core/gems_core.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../domain/entities/staff_dashboard_enums.dart';
import '../../domain/entities/staff_dashboard_overview.dart';
import '../../domain/entities/staff_overview_stat.dart';
import '../../domain/entities/staff_quick_action.dart';
import '../../domain/entities/today_shift_summary.dart';
import '../../domain/repositories/staff_dashboard_repository.dart';

/// Local implementation of [StaffDashboardRepository].
///
/// There is no backend endpoint for the staff dashboard summary yet, so
/// this returns the exact static content shown in the reference
/// screenshot. Replace the body of [getOverview] with a real
/// `ApiService`/`BaseRepository` call once an API contract exists — the
/// domain layer and every widget above it will keep working unchanged.
class StaffDashboardRepositoryImpl implements StaffDashboardRepository {
  @override
  Future<Result<StaffDashboardOverview>> getOverview() async {
    return Result.success(
      const StaffDashboardOverview(
        organizationName: 'Sunrise Home',
        dateLabel: 'Sunday · July 13',
        greetingLine: 'Good morning, Sarah 👋',
        greetingSubtitle: "Here's what's happening on your shift.",
        unreadNotificationCount: 1,
        todayShift: TodayShiftSummary(
          statusLabel: 'On Shift',
          dateLabel: 'May 12, 2025',
          timeRange: '7:00 AM – 3:00 PM',
        ),
        overviewStats: [
          StaffOverviewStat(
            id: 'on-shift',
            tag: StaffStatTag.onShift,
            value: 'On Shift',
            label: 'My Shift',
          ),
          StaffOverviewStat(
            id: 'clients-assigned',
            tag: StaffStatTag.clients,
            value: '8',
            label: 'Clients Assigned',
          ),
          StaffOverviewStat(
            id: 'tasks-due',
            tag: StaffStatTag.tasks,
            value: '6',
            label: 'Tasks Due',
          ),
          StaffOverviewStat(
            id: 'medications-due',
            tag: StaffStatTag.medications,
            value: '4',
            label: 'Medications Due',
          ),
        ],
        alertCount: 2,
        alertLabel: 'Alerts',
        quickActions: [
          StaffQuickAction(id: 'log-task', asset: AppAssets.notePencil, label: 'Log Task'),
          StaffQuickAction(id: 'message', asset: AppAssets.messageCircle, label: 'Message'),
          StaffQuickAction(id: 'mark-done', asset: AppAssets.checkCircle, label: 'Mark Done'),
        ],
      ),
    );
  }
}
