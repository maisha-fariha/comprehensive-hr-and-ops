import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_attendance_overview.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../mappers/staff_attendance_mapper.dart';

class StaffAttendanceRepositoryImpl implements StaffAttendanceRepository {
  static const _historyDays = 30;
  static const _pageLimit = 20;

  final AppApiClient _api;
  final UserSession _session;

  StaffAttendanceRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<StaffAttendanceOverview>> getOverview() async {
    final residenceId = _session.residenceId;

    final futures = <Future<Result<dynamic>>>[
      // Open-shift status: today → now (mine=true per Fixed 1).
      _api.get(
        ApiEndpoints.attendance,
        query: {
          'mine': true,
          'from': IsoDateRange.todayStartIso,
          'to': IsoDateRange.nowIso,
          'page': 1,
          'limit': _pageLimit,
        },
      ),
      // Attendance History.
      _api.get(
        ApiEndpoints.attendance,
        query: {
          'mine': true,
          'from': IsoDateRange.daysAgoStartIso(_historyDays),
          'to': IsoDateRange.nowIso,
          'page': 1,
          'limit': _pageLimit,
        },
      ),
      // Shift Details.
      _api.get(
        ApiEndpoints.shifts,
        query: {
          'mine': true,
          'from': IsoDateRange.todayStartIso,
          'to': IsoDateRange.todayEndIso,
          'page': 1,
          'limit': _pageLimit,
        },
      ),
    ];

    if (residenceId != null && residenceId.isNotEmpty) {
      futures.add(_api.get(ApiEndpoints.residenceById(residenceId)));
    }

    final results = await Future.wait(futures);
    if (results[0].isFailure && results[1].isFailure) {
      return Result.failure(
        results[0].error ??
            results[1].error ??
            const ApiError(message: 'Could not load attendance.'),
      );
    }

    return Result.success(
      StaffAttendanceMapper.compose(
        todayAttendanceBody:
            results[0].isSuccess ? results[0].value : const [],
        historyBody: results[1].isSuccess ? results[1].value : const [],
        shiftsBody: results[2].isSuccess ? results[2].value : const [],
        residenceBody: results.length > 3 && results[3].isSuccess
            ? results[3].value
            : null,
        sessionResidenceId: residenceId,
      ),
    );
  }

  @override
  Future<Result<void>> checkIn({
    String? shiftId,
    String? residenceId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? selfieUrl,
  }) {
    return _clockAction(
      ApiEndpoints.attendanceCheckIn,
      shiftId: shiftId,
      residenceId: residenceId,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      selfieUrl: selfieUrl,
    );
  }

  @override
  Future<Result<void>> checkOut({
    String? shiftId,
    String? residenceId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? selfieUrl,
  }) {
    return _clockAction(
      ApiEndpoints.attendanceCheckOut,
      shiftId: shiftId,
      residenceId: residenceId,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      selfieUrl: selfieUrl,
    );
  }

  @override
  Future<Result<String>> uploadAttendanceSelfie({
    required String localPath,
    required String fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: const {'category': 'attendance'},
        allowQueue: false,
      );
      return result.when(
        success: (body) async {
          final map = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(
            map['fileUrl'] ?? map['url'] ?? map['publicUrl'],
          );
          if (url == null || url.isEmpty) {
            return Result.failure(
              const ApiError(
                message: 'Upload succeeded but file URL was missing.',
              ),
            );
          }
          return Result.success(url);
        },
        failure: (error) async => Result.failure(error),
      );
    } catch (error) {
      return Result.failure(
        ApiError(message: 'Could not upload selfie: $error'),
      );
    }
  }

  @override
  Future<Result<void>> startBreak({String? residenceId}) {
    return _breakAction(ApiEndpoints.attendanceBreakStart, residenceId);
  }

  @override
  Future<Result<void>> endBreak({String? residenceId}) {
    return _breakAction(ApiEndpoints.attendanceBreakEnd, residenceId);
  }

  Future<Result<void>> _clockAction(
    String path, {
    String? shiftId,
    String? residenceId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? selfieUrl,
  }) async {
    final resolvedResidence = residenceId ?? _session.residenceId;
    final staffId = _session.staffId;
    final body = <String, dynamic>{
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
      if (resolvedResidence != null && resolvedResidence.isNotEmpty)
        'residenceId': resolvedResidence,
      if (shiftId != null && shiftId.isNotEmpty) 'shiftId': shiftId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (selfieUrl != null && selfieUrl.isNotEmpty) 'selfieUrl': selfieUrl,
    };
    final result = await _api.post(path, data: body);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> _breakAction(String path, String? residenceId) async {
    final resolvedResidence = residenceId ?? _session.residenceId;
    final staffId = _session.staffId;
    final body = <String, dynamic>{
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
      if (resolvedResidence != null && resolvedResidence.isNotEmpty)
        'residenceId': resolvedResidence,
    };
    final result = await _api.post(path, data: body);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
