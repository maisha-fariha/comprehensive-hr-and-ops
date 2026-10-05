import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/manual_entry_options.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../mappers/attendance_mapper.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AppApiClient _api;
  final UserSession _session;

  static const int _pageSize = 100;

  AttendanceRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<AttendanceRecordPage>> getRecords({
    required int page,
    required int limit,
    String? residenceId,
    String? status,
    String? from,
    String? to,
    bool mine = false,
  }) async {
    final result = await _api.get(
      ApiEndpoints.attendance,
      query: {
        'page': page,
        'limit': limit,
        'residenceId': ?residenceId,
        'status': ?status,
        'from': ?from,
        'to': ?to,
        if (mine) 'mine': true,
      },
    );
    return result.when(
      success: (body) async => Result.success(
        AttendanceMapper.recordPageFrom(body, page: page, limit: limit),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AttendanceSummary>> getSummary({
    String? residenceId,
    required String from,
    required String to,
  }) async {
    final result = await _api.get(
      ApiEndpoints.attendanceSummary,
      query: {'residenceId': ?residenceId, 'from': from, 'to': to},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(AttendanceMapper.summaryFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<OpenAttendance?>> getMyOpenAttendance() async {
    final now = DateTime.now().toUtc();
    final result = await _api.get(
      ApiEndpoints.attendance,
      query: {
        'mine': true,
        'from': now.subtract(const Duration(hours: 48)).toIso8601String(),
        'to': now.add(const Duration(hours: 1)).toIso8601String(),
        'limit': 50,
      },
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(AttendanceMapper.openAttendanceFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AttendanceShiftWindow?>> getMyShiftWindow(
    String staffId,
  ) async {
    final now = DateTime.now();
    final utc = now.toUtc();
    final result = await _api.get(
      ApiEndpoints.shifts,
      query: {
        'staffId': staffId,
        'limit': 20,
        'from': utc.subtract(const Duration(hours: 14)).toIso8601String(),
        'to': utc.add(const Duration(hours: 14)).toIso8601String(),
      },
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(AttendanceMapper.shiftWindowFrom(body, now)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> clockIn(Map<String, dynamic> body) =>
      _voidPost(ApiEndpoints.attendanceCheckIn, body);

  @override
  Future<Result<void>> clockOut(Map<String, dynamic> body) =>
      _voidPost(ApiEndpoints.attendanceCheckOut, body);

  @override
  Future<Result<String>> uploadSelfie(String localPath, String fileName) async {
    final result = await _upload(localPath, fileName, 'attendance-selfies');
    return result.when(
      success: (url) async => Result.success(url),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> updateAttendance(
    String attendanceId,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.patch(
      ApiEndpoints.attendanceById(attendanceId),
      data: body,
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> deleteAttendance(String attendanceId) async {
    final result = await _api.delete(
      ApiEndpoints.attendanceById(attendanceId),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
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

  @override
  Future<Result<List<ManualEntryResidenceOption>>> getResidences() async {
    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(AttendanceMapper.residencesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ManualEntryStaffOption>>> searchStaff({
    String? search,
    String? residenceId,
  }) async {
    final trimmed = search?.trim() ?? '';
    final scopedResidenceId = residenceId ?? _session.residenceId;
    final result = await _api.get(
      ApiEndpoints.staff,
      query: {
        'page': 1,
        'limit': _pageSize,
        if (trimmed.isNotEmpty) 'search': trimmed,
        'residenceId': ?scopedResidenceId,
      },
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(AttendanceMapper.staffFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ManualEntryShiftOption>>> getRosteredShifts({
    required String staffId,
    String? residenceId,
  }) async {
    final result = await _api.get(
      ApiEndpoints.shifts,
      query: {'limit': 50, 'staffId': staffId, 'residenceId': ?residenceId},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(AttendanceMapper.rosteredShiftsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<ManualEntryEvidenceFile>> uploadEvidenceFile(
    ManualEntryEvidenceFile file,
  ) async {
    final result = await _upload(
      file.localPath,
      file.fileName,
      'attendance-evidence',
    );
    return result.when(
      success: (url) async => Result.success(
        file.copyWith(fileUrl: url, isUploading: false, clearError: true),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String>> recordManualAttendance(
    Map<String, dynamic> payload,
  ) async {
    final result = await _api.post(
      ApiEndpoints.attendanceManual,
      data: payload,
      allowQueue: false,
    );
    return result.when(
      success: (body) async => Result.success(_extractId(body) ?? ''),
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<String>> _upload(
    String localPath,
    String fileName,
    String category,
  ) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: {'category': category},
        allowQueue: false,
      );
      return result.when(
        success: (body) async {
          final map = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(
            map['fileUrl'] ?? map['url'] ?? map['publicUrl'],
          );
          if (url == null) {
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
        ApiError(message: 'Could not upload $fileName: $error'),
      );
    }
  }

  Future<Result<void>> _voidPost(
    String path, [
    Map<String, dynamic> body = const <String, dynamic>{},
  ]) async {
    final result = await _api.post(path, data: body, allowQueue: false);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  String? _extractId(dynamic body) {
    if (body is Map) {
      final map = JsonCodec.asMap(body);
      final data = JsonCodec.mapAt(map, 'data') ?? map;
      return JsonCodec.string(data['id'] ?? map['id']);
    }
    return null;
  }
}
