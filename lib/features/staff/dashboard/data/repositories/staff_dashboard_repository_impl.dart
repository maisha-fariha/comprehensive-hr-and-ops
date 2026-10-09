import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../auth/data/mappers/auth_mapper.dart';
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
    // B1 map: Greeting & residence name → GET /mobile/me
    final me = await _api.get(ApiEndpoints.mobileMe, silent: true);
    if (me.isSuccess) {
      final profile = AuthMapper.profileFromJson(me.value);
      if (profile != null) {
        // `/mobile/me` omits the picture. Keep the account photo from
        // `/auth/me` (the same file the web header shows).
        final previous = _session.avatarUrl;
        _session.applyProfile(profile);
        if (profile.avatarUrl == null) {
          final kept = (previous != null && previous.isNotEmpty)
              ? previous
              : await _accountAvatarUrl();
          if (kept != null) _session.updateAvatarUrl(kept);
        }
      }
    }

    // B1 map: shift / attendance / tiles → GET /mobile/home
    final home = await _api.get(ApiEndpoints.mobileHome);
    if (home.isFailure) {
      return Result.failure(
        home.error ?? const ApiError(message: 'Could not load home.'),
      );
    }

    // `/mobile/home` tiles.tasksDue is currently 0 while the web tasks
    // screen uses `GET /tasks/stats` → `today.due`. Prefer that figure.
    final homeBody = Map<String, dynamic>.from(JsonCodec.unwrapMap(home.value));
    final tiles = Map<String, dynamic>.from(
      JsonCodec.mapAt(homeBody, 'tiles') ?? const {},
    );
    if (tiles.containsKey('tasksDue') && tiles['tasksDue'] != null) {
      final stats = await _api.get(ApiEndpoints.tasksStats, silent: true);
      if (stats.isSuccess) {
        final due = JsonCodec.integer(
          JsonCodec.mapAt(JsonCodec.unwrapMap(stats.value), 'today')?['due'],
        );
        if (due != null) tiles['tasksDue'] = due;
      }
    }
    homeBody['tiles'] = tiles;

    var unread = 0;
    final notifications = await _api.get(
      ApiEndpoints.notifications,
      query: const {'page': 1, 'limit': 20},
      silent: true,
    );
    if (notifications.isSuccess) {
      unread = PortalInboxMapper.notificationsFrom(notifications.value)
          .where((item) => !item.isRead)
          .length;
    }

    return Result.success(
      StaffHomeMapper.compose(
        session: _session,
        body: homeBody,
        unreadNotificationCount: unread,
      ),
    );
  }

  @override
  Future<Result<void>> checkIn({String? shiftId, String? residenceId}) {
    return _postAttendance(
      ApiEndpoints.attendanceCheckIn,
      shiftId: shiftId,
      residenceId: residenceId,
    );
  }

  @override
  Future<Result<void>> checkOut({String? shiftId, String? residenceId}) {
    return _postAttendance(
      ApiEndpoints.attendanceCheckOut,
      shiftId: shiftId,
      residenceId: residenceId,
    );
  }

  Future<Result<void>> _postAttendance(
    String path, {
    String? shiftId,
    String? residenceId,
  }) async {
    final resolvedResidence = residenceId ?? _session.residenceId;
    final body = <String, dynamic>{
      if (resolvedResidence != null && resolvedResidence.isNotEmpty)
        'residenceId': resolvedResidence,
      if (_session.staffId != null && _session.staffId!.isNotEmpty)
        'staffId': _session.staffId,
      if (shiftId != null && shiftId.isNotEmpty) 'shiftId': shiftId,
    };
    final result = await _api.post(path, data: body);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  Future<String?> _accountAvatarUrl() async {
    final result = await _api.get(ApiEndpoints.authMe, silent: true);
    if (result.isFailure) return null;
    return JsonCodec.string(JsonCodec.unwrapMap(result.value)['avatarUrl']);
  }
}
