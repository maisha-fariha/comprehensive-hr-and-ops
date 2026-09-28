import 'package:gems_core/gems_core.dart';

import '../../../../hr/attendance/domain/entities/manual_entry_options.dart';
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

  /// Residences available to this staff member for Manual Entry.
  Future<Result<List<ManualEntryResidenceOption>>> getResidences();

  /// Optional rostered shifts for the signed-in staff member.
  Future<Result<List<ManualEntryShiftOption>>> getRosteredShifts({
    String? residenceId,
    DateTime? around,
  });

  /// Upload supporting evidence for manual entry.
  Future<Result<ManualEntryEvidenceFile>> uploadEvidenceFile(
    ManualEntryEvidenceFile file,
  );

  /// `POST /attendance/manual` — staff self-service manual entry (BUG_Report005).
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
  });
}
