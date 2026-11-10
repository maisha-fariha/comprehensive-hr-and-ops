import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../mappers/dashboard_overview_mapper.dart';

/// Manager dashboard: composes session data with
/// `/dashboard`, `/dashboard/alerts`, and `/notifications`.
///
/// Quick Actions are static shortcuts (not API-driven). Today's Schedule /
/// `/shifts` is not fetched for the current Home layout.
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
    final results = await Future.wait([
      _api.get(ApiEndpoints.dashboard),
      _api.get(ApiEndpoints.dashboardAlerts),
      _api.get(
        ApiEndpoints.notifications,
        query: const {'page': 1, 'limit': 30},
      ),
    ]);

    final dashboard = results[0];
    if (dashboard.isFailure) {
      return Result.failure(
        dashboard.error ??
            const ApiError(message: 'Could not load the dashboard.'),
      );
    }

    final alerts = results[1];
    if (alerts.isFailure) {
      return Result.failure(
        alerts.error ??
            const ApiError(message: 'Could not load dashboard alerts.'),
      );
    }

    return Result.success(
      DashboardOverviewMapper.compose(
        session: _session,
        dashboardBody: dashboard.value,
        alertsBody: alerts.value,
        shiftsBody: null,
        notificationsBody: results[2].isSuccess ? results[2].value : null,
      ),
    );
  }
}
