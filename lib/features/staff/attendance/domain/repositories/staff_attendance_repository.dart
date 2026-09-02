import 'package:gems_core/gems_core.dart';

import '../entities/staff_attendance_overview.dart';

/// Contract for the staff member's live attendance/clock status.
abstract class StaffAttendanceRepository {
  Future<Result<StaffAttendanceOverview>> getOverview();

  Future<Result<void>> checkIn({String? shiftId, String? residenceId});

  Future<Result<void>> checkOut({String? shiftId, String? residenceId});

  Future<Result<void>> startBreak({String? residenceId});

  Future<Result<void>> endBreak({String? residenceId});
}
