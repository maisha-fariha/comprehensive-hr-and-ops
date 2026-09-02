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
      'limit': 100,
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

    return Result.success(
      AttendanceMapper.compose(
        attendanceBody: attendance.value,
        overtimeBody: extras[0].value,
        residenceBody: extras[1].value,
        fallbackResidenceName: _session.residenceName,
      ),
    );
  }
}
