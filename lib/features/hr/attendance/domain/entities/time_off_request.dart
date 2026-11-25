/// Web Attendance → Time-Off Requests row from
/// `GET /attendance/time-off-requests`.
class TimeOffRequest {
  final String id;
  final String staffId;
  final String staffName;
  final TimeOffType type;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final TimeOffStatus status;
  final String? reason;
  final String? reviewNotes;
  final DateTime? createdAt;

  const TimeOffRequest({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
    this.reason,
    this.reviewNotes,
    this.createdAt,
  });
}

enum TimeOffType {
  annualLeave,
  sick,
  bereavement,
  unpaid,
  other;

  /// API enum value.
  String get apiValue => switch (this) {
        annualLeave => 'annual_leave',
        sick => 'sick',
        bereavement => 'bereavement',
        unpaid => 'unpaid',
        other => 'other',
      };

  String get label => switch (this) {
        annualLeave => 'Annual leave',
        sick => 'Sick',
        bereavement => 'Bereavement',
        unpaid => 'Unpaid',
        other => 'Other',
      };

  static TimeOffType? fromApi(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'annual_leave' => annualLeave,
      'sick' => sick,
      'bereavement' => bereavement,
      'unpaid' => unpaid,
      'other' => other,
      _ => null,
    };
  }
}

enum TimeOffStatus {
  pending,
  approved,
  rejected;

  String get apiValue => name;

  String get label => switch (this) {
        pending => 'Pending',
        approved => 'Approved',
        rejected => 'Rejected',
      };

  static TimeOffStatus? fromApi(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'pending' => pending,
      'approved' => approved,
      'rejected' => rejected,
      _ => null,
    };
  }
}

/// Top-level Attendance screen segment (web Attendance | Time-Off Requests).
enum AttendanceMainTab { records, timeOff }

/// Sub-tabs on the Time-Off Requests pane.
enum TimeOffStatusTab { pending, approved, rejected, all }
