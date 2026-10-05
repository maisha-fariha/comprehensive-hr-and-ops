/// A threshold on a schedule's reading ("systolic is above 140").
class CheckAlertRule {
  final String field;
  final String operator;
  final Object value;
  final String severity;
  final bool raiseIncident;

  const CheckAlertRule({
    required this.field,
    required this.operator,
    required this.value,
    this.severity = 'needs_attention',
    this.raiseIncident = false,
  });
}

/// `/recurring-checks/schedules` row.
class CheckSchedule {
  final String id;
  final String clientId;
  final String residenceId;
  final String? name;
  final String? checkType;
  final String? instructions;
  final String? frequency;
  final int? intervalMinutes;
  final List<int> timesOfDay;
  final List<int> weekdays;
  final int? dayOfMonth;
  final String? assignedRole;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final DateTime? effectiveFrom;
  final DateTime? expiresAt;
  final bool alertEnabled;
  final List<CheckAlertRule> alertRules;
  final List<String> notifyRoles;
  final bool isActive;
  final int? activeFromMinute;
  final int? activeToMinute;
  final String? clientName;
  final String? residenceName;

  const CheckSchedule({
    required this.id,
    required this.clientId,
    required this.residenceId,
    this.name,
    this.checkType,
    this.instructions,
    this.frequency,
    this.intervalMinutes,
    this.timesOfDay = const [],
    this.weekdays = const [],
    this.dayOfMonth,
    this.assignedRole,
    this.assignedStaffId,
    this.assignedStaffName,
    this.effectiveFrom,
    this.expiresAt,
    this.alertEnabled = false,
    this.alertRules = const [],
    this.notifyRoles = const [],
    this.isActive = true,
    this.activeFromMinute,
    this.activeToMinute,
    this.clientName,
    this.residenceName,
  });
}

class CheckSchedulePage {
  final List<CheckSchedule> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const CheckSchedulePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

/// A recorded check (`/recurring-checks/entries`), also nested on instances.
class CheckEntry {
  final String id;
  final String? checkName;
  final String? staffName;
  final DateTime? checkedAt;
  final String note;
  final bool? recordedOnDuty;
  final String? coveredForName;
  final String? takeoverReason;

  /// In API order, `...Unit` keys included.
  final Map<String, Object?> result;
  final String? outcome;

  const CheckEntry({
    required this.id,
    required this.note,
    this.checkName,
    this.staffName,
    this.checkedAt,
    this.recordedOnDuty,
    this.coveredForName,
    this.takeoverReason,
    this.result = const {},
    this.outcome,
  });
}

/// One due occurrence (`/recurring-checks/instances`).
class CheckInstance {
  final String id;
  final String scheduleId;
  final String clientId;
  final String residenceId;
  final DateTime dueAt;
  final String status;
  final String? statusNote;
  final bool? statusOnDuty;
  final String? assignedRole;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? checkName;
  final String? checkType;
  final String? instructions;
  final String? clientName;
  final String? roomNumber;
  final CheckEntry? entry;

  const CheckInstance({
    required this.id,
    required this.scheduleId,
    required this.clientId,
    required this.residenceId,
    required this.dueAt,
    required this.status,
    this.statusNote,
    this.statusOnDuty,
    this.assignedRole,
    this.assignedStaffId,
    this.assignedStaffName,
    this.checkName,
    this.checkType,
    this.instructions,
    this.clientName,
    this.roomNumber,
    this.entry,
  });

  static const openStatuses = {'pending', 'needs_assignment', 'in_progress'};

  bool get open => openStatuses.contains(status);
}

/// `/recurring-checks/instances/{id}/available-staff` row.
class CheckAvailableStaff {
  final String staffId;
  final String name;
  final String? shiftTitle;
  final DateTime? shiftStartsAt;
  final DateTime? shiftEndsAt;

  const CheckAvailableStaff({
    required this.staffId,
    required this.name,
    this.shiftTitle,
    this.shiftStartsAt,
    this.shiftEndsAt,
  });
}

class CheckOption {
  final String id;
  final String label;

  const CheckOption({required this.id, required this.label});
}
