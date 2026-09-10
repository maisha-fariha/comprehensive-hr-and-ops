import 'package:gems_core/gems_core.dart';

import '../entities/attendance_overview.dart';
import '../entities/manual_entry_options.dart';

/// Contract for fetching the "Attendance" screen's data.
abstract class AttendanceRepository {
  /// Loads list + overtime + summary for `[from, to)` (ISO query params).
  /// Defaults to today when both are omitted.
  Future<Result<AttendanceOverview>> getOverview({
    DateTime? from,
    DateTime? to,
  });

  /// Manager review of a missed / exceptional attendance record.
  Future<Result<void>> approveAttendance(String attendanceId);

  Future<Result<void>> rejectAttendance(String attendanceId);

  /// Residences for Manual Entry (`GET /residences`).
  Future<Result<List<ManualEntryResidenceOption>>> getResidences();

  /// Staff search for Manual Entry (`GET /staff`).
  Future<Result<List<ManualEntryStaffOption>>> searchStaff({
    String? search,
    String? residenceId,
  });

  /// Rostered shifts for a staff member (`GET /shifts?from&to&residenceId`).
  Future<Result<List<ManualEntryShiftOption>>> getRosteredShifts({
    required String staffId,
    String? residenceId,
    DateTime? around,
  });

  /// Upload evidence for manual entry (`POST /uploads?category=documents`).
  Future<Result<ManualEntryEvidenceFile>> uploadEvidenceFile(
    ManualEntryEvidenceFile file,
  );

  /// Create a manual attendance record (`POST /attendance/manual`).
  /// Returns the new attendance id when present.
  Future<Result<String>> recordManualAttendance(Map<String, dynamic> payload);
}
