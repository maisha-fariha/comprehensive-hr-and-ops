class DailyLogOption {
  final String id;
  final String label;

  const DailyLogOption({required this.id, required this.label});
}

class DailyLogPage<T> {
  final List<T> items;
  final int total;
  final int totalPages;

  const DailyLogPage({required this.items, required this.total, required this.totalPages});
}

/// A resident-day with entries on it (`status=review`).
class DailyLogReviewRow {
  final String id;
  final String clientId;
  final String clientName;
  final String logDate;
  final int entriesCount;

  const DailyLogReviewRow({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.logDate,
    required this.entriesCount,
  });
}

/// A resident-day with nothing written (`status=missing`).
class DailyLogMissingRow {
  final String clientId;
  final String clientName;
  final String logDate;

  const DailyLogMissingRow({
    required this.clientId,
    required this.clientName,
    required this.logDate,
  });
}

class DailyLogEntryFlag {
  final String category;
  final String? note;
  final DateTime? raisedAt;
  final DateTime? resolvedAt;

  const DailyLogEntryFlag({
    required this.category,
    this.note,
    this.raisedAt,
    this.resolvedAt,
  });
}

class DailyLogAttachment {
  final String id;
  final String fileUrl;

  const DailyLogAttachment({required this.id, required this.fileUrl});

  String get fileName => fileUrl.split('/').last;
}

class DailyLogEntry {
  final String id;
  final String body;
  final String? clientId;
  final DateTime? occurredAt;
  final DateTime? createdAt;
  final String? authorName;
  final String? amendsEntryId;
  final String? amendmentReason;
  final bool isSuperseded;
  final String? shift;
  final String? logType;
  final String? source;
  final bool recordedAfterLock;

  /// In API order.
  final Map<String, Object?> observations;
  final bool? wellnessCheckCompleted;
  final bool? bedCheckCompleted;
  final DateTime? remindAt;
  final List<DailyLogAttachment> attachments;
  final DailyLogEntryFlag? flag;
  final List<DailyLogEntry> amendmentChain;

  const DailyLogEntry({
    required this.id,
    required this.body,
    this.clientId,
    this.occurredAt,
    this.createdAt,
    this.authorName,
    this.amendsEntryId,
    this.amendmentReason,
    this.isSuperseded = false,
    this.shift,
    this.logType,
    this.source,
    this.recordedAfterLock = false,
    this.observations = const {},
    this.wellnessCheckCompleted,
    this.bedCheckCompleted,
    this.remindAt,
    this.attachments = const [],
    this.flag,
    this.amendmentChain = const [],
  });

  DateTime? get at => occurredAt ?? createdAt;
}

/// A recurring check recorded on the day.
class DailyLogCheck {
  final String id;
  final DateTime checkedAt;
  final String? checkName;
  final String note;
  final Map<String, Object?> result;
  final String? outcome;
  final String? recordedBy;

  const DailyLogCheck({
    required this.id,
    required this.checkedAt,
    required this.note,
    this.checkName,
    this.result = const {},
    this.outcome,
    this.recordedBy,
  });
}

class DailyLogDay {
  final List<DailyLogEntry> entries;
  final List<DailyLogCheck> checks;

  const DailyLogDay({this.entries = const [], this.checks = const []});
}

/// `/daily-logs/shifts` row: one resident on one running shift.
class DailyLogShiftRow {
  final String id;
  final String status;
  final String? summary;
  final String? clientName;
  final String? shiftTitle;
  final String? shiftType;
  final DateTime? shiftStartsAt;
  final DateTime? shiftEndsAt;
  final String? completedByName;
  final String? lockedByName;

  const DailyLogShiftRow({
    required this.id,
    required this.status,
    this.summary,
    this.clientName,
    this.shiftTitle,
    this.shiftType,
    this.shiftStartsAt,
    this.shiftEndsAt,
    this.completedByName,
    this.lockedByName,
  });
}

/// `/residence-activity` row ("House activity").
class ResidenceActivityRow {
  final String id;
  final String module;
  final String activityType;
  final String summary;
  final DateTime occurredAt;
  final String? clientName;
  final String? staffName;
  final String? residenceName;
  final String? entityType;
  final String? entityId;

  const ResidenceActivityRow({
    required this.id,
    required this.module,
    required this.activityType,
    required this.summary,
    required this.occurredAt,
    this.clientName,
    this.staffName,
    this.residenceName,
    this.entityType,
    this.entityId,
  });
}

class CareFlagSource {
  final String kind;
  final String? clientName;
  final String? logDate;
  final String excerpt;

  const CareFlagSource({
    required this.kind,
    required this.excerpt,
    this.clientName,
    this.logDate,
  });
}

/// Open `/care-flags` row on the Priority Notes board.
class CareFlag {
  final String id;
  final String category;
  final String? note;
  final DateTime? raisedAt;
  final String? raisedBy;
  final DateTime? resolvedAt;
  final String? residenceName;
  final CareFlagSource? source;

  const CareFlag({
    required this.id,
    required this.category,
    this.note,
    this.raisedAt,
    this.raisedBy,
    this.resolvedAt,
    this.residenceName,
    this.source,
  });
}

class DailyLogUpload {
  final String fileUrl;
  final String? fileType;
  final String? fileName;

  const DailyLogUpload({required this.fileUrl, this.fileType, this.fileName});
}
