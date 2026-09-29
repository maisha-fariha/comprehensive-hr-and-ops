import 'package:flutter/foundation.dart';

/// Present / Late / Missed / Pending counts from `GET /attendance/summary`.
@immutable
class StaffAttendanceMetrics {
  final int present;
  final int late;
  final int missed;
  final int pendingApproval;

  const StaffAttendanceMetrics({
    this.present = 0,
    this.late = 0,
    this.missed = 0,
    this.pendingApproval = 0,
  });

  static const empty = StaffAttendanceMetrics();
}
