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
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Result.success(const <PortalSearchHit>[]);
    }

    // Silent so the Search screen owns error UI (avoids duplicate dialogs
    // while the user is typing / retrying).
    final result = await _api.get(
      ApiEndpoints.search,
      query: {'q': trimmed},
      silent: true,
    );
    return result.when(
      success: (body) async {
        try {
          return Result.success(PortalInboxMapper.searchFrom(body));
        } catch (_) {
          return Result.failure(
            const NetworkError(
              message: 'Search results could not be read. Please try again.',
              code: 'parse',
            ),
          );
        }
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<PortalNotification>>> getNotifications() async {
    final result = await _api.get(
      ApiEndpoints.notifications,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(PortalInboxMapper.notificationsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> markNotificationRead(String id) async {
    // Action endpoint (same style as /notifications/read-all) — prefer POST.
    // Fall back to PATCH for backends that expose the older verb.
    final post = await _api.post(
      ApiEndpoints.notificationRead(id),
      data: const <String, dynamic>{},
      silent: true,
      allowQueue: false,
    );
    if (post.isSuccess) return Result.success(null);

    final patch = await _api.patch(
      ApiEndpoints.notificationRead(id),
      data: const <String, dynamic>{},
      silent: true,
      allowQueue: false,
    );
    return patch.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> markAllNotificationsRead() async {
    final result = await _api.post(
      ApiEndpoints.notificationsReadAll,
      data: const <String, dynamic>{},
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
