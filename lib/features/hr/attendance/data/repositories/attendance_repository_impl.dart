import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/attendance_overview.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../mappers/attendance_mapper.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AppApiClient _api;
  final UserSession _session;

  AttendanceRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<AttendanceOverview>> getOverview() async {
    final residenceId = _session.residenceId;
    final query = <String, dynamic>{
      'from': IsoDateRange.todayStartIso,
      'to': IsoDateRange.todayEndIso,
      'page': 1,
      'limit': 200,
      'residenceId': ?residenceId,
    };

    final attendance = await _api.get(ApiEndpoints.attendance, query: query);
    if (attendance.isFailure) {
      return Result.failure(
        attendance.error ??
            const ApiError(message: 'Could not load attendance.'),
      );
    }

    final extras = await Future.wait([
      _api.get(
        ApiEndpoints.attendanceOvertime,
        query: {
          'from': IsoDateRange.weekStartIso,
          'to': IsoDateRange.weekEndIso,
          'residenceId': ?residenceId,
        },
      ),
      if (residenceId != null && residenceId.isNotEmpty)
        _api.get(ApiEndpoints.residenceById(residenceId))
      else
        Future.value(Result<dynamic>.success(null)),
    ]);

    final overtime = extras[0];
    if (overtime.isFailure) {
      return Result.failure(
        overtime.error ??
            const ApiError(message: 'Could not load overtime records.'),
      );
    }

    return Result.success(
      AttendanceMapper.compose(
        attendanceBody: attendance.value,
        overtimeBody: overtime.value,
        residenceBody: extras[1].isSuccess ? extras[1].value : null,
        fallbackResidenceName: _session.residenceName,
      ),
    );
  }

  @override
  Future<Result<void>> approveAttendance(String attendanceId) {
    return _voidPost(ApiEndpoints.attendanceApprove(attendanceId));
  }

  @override
  Future<Result<void>> rejectAttendance(String attendanceId) {
    return _voidPost(ApiEndpoints.attendanceReject(attendanceId));
  }

  Future<Result<void>> _voidPost(String path) async {
    final result = await _api.post(path, data: const <String, dynamic>{});
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
