import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_dashboard_overview.dart';
import '../../domain/entities/family_notification.dart';
import '../../domain/entities/family_search_hit.dart';
import '../../domain/repositories/family_dashboard_repository.dart';
import '../mappers/family_home_mapper.dart';
import '../mappers/family_notifications_mapper.dart';
import '../mappers/family_search_mapper.dart';

class FamilyDashboardRepositoryImpl implements FamilyDashboardRepository {
  final AppApiClient _api;
  final UserSession _session;

  FamilyDashboardRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<FamilyDashboardOverview>> getOverview() async {
    final home = await _api.get(ApiEndpoints.familyHome);
    if (home.isFailure) {
      return Result.failure(
        home.error ?? const ApiError(message: 'Could not load family home.'),
      );
    }

    Result<dynamic>? updates;
    final homeJson = JsonCodec.unwrapMap(home.value);
    final clients = JsonCodec.listAt(homeJson, 'linkedClients');
    var clientId = _session.selectedClientId;
    if ((clientId == null || clientId.isEmpty) &&
        clients.isNotEmpty &&
        clients.first is Map) {
      clientId = JsonCodec.string(JsonCodec.asMap(clients.first as Map)['id']);
    }
    final visibility = JsonCodec.mapAt(homeJson, 'visibility') ?? {};
    final showLogs = JsonCodec.boolean(visibility['dailyLogs']) ?? true;
    if (clientId != null && clientId.isNotEmpty && showLogs) {
      updates = await _api.get(ApiEndpoints.familyDailyUpdates(clientId));
    }

    var unread = JsonCodec.integerOr(homeJson['unreadCount'], 0);
    final notifications = await _api.get(ApiEndpoints.notifications);
    if (notifications.isSuccess) {
      final items = FamilyNotificationsMapper.listFrom(notifications.value);
      unread = items.where((item) => !item.isRead).length;
    }

    return Result.success(
      FamilyHomeMapper.compose(
        session: _session,
        homeBody: home.value,
        updatesBody: updates?.value,
        unreadNotificationCount: unread,
      ),
    );
  }

  @override
  Future<Result<List<FamilySearchHit>>> search(String query) async {
    final result = await _api.get(
      ApiEndpoints.familySearch,
      query: {'q': query.trim()},
    );
    return result.when(
      success: (body) async => Result.success(FamilySearchMapper.listFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<FamilyNotification>>> getNotifications() async {
    final result = await _api.get(ApiEndpoints.notifications);
    return result.when(
      success: (body) async =>
          Result.success(FamilyNotificationsMapper.listFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> markNotificationRead(String id) async {
    final result = await _api.patch(ApiEndpoints.notificationRead(id));
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> markAllNotificationsRead() async {
    final result = await _api.post(ApiEndpoints.notificationsReadAll);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
