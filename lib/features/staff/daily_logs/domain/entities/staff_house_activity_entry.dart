import 'package:flutter/foundation.dart';

/// House-level activity row (`GET /client-activities`).
@immutable
class StaffHouseActivityEntry {
  final String id;
  final String clientName;
  final String activityType;
  final String status;
  final String dateLabel;
  final String notes;
  final String authorName;

  const StaffHouseActivityEntry({
    required this.id,
    required this.clientName,
    required this.activityType,
    required this.status,
    required this.dateLabel,
    this.notes = '',
    this.authorName = '',
  });
}
