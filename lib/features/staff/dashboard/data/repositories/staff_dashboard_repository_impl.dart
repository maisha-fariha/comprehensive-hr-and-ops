import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../common/inbox/data/mappers/portal_inbox_mapper.dart';
import '../../domain/entities/staff_dashboard_overview.dart';
import '../../domain/repositories/staff_dashboard_repository.dart';
import '../mappers/staff_home_mapper.dart';

class StaffDashboardRepositoryImpl implements StaffDashboardRepository {
  final AppApiClient _api;
  final UserSession _session;

  StaffDashboardRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<StaffDashboardOverview>> getOverview() async {
    final result = await _api.get(ApiEndpoints.mobileHome);
    if (result.isFailure) {
      return Result.failure(
        result.error ?? const ApiError(message: 'Could not load home.'),
      );
    }
    var unread = 0;
    final notifications = await _api.get(
      ApiEndpoints.notifications,
      query: const {'page': 1, 'limit': 20},
    );
    if (notifications.isSuccess) {
      unread = PortalInboxMapper.notificationsFrom(notifications.value)
          .where((item) => !item.isRead)
          .length;
    }
    return Result.success(
      StaffHomeMapper.compose(
        session: _session,
        body: result.value,
        unreadNotificationCount: unread,
      ),
    );
  }
}
