/// Status filter values accepted by `GET /attendance?status=`.
enum AttendanceStatusFilter {
  present('present', 'Present'),
  late('late', 'Late'),
  missed('missed', 'Missed'),
  pendingApproval('pending_approval', 'Pending approval'),
  rejected('rejected', 'Rejected');

  final String value;
  final String label;

  const AttendanceStatusFilter(this.value, this.label);

  static AttendanceStatusFilter? fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// Geofence / photo facts captured at one end of a clock record.
class AttendanceCheckpoint {
  final String geofenceStatus;
  final int? distanceMeters;
  final int? accuracyMeters;
  final String? selfieUrl;

  const AttendanceCheckpoint({
    this.geofenceStatus = 'not_provided',
    this.distanceMeters,
    this.accuracyMeters,
    this.selfieUrl,
  });
}

class AttendanceEvidence {
  final String fileUrl;
  final String? fileType;

  const AttendanceEvidence({required this.fileUrl, this.fileType});
}

/// One row of `GET /attendance`.
class AttendanceRecord {
  final String id;
  final String staffId;
  final String staffName;
  final String staffInitials;
  final String? staffRole;
  final String residenceId;
  final String residenceName;
  final String? shiftId;
  final DateTime? shiftStartsAt;
  final DateTime? shiftEndsAt;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int breakMinutes;
  final int? workedMinutes;
  final String status;
  final bool isManual;
  final AttendanceCheckpoint checkIn;
  final String? reasonCategory;
  final DateTime? originalCheckInAt;
  final DateTime? originalCheckOutAt;
  final List<AttendanceEvidence> evidence;
  final String? adminNote;
  final int? lateMinutes;
  final int? earlyDepartureMinutes;
  final String? earlyDepartureReason;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.staffInitials,
    this.staffRole,
    required this.residenceId,
    required this.residenceName,
    this.shiftId,
    this.shiftStartsAt,
    this.shiftEndsAt,
    this.checkInAt,
    this.checkOutAt,
    this.breakMinutes = 0,
    this.workedMinutes,
    required this.status,
    this.isManual = false,
    this.checkIn = const AttendanceCheckpoint(),
    this.reasonCategory,
    this.originalCheckInAt,
    this.originalCheckOutAt,
    this.evidence = const [],
    this.adminNote,
    this.lateMinutes,
    this.earlyDepartureMinutes,
    this.earlyDepartureReason,
    this.notes,
  });

  bool get needsApproval => status == 'pending_approval';
}

class AttendanceRecordPage {
  final List<AttendanceRecord> records;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const AttendanceRecordPage({
    required this.records,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  static const empty = AttendanceRecordPage(
    records: [],
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 0,
  );
}

/// `GET /attendance/summary` — the KPI cards.
class AttendanceSummary {
  final int present;
  final int late;
  final int missed;

  /// Open manual claims (`openClaims`), not `byStatus.pending_approval`.
  final int pendingApproval;
  final int? averageLateMinutes;
  final int lateStaffCount;

  const AttendanceSummary({
    this.present = 0,
    this.late = 0,
    this.missed = 0,
    this.pendingApproval = 0,
    this.averageLateMinutes,
    this.lateStaffCount = 0,
  });

  String get lateCaption {
    final average = averageLateMinutes;
    if (average == null) return 'Clocked in after the shift started';
    final people = lateStaffCount == 1 ? 'person' : 'people';
    return '${average}m average delay · $lateStaffCount $people';
  }
}

/// The signed-in user's current (or next) rostered shift for clocking in.
class AttendanceShiftWindow {
  final String shiftId;
  final String? residenceId;
  final String? residenceName;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isCurrent;

  const AttendanceShiftWindow({
    required this.shiftId,
    this.residenceId,
    this.residenceName,
    required this.startsAt,
    required this.endsAt,
    required this.isCurrent,
  });

  /// Clocking in opens 15 minutes before the shift starts.
  DateTime get opensAt => startsAt.subtract(const Duration(minutes: 15));
}

/// The user's own attendance record that has a clock-in but no clock-out.
class OpenAttendance {
  final String id;
  final String residenceId;
  final String? residenceName;

  const OpenAttendance({
    required this.id,
    required this.residenceId,
    this.residenceName,
  });
}
