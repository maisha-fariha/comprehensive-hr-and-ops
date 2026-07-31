import 'package:gems_core/gems_core.dart';

import '../entities/attendance_overview.dart';

/// Contract for fetching the "Attendance" screen's data. The presentation
/// layer only ever depends on this interface, so swapping the mocked
/// [AttendanceRepositoryImpl] for a real API-backed implementation later
/// requires no changes above the data layer.
abstract class AttendanceRepository {
  Future<Result<AttendanceOverview>> getOverview();
}
