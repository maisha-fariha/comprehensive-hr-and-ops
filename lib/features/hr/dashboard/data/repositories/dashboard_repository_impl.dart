import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../mappers/dashboard_overview_mapper.dart';

/// Manager dashboard: composes `GET /mobile/me` session data with
/// `/dashboard`, `/dashboard/alerts`, `/shifts` and `/notifications`.
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
    final residenceId = _session.residenceId;
    final shiftQuery = <String, dynamic>{
      'from': IsoDateRange.todayStartIso,
      'to': IsoDateRange.todayEndIso,
      'page': 1,
      'limit': 50,
      'residenceId': ?residenceId,
    };

    final results = await Future.wait([
      _api.get(ApiEndpoints.dashboard),
      _api.get(ApiEndpoints.dashboardAlerts),
      _api.get(ApiEndpoints.shifts, query: shiftQuery),
      _api.get(
        ApiEndpoints.notifications,
        query: const {'page': 1, 'limit': 20},
      ),
    ]);

    final dashboard = results[0];
    if (dashboard.isFailure) {
      return Result.failure(
        dashboard.error ??
            const ApiError(message: 'Could not load the dashboard.'),
      );
    }

    return Result.success(
      DashboardOverviewMapper.compose(
        session: _session,
        dashboardBody: dashboard.value,
        alertsBody: results[1].value,
        shiftsBody: results[2].value,
        notificationsBody: results[3].value,
      ),
    );
  }
}
