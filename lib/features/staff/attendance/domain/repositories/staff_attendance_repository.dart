import 'package:gems_core/gems_core.dart';

import '../entities/staff_attendance_overview.dart';

/// Contract for fetching the staff member's live attendance/clock status.
/// The presentation layer only ever depends on this interface, so swapping
/// the mocked [StaffAttendanceRepositoryImpl] for a real API-backed
/// implementation later requires no changes above the data layer.
abstract class StaffAttendanceRepository {
  Future<Result<StaffAttendanceOverview>> getOverview();
}
