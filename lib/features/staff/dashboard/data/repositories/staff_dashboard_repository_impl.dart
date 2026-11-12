import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../auth/data/mappers/auth_mapper.dart';
import '../../../../hr/attendance/data/mappers/attendance_mapper.dart';
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
    final open = await _openPunch();
    StaffHomeMapper.applyOpenPunch(homeBody, open);
    final openShiftId = JsonCodec.string(
      open?['shiftId'] ?? JsonCodec.mapAt(open ?? const {}, 'shift')?['id'],
    );
    _applyRosteredShift(
      homeBody,
      await _rosteredShift(preferShiftId: openShiftId),
      hasOpenPunch: open != null,
    );

    var unread = 0;
    final notifications = await _api.get(
      ApiEndpoints.notifications,
      query: const {'page': 1, 'limit': 30},
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

  /// `/mobile/home` can keep a shift from an earlier day. Today's Shift and
  /// clock-in follow the web window: this person, ±14h (wider when an open
  /// punch's shiftId must still be found after the window ends).
  Future<Map<String, dynamic>?> _rosteredShift({String? preferShiftId}) async {
    final now = DateTime.now().toUtc();
    final staffId = _session.staffId;
    final prefer = preferShiftId?.trim();
    final lookBackHours = prefer != null && prefer.isNotEmpty ? 48 : 14;
    final lookAheadHours = prefer != null && prefer.isNotEmpty ? 24 : 14;
    final result = await _api.get(
      ApiEndpoints.shifts,
      query: {
        if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
        if (staffId == null || staffId.isEmpty) 'mine': true,
        'from': now
            .subtract(Duration(hours: lookBackHours))
            .toIso8601String(),
        'to': now.add(Duration(hours: lookAheadHours)).toIso8601String(),
        'page': 1,
        'limit': 50,
      },
      silent: true,
    );
    if (result.isFailure) return null;
    final wallNow = DateTime.now();
    final window = AttendanceMapper.shiftWindowFrom(result.value, wallNow);
    if (window != null) {
      return {
        'id': window.shiftId,
        'startsAt': window.startsAt.toUtc().toIso8601String(),
        'endsAt': window.endsAt.toUtc().toIso8601String(),
        'clockOpen': window.isCurrent,
        if (window.residenceId != null) 'residenceId': window.residenceId,
        if (window.residenceName != null) 'residenceName': window.residenceName,
      };
    }

    // Still clocked into a just-ended shift — keep its times / id for Home
    // and clock-out (missing shiftId re-triggers HANDOVER_REQUIRED).
    if (prefer != null && prefer.isNotEmpty) {
      for (final item in JsonCodec.unwrapList(result.value)) {
        if (item is! Map) continue;
        final json = JsonCodec.asMap(item);
        if (JsonCodec.string(json['status']) == 'cancelled') continue;
        if (JsonCodec.string(json['id']) != prefer) continue;
        final startsAt = JsonCodec.dateTime(json['startsAt']);
        final endsAt = JsonCodec.dateTime(json['endsAt']);
        if (startsAt == null || endsAt == null) continue;
        return {
          'id': prefer,
          'startsAt': startsAt.toUtc().toIso8601String(),
          'endsAt': endsAt.toUtc().toIso8601String(),
          'clockOpen': !startsAt
                  .subtract(const Duration(minutes: 15))
                  .isAfter(wallNow) &&
              !endsAt.isBefore(wallNow),
          if (JsonCodec.string(json['residenceId']) != null)
            'residenceId': JsonCodec.string(json['residenceId']),
          if (JsonCodec.string(json['residenceName']) != null)
            'residenceName': JsonCodec.string(json['residenceName']),
        };
      }
    }
    return const {};
  }

  void _applyRosteredShift(
    Map<String, dynamic> home,
    Map<String, dynamic>? shift, {
    bool hasOpenPunch = false,
  }) {
    // A failed lookup leaves the home payload alone.
    if (shift == null) return;
    if (shift.isEmpty) {
      // Do not blank Today's Shift while an open punch keeps us On Shift —
      // that produced "On Shift" + "No shift today" and dropped shiftId.
      if (hasOpenPunch) return;
      home['shift'] = <String, dynamic>{};
      return;
    }
    final current = Map<String, dynamic>.from(
      JsonCodec.mapAt(home, 'shift') ?? const {},
    );
    current.addAll(shift);
    for (final key in ['timeRange', 'label', 'timeLabel']) {
      final value = JsonCodec.string(current[key])?.trim().toLowerCase() ?? '';
      if (value.isEmpty ||
          value == 'no shift today' ||
          value == 'no shift' ||
          value == 'off shift') {
        current.remove(key);
      }
    }
    home['shift'] = current;
  }

  /// Same window as the web `useMyOpenAttendance` and the Attendance screen.
  Future<Map<String, dynamic>?> _openPunch() async {
    final now = DateTime.now().toUtc();
    final result = await _api.get(
      ApiEndpoints.attendance,
      query: {
        'mine': true,
        'from': now.subtract(const Duration(hours: 48)).toIso8601String(),
        'to': now.add(const Duration(hours: 1)).toIso8601String(),
        'page': 1,
        'limit': 50,
      },
      silent: true,
    );
    if (result.isFailure) return null;
    for (final raw in JsonCodec.unwrapList(result.value)) {
      if (raw is! Map) continue;
      final json = JsonCodec.asMap(raw);
      final checkIn = JsonCodec.dateTime(json['checkInAt'] ?? json['clockInAt']);
      if (checkIn == null) continue;
      final checkOut = JsonCodec.dateTime(json['checkOutAt'] ?? json['clockOutAt']);
      if (checkOut == null) return json;
    }
    return null;
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
