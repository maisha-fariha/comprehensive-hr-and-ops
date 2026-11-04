class DailyLogOption {
  final String id;
  final String label;
  final String? residenceId;

  const DailyLogOption({required this.id, required this.label, this.residenceId});
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
  final String? shiftLabel;
  final String? summary;
  final String? residenceId;

  const DailyLogReviewRow({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.logDate,
    required this.entriesCount,
    this.shiftLabel,
    this.summary,
    this.residenceId,
  });

  DailyLogReviewRow atResidence(String residenceId) => DailyLogReviewRow(
        id: id,
        clientId: clientId,
        clientName: clientName,
        logDate: logDate,
        entriesCount: entriesCount,
        shiftLabel: shiftLabel,
        summary: summary,
        residenceId: residenceId,
      );
}

/// One gap on a missing resident-day (`gaps[]` from `/daily-logs?status=missing`).
class DailyLogGap {
  final String type;
  final String detail;

  const DailyLogGap({required this.type, required this.detail});
}

/// A resident-day with nothing written (`status=missing`).
class DailyLogMissingRow {
  final String clientId;
  final String clientName;
  final String logDate;
  final List<DailyLogGap> gaps;
  final String? residenceId;

  const DailyLogMissingRow({
    required this.clientId,
    required this.clientName,
    required this.logDate,
    this.gaps = const [],
    this.residenceId,
  });

  DailyLogMissingRow atResidence(String residenceId) => DailyLogMissingRow(
        clientId: clientId,
        clientName: clientName,
        logDate: logDate,
        gaps: gaps,
        residenceId: residenceId,
      );
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

/// One gap or open flag on a board resident row.
class DailyLogBoardGap {
  final String type;
  final String detail;

  const DailyLogBoardGap({required this.type, required this.detail});
}

class DailyLogBoardFlag {
  final String id;
  final String category;

  const DailyLogBoardFlag({required this.id, required this.category});
}

/// `/daily-logs/board` resident row.
class DailyLogBoardResident {
  final String clientId;
  final String name;
  final String? room;
  final String? photoUrl;
  final int notes;
  final DateTime? lastNoteAt;
  final String? lastNoteBy;
  final List<DailyLogBoardGap> gaps;
  final List<DailyLogBoardFlag> flags;

  const DailyLogBoardResident({
    required this.clientId,
    required this.name,
    this.room,
    this.photoUrl,
    this.notes = 0,
    this.lastNoteAt,
    this.lastNoteBy,
    this.gaps = const [],
    this.flags = const [],
  });

  bool get needsSomething => gaps.isNotEmpty || notes == 0;
  bool get isFlagged => flags.isNotEmpty;
}

/// Staff on a board shift (`onDuty[]`).
class DailyLogBoardOnDuty {
  final String staffId;
  final String name;
  final DateTime? clockedInAt;
  final DateTime? clockedOutAt;
  final bool late;

  const DailyLogBoardOnDuty({
    required this.staffId,
    required this.name,
    this.clockedInAt,
    this.clockedOutAt,
    this.late = false,
  });

  bool get notClockedIn => clockedInAt == null;
}

class DailyLogBoardShift {
  final String id;
  final String? title;
  final String? shiftType;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<DailyLogBoardOnDuty> onDuty;

  const DailyLogBoardShift({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    this.title,
    this.shiftType,
    this.onDuty = const [],
  });
}

class DailyLogBoardHandover {
  final String id;
  final String status;
  final DateTime? submittedAt;
  final String? from;
  final String? to;
  final String? givenBy;
  final DateTime? takenAt;
  final List<String> takenBy;
  final int tasks;
  final int tasksWaiting;

  const DailyLogBoardHandover({
    required this.id,
    required this.status,
    this.submittedAt,
    this.from,
    this.to,
    this.givenBy,
    this.takenAt,
    this.takenBy = const [],
    this.tasks = 0,
    this.tasksWaiting = 0,
  });

  bool get notTakenYet => takenAt == null;
}

/// Note marked for the next shift on the board.
class DailyLogBoardNextNote {
  final String id;
  final String clientId;
  final String clientName;
  final String body;
  final DateTime occurredAt;
  final String? author;
  final bool inHandover;

  const DailyLogBoardNextNote({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.body,
    required this.occurredAt,
    this.author,
    this.inHandover = false,
  });
}

class DailyLogBoardCounts {
  final int notesMissing;
  final int dosesMissing;
  final int checksMissing;
  final int openFlags;

  const DailyLogBoardCounts({
    this.notesMissing = 0,
    this.dosesMissing = 0,
    this.checksMissing = 0,
    this.openFlags = 0,
  });
}

/// Web Today hub payload (`GET /daily-logs/board`).
class DailyLogBoard {
  final String residenceId;
  final String date;
  final List<DailyLogBoardNextNote> forNextShift;
  final List<DailyLogBoardNextNote> notHandedOver;
  final DailyLogBoardCounts counts;
  final List<DailyLogBoardResident> residents;
  final List<DailyLogBoardShift> shifts;
  final List<DailyLogBoardHandover> handovers;

  const DailyLogBoard({
    required this.residenceId,
    required this.date,
    this.forNextShift = const [],
    this.notHandedOver = const [],
    this.counts = const DailyLogBoardCounts(),
    this.residents = const [],
    this.shifts = const [],
    this.handovers = const [],
  });
}

/// One item on `/clients/:id/daily-activity-feed`.
class DailyActivityFeedItem {
  final String id;
  final String module;
  final String type;
  final String title;
  final String detail;
  final DateTime occurredAt;
  final String? staffName;
  final String? status;

  const DailyActivityFeedItem({
    required this.id,
    required this.module,
    required this.type,
    required this.title,
    required this.detail,
    required this.occurredAt,
    this.staffName,
    this.status,
  });
}

class DailyActivityFeed {
  final String clientId;
  final String date;
  final List<DailyActivityFeedItem> items;
  final Map<String, int> counts;

  const DailyActivityFeed({
    required this.clientId,
    required this.date,
    this.items = const [],
    this.counts = const {},
  });
}

/// Web Resident Activity "Daily summary" (`/daily-summaries/*`).
class DailySummary {
  final String id;
  final String clientId;
  final String? residenceId;
  final String day;
  final String summary;
  final String? familySummary;
  final List<String> attention;
  /// Source kind → count (care notes, doses, …).
  final Map<String, int> sources;
  final String? model;
  final String? generatedBy;
  final DateTime? generatedAt;
  final DateTime? editedAt;
  final DateTime? sharedAt;

  const DailySummary({
    required this.id,
    required this.clientId,
    required this.day,
    required this.summary,
    this.residenceId,
    this.familySummary,
    this.attention = const [],
    this.sources = const {},
    this.model,
    this.generatedBy,
    this.generatedAt,
    this.editedAt,
    this.sharedAt,
  });

  bool get isShared => sharedAt != null;

  DailySummary copyWith({
    String? summary,
    String? familySummary,
    DateTime? editedAt,
    DateTime? sharedAt,
    bool clearSharedAt = false,
  }) =>
      DailySummary(
        id: id,
        clientId: clientId,
        residenceId: residenceId,
        day: day,
        summary: summary ?? this.summary,
        familySummary: familySummary ?? this.familySummary,
        attention: attention,
        sources: sources,
        model: model,
        generatedBy: generatedBy,
        generatedAt: generatedAt,
        editedAt: editedAt ?? this.editedAt,
        sharedAt: clearSharedAt ? null : (sharedAt ?? this.sharedAt),
      );
}
