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

/// Result of `POST /shifts/conflicts`.
class ShiftConflictsResult {
  final bool hasConflict;
  final List<ShiftScheduleConflict> conflicts;
  final List<ShiftLeaveConflict> leave;

  const ShiftConflictsResult({
    this.hasConflict = false,
    this.conflicts = const [],
    this.leave = const [],
  });

  bool get blocksStaffing => conflicts.isNotEmpty || leave.isNotEmpty;
}
