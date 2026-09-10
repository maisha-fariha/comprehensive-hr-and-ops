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
  Future<Result<AttendanceOverview>> getOverview({
    DateTime? from,
    DateTime? to,
  }) async {
    final rangeStart = from == null
        ? IsoDateRange.startOfLocalDay()
        : DateTime(from.year, from.month, from.day);
    final rangeEndExclusive = to == null
        ? rangeStart.add(const Duration(days: 1))
        : DateTime(to.year, to.month, to.day).add(const Duration(days: 1));

    final fromIso = rangeStart.toUtc().toIso8601String();
    final toIso = rangeEndExclusive.toUtc().toIso8601String();
    final residenceId = _session.residenceId;
    final rangeQuery = <String, dynamic>{
      'from': fromIso,
      'to': toIso,
      'residenceId': ?residenceId,
    };

    final results = await Future.wait([
      _api.get(
        ApiEndpoints.attendance,
        query: {
          ...rangeQuery,
          'page': 1,
          'limit': 200,
        },
      ),
      _api.get(ApiEndpoints.attendanceOvertime, query: rangeQuery),
      _api.get(ApiEndpoints.attendanceSummary, query: rangeQuery),
      if (residenceId != null && residenceId.isNotEmpty)
        _api.get(ApiEndpoints.residenceById(residenceId))
      else
        Future.value(Result<dynamic>.success(null)),
    ]);

    final attendance = results[0];
    if (attendance.isFailure) {
      return Result.failure(
        attendance.error ??
            const ApiError(message: 'Could not load attendance.'),
      );
    }

    final overtime = results[1];
    if (overtime.isFailure) {
      return Result.failure(
        overtime.error ??
            const ApiError(message: 'Could not load overtime records.'),
      );
    }

    // Summary powers the stat tiles; if it fails, list-derived counts still work.
    final summaryBody =
        results[2].isSuccess ? results[2].value : null;

    return Result.success(
      AttendanceMapper.compose(
        attendanceBody: attendance.value,
        overtimeBody: overtime.value,
        summaryBody: summaryBody,
        residenceBody: results[3].isSuccess ? results[3].value : null,
        fallbackResidenceName: _session.residenceName,
        multiDay: rangeEndExclusive.difference(rangeStart).inDays > 1,
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
