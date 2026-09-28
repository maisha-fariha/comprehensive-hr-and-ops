import 'package:flutter/foundation.dart';

/// Row from `GET /recurring-checks/instances?from&to&mine=true`.
@immutable
class RecurringCheckInstance {
  final String id;
  final String scheduleId;
  final String clientId;
  final String clientName;
  final String roomLabel;
  final String residenceId;
  final String residenceName;
  final String title;
  final String statusRaw;
  final String dueLabel;
  final String location;
  final String assignedStaffName;
  final String assignedRole;
  final String statusNote;
  final bool hasEntry;

  const RecurringCheckInstance({
    required this.id,
    this.scheduleId = '',
    this.clientId = '',
    this.clientName = '',
    this.roomLabel = '',
    this.residenceId = '',
    this.residenceName = '',
    required this.title,
    this.statusRaw = '',
    this.dueLabel = '',
    this.location = '',
    this.assignedStaffName = '',
    this.assignedRole = '',
    this.statusNote = '',
    this.hasEntry = false,
  });

  bool get isOpen {
    final s = statusRaw.toLowerCase();
    return s.isEmpty ||
        s == 'pending' ||
        s == 'due' ||
        s == 'open' ||
        s == 'in_progress';
  }

  bool get isRecorded {
    final s = statusRaw.toLowerCase();
    return hasEntry ||
        s == 'requires_review' ||
        s == 'recorded' ||
        s == 'completed' ||
        s == 'skipped';
  }

  String get clientRoomDueLabel {
    final parts = [
      if (clientName.trim().isNotEmpty) clientName.trim(),
      if (roomLabel.trim().isNotEmpty) roomLabel.trim(),
      if (dueLabel.trim().isNotEmpty) dueLabel.trim(),
    ];
    return parts.join(' · ');
  }

  String get assignmentLabel {
    if (assignedStaffName.trim().isNotEmpty) {
      return 'Assigned to ${assignedStaffName.trim()}';
    }
    if (assignedRole.trim().isNotEmpty) return 'Assigned to $assignedRole';
    return 'Whoever is on shift';
  }
}
