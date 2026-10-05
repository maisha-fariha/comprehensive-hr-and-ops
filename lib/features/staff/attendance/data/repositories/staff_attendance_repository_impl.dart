import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../hr/attendance/data/mappers/attendance_mapper.dart';
import '../../../../hr/attendance/domain/entities/manual_entry_options.dart';
import '../../domain/entities/staff_attendance_overview.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../mappers/staff_attendance_mapper.dart';

class StaffAttendanceRepositoryImpl implements StaffAttendanceRepository {
  static const _pageLimit = 20;

  final AppApiClient _api;
  final UserSession _session;

  StaffAttendanceRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  }) : _api = api,
       _session = session;

  @override
  Future<Result<StaffAttendanceOverview>> getOverview() async {
    final residenceId = _session.residenceId;

    // Web list uses `mine` without a tight from/to — date filters on the API
    // drop missed rows (null checkInAt). Open punch uses the web's
    // `useMyOpenAttendance` window (now-48h → now+1h) so overnight shifts count.
    final now = DateTime.now().toUtc();
    final futures = <Future<Result<dynamic>>>[
      _api.get(
        ApiEndpoints.attendance,
        query: {
          'mine': true,
          'from': now.subtract(const Duration(hours: 48)).toIso8601String(),
          'to': now.add(const Duration(hours: 1)).toIso8601String(),
          'page': 1,
          'limit': 50,
        },
      ),
      // History: omit from/to so missed / pending rows are returned (web parity).
      _api.get(
        ApiEndpoints.attendance,
        query: {
          'mine': true,
          'page': 1,
          'limit': 50,
        },
      ),
      _api.get(
        ApiEndpoints.shifts,
        query: {
          'mine': true,
          'from': IsoDateRange.daysAgoStartIso(7),
          'to': IsoDateRange.weekEndIso,
          'page': 1,
          'limit': _pageLimit,
        },
      ),
      // Summary drives Present / Late / Missed / Pending cards (web).
      _api.get(ApiEndpoints.attendanceSummary, silent: true),
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
        todayAttendanceBody: results[0].isSuccess ? results[0].value : const [],
        historyBody: results[1].isSuccess ? results[1].value : const [],
        shiftsBody: results[2].isSuccess ? results[2].value : const [],
        summaryBody: results[3].isSuccess ? results[3].value : null,
        residenceBody: results.length > 4 && results[4].isSuccess
            ? results[4].value
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

  @override
  Future<Result<List<ManualEntryResidenceOption>>> getResidences() async {
    final result = await _api.get(ApiEndpoints.residences, silent: true);
    return result.when(
      success: (body) async =>
          Result.success(AttendanceMapper.residencesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ManualEntryShiftOption>>> getRosteredShifts({
    String? residenceId,
    DateTime? around,
  }) async {
    final day = IsoDateRange.startOfLocalDay(around);
    final from = day.subtract(const Duration(days: 3));
    final to = day.add(const Duration(days: 4));
    final scopedResidenceId = residenceId ?? _session.residenceId;

    final result = await _api.get(
      ApiEndpoints.shifts,
      query: {
        'mine': true,
        'page': 1,
        'limit': _pageLimit,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'residenceId': ?scopedResidenceId,
      },
      silent: true,
    );

    return result.when(
      success: (body) async =>
          Result.success(AttendanceMapper.shiftsForStaff(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<ManualEntryEvidenceFile>> uploadEvidenceFile(
    ManualEntryEvidenceFile file,
  ) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.localPath,
          filename: file.fileName,
        ),
      });
      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: const {'category': 'documents'},
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
          return Result.success(
            file.copyWith(fileUrl: url, isUploading: false, clearError: true),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    } catch (error) {
      return Result.failure(
        ApiError(message: 'Could not upload ${file.fileName}: $error'),
      );
    }
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

  @override
  Future<Result<String>> recordManualAttendance({
    required String checkInAtIso,
    String? checkOutAtIso,
    String? residenceId,
    String? staffId,
    String? shiftId,
    int breakMinutes = 0,
    String reasonCategory = 'other',
    String status = 'pending_approval',
    String? notes,
    List<Map<String, dynamic>> evidence = const [],
  }) async {
    final resolvedStaff = staffId ?? _session.staffId;
    final resolvedResidence = residenceId ?? _session.residenceId;
    if (resolvedStaff == null || resolvedStaff.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Staff profile is required for manual entry.'),
      );
    }
    if (resolvedResidence == null || resolvedResidence.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Residence is required for manual entry.'),
      );
    }
    final result = await _api.post(
      ApiEndpoints.attendanceManual,
      data: {
        'staffId': resolvedStaff,
        'residenceId': resolvedResidence,
        'checkInAt': checkInAtIso,
        if (checkOutAtIso != null && checkOutAtIso.isNotEmpty)
          'checkOutAt': checkOutAtIso,
        if (shiftId != null && shiftId.isNotEmpty) 'shiftId': shiftId,
        'status': status,
        'reasonCategory': reasonCategory,
        'breakMinutes': breakMinutes,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (evidence.isNotEmpty) 'evidence': evidence,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final json = JsonCodec.unwrapMap(body);
        return Result.success(JsonCodec.string(json['id']) ?? '');
      },
      failure: (error) async => Result.failure(error),
    );
  }
}
