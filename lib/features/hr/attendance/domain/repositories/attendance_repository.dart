import 'package:gems_core/gems_core.dart';

import '../entities/attendance_overview.dart';

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
}
