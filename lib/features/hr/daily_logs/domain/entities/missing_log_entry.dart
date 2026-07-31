import 'package:flutter/foundation.dart';

/// A single card in the Missing tab's "Missing Logs" list.
@immutable
class MissingLogEntry {
  final String id;
  final String staffName;
  final String initials;
  final String locationLabel;
  final String overdueLabel;
  final String expectedShiftLabel;
  final String assignedStaffName;
  final String assignedStaffInitials;

  const MissingLogEntry({
    required this.id,
    required this.staffName,
    required this.initials,
    required this.locationLabel,
    required this.overdueLabel,
    required this.expectedShiftLabel,
    required this.assignedStaffName,
    required this.assignedStaffInitials,
  });
}
