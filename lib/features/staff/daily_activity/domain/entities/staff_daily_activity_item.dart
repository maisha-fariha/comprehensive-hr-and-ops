import 'package:flutter/foundation.dart';

/// One row in the Client Activity Registry.
@immutable
class StaffDailyActivityItem {
  final String id;
  final String activityCode;
  final String clientId;
  final String residentName;
  final String residenceName;
  final String activityType;
  final String activityTypeLabel;
  final String description;
  final String notes;
  final String recordedByName;
  final String recordedByInitials;
  final String? recordedByStaffId;
  final DateTime? activityDate;
  final DateTime? occurredAt;
  final String dateTimeLabel;
  final String status;
  final String statusLabel;

  const StaffDailyActivityItem({
    required this.id,
    required this.activityCode,
    required this.clientId,
    required this.residentName,
    required this.residenceName,
    required this.activityType,
    required this.activityTypeLabel,
    required this.description,
    required this.notes,
    required this.recordedByName,
    required this.recordedByInitials,
    this.recordedByStaffId,
    this.activityDate,
    this.occurredAt,
    required this.dateTimeLabel,
    required this.status,
    required this.statusLabel,
  });
}
