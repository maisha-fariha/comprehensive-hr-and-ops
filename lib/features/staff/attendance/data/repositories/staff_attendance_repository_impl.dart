import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_attendance_overview.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../mappers/staff_attendance_mapper.dart';

class StaffAttendanceRepositoryImpl implements StaffAttendanceRepository {
  final AppApiClient _api;
  final UserSession _session;

  StaffAttendanceRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<StaffAttendanceOverview>> getOverview() async {
    final attendance = await _api.get(
      ApiEndpoints.attendance,
      query: {
        'mine': true,
        'from': IsoDateRange.daysAgoStartIso(30),
        'to': IsoDateRange.nowIso,
        'page': 1,
        'limit': 20,
      },
    );
    if (attendance.isFailure) {
      return Result.failure(
        attendance.error ??
            const ApiError(message: 'Could not load attendance.'),
      );
    }

    final shifts = await _api.get(
      ApiEndpoints.shifts,
      query: {
        'mine': true,
        'from': IsoDateRange.todayStartIso,
        'to': IsoDateRange.todayEndIso,
        'page': 1,
        'limit': 20,
      },
    );

    Result<dynamic>? residence;
    final residenceId = _session.residenceId;
    if (residenceId != null && residenceId.isNotEmpty) {
      residence = await _api.get(ApiEndpoints.residenceById(residenceId));
    }

    return Result.success(
      StaffAttendanceMapper.compose(
        attendanceBody: attendance.value,
        shiftsBody: shifts.value,
        residenceBody: residence?.value,
      ),
    );
  }

  @override
  Future<Result<void>> checkIn({String? shiftId, String? residenceId}) {
    return _postAction(ApiEndpoints.attendanceCheckIn, shiftId, residenceId);
  }

  @override
  Future<Result<void>> checkOut({String? shiftId, String? residenceId}) {
    return _postAction(ApiEndpoints.attendanceCheckOut, shiftId, residenceId);
  }

  @override
  Future<Result<void>> startBreak({String? residenceId}) {
    return _postAction(ApiEndpoints.attendanceBreakStart, null, residenceId);
  }

  @override
  Future<Result<void>> endBreak({String? residenceId}) {
    return _postAction(ApiEndpoints.attendanceBreakEnd, null, residenceId);
  }

  Future<Result<void>> _postAction(
    String path,
    String? shiftId,
    String? residenceId,
  ) async {
    final resolvedResidence = residenceId ?? _session.residenceId;
    final body = <String, dynamic>{
      'residenceId': ?resolvedResidence,
      'staffId': ?_session.staffId,
      'shiftId': ?shiftId,
    };
    final result = await _api.post(path, data: body);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
