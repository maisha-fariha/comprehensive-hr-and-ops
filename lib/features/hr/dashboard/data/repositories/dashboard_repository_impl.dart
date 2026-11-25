import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../mappers/dashboard_overview_mapper.dart';

/// Manager dashboard: composes session data with
/// `/dashboard`, `/dashboard/alerts`, `/notifications`, and the signed-in
/// user's attendance / shifts for the personal "Today's Shift" card.
///
/// Quick Actions are static shortcuts (not API-driven). Today's Schedule /
/// `/shifts` for the home list is not fetched for the current Home layout.
class DashboardRepositoryImpl implements DashboardRepository {
  final AppApiClient _api;
  final UserSession _session;

  DashboardRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<DashboardOverview>> getOverview() async {
    // Web Home is tenant-wide unless the user picks a residence filter.
    // Do not inject session.residenceId — that silently scopes nurse/manager
    // home houses differently and hides alerts the web still shows.
    final canNeedsAttention = _session.can('incidents:read') ||
        _session.can('documents:read') ||
        _session.canAccessDocuments;
    final canAttendance = _session.can('attendance:read') ||
        _session.can('attendance:write');
    final staffId = (_session.staffId ?? '').trim();
    final now = DateTime.now().toUtc();

    final results = await Future.wait([
      _api.get(ApiEndpoints.dashboard),
      if (canNeedsAttention)
        _api.get(ApiEndpoints.dashboardAlerts, silent: true)
      else
        Future.value(Result.success(const {'data': <dynamic>[]})),
      _api.get(
        ApiEndpoints.notifications,
        query: const {'page': 1, 'limit': 30},
        silent: true,
      ),
      if (canAttendance)
        _api.get(
          ApiEndpoints.attendance,
          query: {
            'mine': true,
            'from': now.subtract(const Duration(hours: 48)).toIso8601String(),
            'to': now.add(const Duration(hours: 1)).toIso8601String(),
            'limit': 50,
          },
          silent: true,
        )
      else
        Future.value(Result.success(const {'data': <dynamic>[]})),
      if (canAttendance && staffId.isNotEmpty)
        _api.get(
          ApiEndpoints.shifts,
          query: {
            'staffId': staffId,
            'limit': 20,
            'from': now.subtract(const Duration(hours: 14)).toIso8601String(),
            'to': now.add(const Duration(hours: 14)).toIso8601String(),
          },
          silent: true,
        )
      else
        Future.value(Result.success(const {'data': <dynamic>[]})),
    ]);

    final dashboard = results[0];
    if (dashboard.isFailure) {
      return Result.failure(
        dashboard.error ??
            const ApiError(message: 'Could not load the dashboard.'),
      );
    }

    // Alerts / personal shift feeds are optional — missing permission / 403
    // must not blank Home.
    final alertsBody = results[1].isSuccess
        ? results[1].value
        : const {'data': <dynamic>[]};
    final myAttendance =
        results[3].isSuccess ? results[3].value : const {'data': <dynamic>[]};
    final myShifts =
        results[4].isSuccess ? results[4].value : const {'data': <dynamic>[]};

    return Result.success(
      DashboardOverviewMapper.compose(
        session: _session,
        dashboardBody: dashboard.value,
        alertsBody: alertsBody,
        shiftsBody: null,
        notificationsBody: results[2].isSuccess ? results[2].value : null,
        myAttendanceBody: myAttendance,
        myShiftsBody: myShifts,
      ),
    );
  }
}
