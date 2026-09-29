import 'package:gems_core/gems_core.dart';

import '../entities/attendance_record.dart';
import '../entities/manual_entry_options.dart';

/// Contract for the manager "Attendance" screen and its nested flows.
abstract class AttendanceRepository {
  /// `GET /attendance?page&limit&residenceId&status&from&to` (dates `yyyy-MM-dd`).
  /// [mine] limits the list to the caller's own records.
  Future<Result<AttendanceRecordPage>> getRecords({
    required int page,
    required int limit,
    String? residenceId,
    String? status,
    String? from,
    String? to,
    bool mine = false,
  });

  /// `GET /attendance/summary?residenceId&from&to`.
  Future<Result<AttendanceSummary>> getSummary({
    String? residenceId,
    required String from,
    required String to,
  });

  /// The caller's own record with a clock-in but no clock-out, if any
  /// (`GET /attendance?mine=true` over the last 48 hours).
  Future<Result<OpenAttendance?>> getMyOpenAttendance();

  /// The caller's current shift, else the next one, within ±14 hours
  /// (`GET /shifts?staffId&from&to`).
  Future<Result<AttendanceShiftWindow?>> getMyShiftWindow(String staffId);

  /// `POST /attendance/check-in`.
  Future<Result<void>> clockIn(Map<String, dynamic> body);

  /// `POST /attendance/check-out`.
  Future<Result<void>> clockOut(Map<String, dynamic> body);

  /// Clock photo upload (`POST /uploads?category=attendance-selfies`).
  Future<Result<String>> uploadSelfie(String localPath, String fileName);

  /// Correction of an existing record (`PATCH /attendance/{id}`).
  Future<Result<void>> updateAttendance(
    String attendanceId,
    Map<String, dynamic> body,
  );

  /// Soft delete (`DELETE /attendance/{id}`).
  Future<Result<void>> deleteAttendance(String attendanceId);

  Future<Result<void>> approveAttendance(String attendanceId);

  Future<Result<void>> rejectAttendance(String attendanceId);

  /// Residences for filters and Manual Entry (`GET /residences`).
  Future<Result<List<ManualEntryResidenceOption>>> getResidences();

  /// Staff search for Manual Entry (`GET /staff`).
  Future<Result<List<ManualEntryStaffOption>>> searchStaff({
    String? search,
    String? residenceId,
  });

  /// Shifts a staff member is rostered on (`GET /shifts?limit=50&staffId&residenceId`).
  Future<Result<List<ManualEntryShiftOption>>> getRosteredShifts({
    required String staffId,
    String? residenceId,
  });

  /// Evidence upload (`POST /uploads?category=attendance-evidence`).
  Future<Result<ManualEntryEvidenceFile>> uploadEvidenceFile(
    ManualEntryEvidenceFile file,
  );

  /// `POST /attendance/manual`. Returns the new attendance id when present.
  Future<Result<String>> recordManualAttendance(Map<String, dynamic> payload);
}
