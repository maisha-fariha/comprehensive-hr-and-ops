import 'package:gems_core/gems_core.dart';

import '../entities/staff_attendance_overview.dart';

/// Contract for the staff member's live attendance/clock status.
abstract class StaffAttendanceRepository {
  Future<Result<StaffAttendanceOverview>> getOverview();

  /// `POST /attendance/check-in`
  Future<Result<void>> checkIn({
    String? shiftId,
    String? residenceId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? selfieUrl,
  });

  /// `POST /attendance/check-out`
  Future<Result<void>> checkOut({
    String? shiftId,
    String? residenceId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? selfieUrl,
  });

  /// `POST /uploads?category=attendance` → URL for [selfieUrl].
  Future<Result<String>> uploadAttendanceSelfie({
    required String localPath,
    required String fileName,
  });

  /// `POST /attendance/break/start`
  Future<Result<void>> startBreak({String? residenceId});

  /// `POST /attendance/break/end`
  Future<Result<void>> endBreak({String? residenceId});

  /// `POST /attendance/manual` — staff self-service manual entry (BUG_Report005).
  Future<Result<String>> recordManualAttendance({
    required String checkInAtIso,
    String? checkOutAtIso,
    String? residenceId,
    String? staffId,
    String? notes,
    String reasonCategory = 'other',
  });
}
