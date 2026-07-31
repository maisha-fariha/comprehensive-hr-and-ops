import 'package:gems_core/gems_core.dart';

import '../../domain/entities/staff_attendance_overview.dart';
import '../../domain/repositories/staff_attendance_repository.dart';

/// Local implementation of [StaffAttendanceRepository].
///
/// There is no backend endpoint for live attendance/clock status yet, so
/// this returns the exact static content shown in the reference
/// screenshot. Replace the body of [getOverview] with a real
/// `ApiService`/`BaseRepository` call once an API contract exists — the
/// domain layer and every widget above it will keep working unchanged.
class StaffAttendanceRepositoryImpl implements StaffAttendanceRepository {
  @override
  Future<Result<StaffAttendanceOverview>> getOverview() async {
    return Result.success(
      const StaffAttendanceOverview(
        isOnShift: true,
        shiftStartedLabel: 'Started at 7:02 AM',
        shiftLocationName: 'Sunrise Home',
        shiftTimeRange: '7:00 AM – 3:00 PM',
        elapsedTimeLabel: '04:18:32',
        isWithinGeofence: true,
        geofenceAddress: '700 Sunrise Way, Pleasantville, CA · Accuracy: 12 ft',
        isSelfieVerified: true,
        selfieVerifiedLabel: 'Verified · 7:02 AM',
        isOnBreak: false,
        breakStatusLabel: 'No break started',
      ),
    );
  }
}
