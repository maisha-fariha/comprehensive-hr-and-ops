/// Lightweight shift row used to build the "Has Shift" picker badge.
class ShiftWindowRow {
  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final List<String> staffIds;

  const ShiftWindowRow({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.staffIds,
  });
}

/// One overlapping shift from `POST /shifts/conflicts` → `conflicts[]`.
class ShiftScheduleConflict {
  final String staffId;
  final String staffName;
  final String shiftId;
  final String? residenceName;
  final String label;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const ShiftScheduleConflict({
    required this.staffId,
    required this.staffName,
    required this.shiftId,
    required this.label,
    this.residenceName,
    this.startsAt,
    this.endsAt,
  });
}

/// Approved leave from `POST /shifts/conflicts` → `leave[]`.
class ShiftLeaveConflict {
  final String staffId;
  final String staffName;
  final String? type;
  final String label;

  const ShiftLeaveConflict({
    required this.staffId,
    required this.staffName,
    required this.label,
    this.type,
  });
}

/// Short rest between shifts from `POST /shifts/conflicts` → `rest[]`.
/// Soft warning: staff can still be rostered with [restOverrideReason].
class ShiftRestConflict {
  final String staffId;
  final String staffName;
  final String label;
  final num restHours;

  const ShiftRestConflict({
    required this.staffId,
    required this.staffName,
    required this.label,
    required this.restHours,
  });

  /// Web shows `4.5` / `5` without trailing zeros.
  String get restHoursLabel {
    final value = restHours;
    if (value == value.roundToDouble()) return '${value.toInt()}';
    return '$value';
  }
}

/// Result of `POST /shifts/conflicts`.
class ShiftConflictsResult {
  final bool hasConflict;
  final List<ShiftScheduleConflict> conflicts;
  final List<ShiftLeaveConflict> leave;
  final List<ShiftRestConflict> rest;
  final int? minimumRestHours;

  const ShiftConflictsResult({
    this.hasConflict = false,
    this.conflicts = const [],
    this.leave = const [],
    this.rest = const [],
    this.minimumRestHours,
  });

  /// Overlap / leave block Next; short rest only requires an override reason.
  bool get blocksStaffing => conflicts.isNotEmpty || leave.isNotEmpty;
}
