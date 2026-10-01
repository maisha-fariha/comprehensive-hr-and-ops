import 'package:flutter/foundation.dart';

@immutable
class DailyActivityAttachment {
  final String fileUrl;
  final String? fileType;

  const DailyActivityAttachment({required this.fileUrl, this.fileType});

  /// The web lists an attachment by its `fileType` (the original file name).
  String get name => fileType ?? 'Attachment';

  Map<String, String> toJson() => {'fileUrl': fileUrl, 'fileType': ?fileType};
}

@immutable
class DailyActivityTimelineEntry {
  final DateTime at;
  final String description;

  const DailyActivityTimelineEntry({required this.at, required this.description});
}

/// One `/client-activities` row, shaped like the web registry row.
@immutable
class DailyActivity {
  final String id;
  final String clientId;
  final String? clientName;
  final String? clientResidence;
  final String? clientLevel;
  final String activityType;
  final String status;
  final String? description;
  final String? notes;
  final String? recordedByStaffId;
  final String? recordedByStaffName;
  final String? authorName;

  /// `YYYY-MM-DD`, the day the activity is filed to.
  final String activityDate;
  final DateTime? occurredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DailyActivityAttachment> attachments;

  const DailyActivity({
    required this.id,
    required this.clientId,
    required this.activityType,
    required this.status,
    required this.activityDate,
    this.clientName,
    this.clientResidence,
    this.clientLevel,
    this.description,
    this.notes,
    this.recordedByStaffId,
    this.recordedByStaffName,
    this.authorName,
    this.occurredAt,
    this.createdAt,
    this.updatedAt,
    this.attachments = const [],
  });

  String get code {
    final head = id.length >= 8 ? id.substring(0, 8) : id;
    return 'ACT-${head.toUpperCase()}';
  }

  String get recordedByName {
    final staff = recordedByStaffName;
    if (staff != null && staff.isNotEmpty) return staff;
    final author = authorName;
    if (author != null && author.isNotEmpty) return author;
    return '—';
  }

  /// "Entered by …" when somebody logged it on another staff member's behalf.
  String get enteredBy {
    final staff = recordedByStaffName;
    final author = authorName;
    if (staff == null || staff.isEmpty || author == null || author.isEmpty) {
      return '';
    }
    return staff == author ? '' : 'Entered by $author';
  }

  bool get isPendingReview => status == 'pending_review';

  /// Web timeline: took place, recorded, and corrected when edited later.
  List<DailyActivityTimelineEntry> get timeline {
    final occurred = occurredAt;
    final created = createdAt;
    final updated = updatedAt;
    final staff = recordedByStaffName;
    final who = staff != null && staff.isNotEmpty ? staff : authorName;
    return [
      if (occurred != null)
        DailyActivityTimelineEntry(at: occurred, description: 'Activity took place'),
      if (created != null)
        DailyActivityTimelineEntry(
          at: created,
          description: who == null || who.isEmpty ? 'Recorded' : 'Recorded by $who',
        ),
      if (created != null &&
          updated != null &&
          updated.difference(created).inMilliseconds > 1000)
        DailyActivityTimelineEntry(at: updated, description: 'Record corrected'),
    ];
  }
}

/// `meta.summary` of the registry list — the four KPI tiles.
@immutable
class DailyActivityStats {
  final int todaysActivities;
  final int activeClients;
  final int staffEntries;
  final int pendingReview;

  const DailyActivityStats({
    this.todaysActivities = 0,
    this.activeClients = 0,
    this.staffEntries = 0,
    this.pendingReview = 0,
  });
}

@immutable
class DailyActivityListResult {
  final List<DailyActivity> items;
  final int total;
  final int totalPages;
  final DailyActivityStats stats;

  const DailyActivityListResult({
    this.items = const [],
    this.total = 0,
    this.totalPages = 0,
    this.stats = const DailyActivityStats(),
  });
}

/// `GET /client-activities/summary` for one resident and month.
@immutable
class DailyActivityMonthSummary {
  /// status → count, in API order.
  final List<(String, int)> byStatus;

  /// activity type → present + absent, in API order.
  final List<(String, int)> byType;

  const DailyActivityMonthSummary({
    this.byStatus = const [],
    this.byType = const [],
  });
}

@immutable
class DailyActivityOption {
  final String id;
  final String name;
  final String subtitle;
  final String? residenceName;
  final String? level;

  const DailyActivityOption({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.residenceName,
    this.level,
  });
}

/// Body for create and edit, built the way the web form builds it.
@immutable
class DailyActivityDraft {
  final String clientId;
  final String activityDate;
  final String activityType;
  final String status;
  final String description;
  final String? notes;
  final DateTime? occurredAt;
  final String? recordedByStaffId;
  final List<DailyActivityAttachment> attachments;

  const DailyActivityDraft({
    required this.clientId,
    required this.activityDate,
    required this.activityType,
    required this.status,
    required this.description,
    this.notes,
    this.occurredAt,
    this.recordedByStaffId,
    this.attachments = const [],
  });

  DailyActivityDraft withAttachments(List<DailyActivityAttachment> files) =>
      DailyActivityDraft(
        clientId: clientId,
        activityDate: activityDate,
        activityType: activityType,
        status: status,
        description: description,
        notes: notes,
        occurredAt: occurredAt,
        recordedByStaffId: recordedByStaffId,
        attachments: files,
      );

  Map<String, dynamic> toJson() {
    final note = notes?.trim();
    final staff = recordedByStaffId;
    return {
      'clientId': clientId,
      'activityDate': activityDate,
      'activityType': activityType,
      'status': status,
      'description': description.trim(),
      if (note != null && note.isNotEmpty) 'notes': note,
      if (occurredAt != null) 'occurredAt': occurredAt!.toUtc().toIso8601String(),
      if (staff != null && staff.isNotEmpty) 'recordedByStaffId': staff,
      if (attachments.isNotEmpty)
        'attachments': [for (final a in attachments) a.toJson()],
    };
  }
}

/// A file picked in the form, uploaded on save.
@immutable
class DailyActivityLocalFile {
  final String path;
  final String name;

  const DailyActivityLocalFile({required this.path, required this.name});
}
