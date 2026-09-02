import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../domain/entities/portal_notification.dart';
import '../../domain/entities/portal_search_hit.dart';
import '../../domain/repositories/portal_inbox_repository.dart';
import '../mappers/portal_inbox_mapper.dart';

class PortalInboxRepositoryImpl implements PortalInboxRepository {
  final AppApiClient _api;

  PortalInboxRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<List<PortalSearchHit>>> search(String query) async {
    final result = await _api.get(
      ApiEndpoints.search,
      query: {'q': query.trim()},
    );
    return result.when(
      success: (body) async =>
          Result.success(PortalInboxMapper.searchFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<PortalNotification>>> getNotifications() async {
    final result = await _api.get(
      ApiEndpoints.notifications,
      query: const {'page': 1, 'limit': 50},
    );
    return result.when(
      success: (body) async =>
          Result.success(PortalInboxMapper.notificationsFrom(body)),
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
