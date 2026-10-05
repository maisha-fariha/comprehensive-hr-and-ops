import 'package:flutter/foundation.dart';

/// Row from `GET /recurring-checks/schedules`.
@immutable
class RecurringCheckSchedule {
  final String id;
  final String name;
  final String checkType;
  final String instructions;
  final String clientId;
  final String clientName;
  final String residenceId;
  final String residenceName;
  final int? intervalMinutes;
  final String frequency;
  final String assignedStaffId;
  final String assignedStaffName;
  final String assignedRole;
  final bool alertEnabled;
  final bool isActive;

  const RecurringCheckSchedule({
    required this.id,
    required this.name,
    this.checkType = '',
    this.instructions = '',
    this.clientId = '',
    this.clientName = '',
    this.residenceId = '',
    this.residenceName = '',
    this.intervalMinutes,
    this.frequency = '',
    this.assignedStaffId = '',
    this.assignedStaffName = '',
    this.assignedRole = '',
    this.alertEnabled = false,
    this.isActive = true,
  });

  String get clientResidenceLabel {
    final parts = [
      if (clientName.trim().isNotEmpty) clientName.trim(),
      if (residenceName.trim().isNotEmpty) residenceName.trim(),
    ];
    return parts.isEmpty ? 'No resident assigned' : parts.join(' · ');
  }

  String get frequencyLabel {
    final minutes = intervalMinutes;
    if (minutes != null && minutes > 0) return 'Every $minutes minutes';
    final raw = frequency.trim().replaceAll('_', ' ');
    if (raw.isEmpty) return 'Interval not set';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String get assigneeLabel {
    if (assignedStaffName.trim().isNotEmpty) return assignedStaffName.trim();
    if (assignedRole.trim().isNotEmpty) return assignedRole.trim();
    return 'Assign';
  }
}
