import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/client_status_summary.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/daily_logs_overview.dart';
import '../../domain/entities/handover_entry.dart';
import '../../domain/entities/handover_note.dart';
import '../../domain/entities/missing_log_entry.dart';
import '../../domain/entities/submitted_log_entry.dart';

abstract final class DailyLogsMapper {
  static DailyLogsOverview compose({
    required dynamic reviewBody,
    required dynamic flagsBody,
    required dynamic missingBody,
    required dynamic handoversBody,
    String? residenceName,
  }) {
    final submitted = JsonCodec.unwrapList(reviewBody)
        .whereType<Map>()
        .map((item) => _submitted(JsonCodec.asMap(item)))
        .toList();
    final flags = JsonCodec.unwrapList(flagsBody).whereType<Map>().toList();
    final missing = JsonCodec.unwrapList(missingBody)
        .whereType<Map>()
        .map(
          (item) => _missing(
            JsonCodec.asMap(item),
            residenceName: residenceName,
          ),
        )
        .toList();
    final handovers = JsonCodec.unwrapList(handoversBody)
        .whereType<Map>()
        .map((item) => _handover(JsonCodec.asMap(item)))
        .toList();
    final pending = submitted
        .where((item) => item.status != LogReviewStatus.complete)
        .length;
    final flagged = submitted
        .where((item) => item.status == LogReviewStatus.flagged)
        .length;
    final pendingAck = handovers.where((item) => !item.isAcknowledged).length;
    final urgent = handovers.where((item) => item.isUrgent).length;

    return DailyLogsOverview(
      reviewStats: [
        DailyLogSummaryStat(
          tag: DailyLogStatTag.submittedToday,
          value: '${submitted.length}',
          label: 'Submitted Today',
        ),
        DailyLogSummaryStat(
          tag: DailyLogStatTag.pendingReview,
          value: '$pending',
          label: 'Pending Review',
        ),
        DailyLogSummaryStat(
          tag: DailyLogStatTag.flaggedNotes,
          value: '${flags.isEmpty ? flagged : flags.length}',
          label: 'Flagged Notes',
          isHighlighted: true,
        ),
      ],
      submittedLogsTotalCount: submitted.length,
      submittedLogs: submitted,
      clientStatusSummaries: _clients(reviewBody, flagsBody),
      missingStats: [
        DailyLogSummaryStat(
          tag: DailyLogStatTag.missingLogs,
          value: '${missing.length}',
          label: 'Missing Logs',
        ),
        DailyLogSummaryStat(
          tag: DailyLogStatTag.overdue,
          value: '${missing.length}',
          label: 'Overdue',
        ),
        DailyLogSummaryStat(
          tag: DailyLogStatTag.followUpRequired,
          value: '${flags.length}',
          label: 'Follow Up',
        ),
      ],
      missingLogs: missing,
      handoverStats: [
        DailyLogSummaryStat(
          tag: DailyLogStatTag.activeHandovers,
          value: '${handovers.length}',
          label: 'Active Handovers',
        ),
        DailyLogSummaryStat(
          tag: DailyLogStatTag.pendingAcknowledgement,
          value: '$pendingAck',
          label: 'Pending Ack',
        ),
        DailyLogSummaryStat(
          tag: DailyLogStatTag.urgentNotes,
          value: '$urgent',
          label: 'Urgent Notes',
        ),
      ],
      handoverEntries: handovers,
    );
  }

  /// Manager review queue rows are client-centric (`clientName`, `entriesCount`).
  static SubmittedLogEntry _submitted(Map<String, dynamic> json) {
    final name = JsonCodec.stringOr(
      json['clientName'] ?? IsoDateRange.personName(json['client']),
      'Unknown',
    );
    final entriesCount = JsonCodec.integer(json['entriesCount']);
    final logDate = JsonCodec.dateTime(json['logDate']);
    final at = JsonCodec.dateTime(json['createdAt'] ?? json['submittedAt']);
    final shiftLabel = entriesCount == null
        ? (logDate == null
            ? 'Daily log'
            : IsoDateRange.formatShortDate(logDate.toLocal()))
        : '$entriesCount ${entriesCount == 1 ? 'entry' : 'entries'}';

    return SubmittedLogEntry(
      id: JsonCodec.stringOr(
        json['id'] ?? json['clientId'],
        name,
      ),
      initials: IsoDateRange.initials(name),
      shiftLabel: shiftLabel,
      staffName: name,
      submittedTimeLabel: at == null
          ? JsonCodec.stringOr(json['status'], 'Review')
          : 'Submitted ${IsoDateRange.timeLabel(at.toLocal())}',
      status: _reviewStatus(json['status'] ?? json['reviewStatus']),
    );
  }

  /// Missing rows are client + logDate (no staff fields in Manager sample).
  static MissingLogEntry _missing(
    Map<String, dynamic> json, {
    String? residenceName,
  }) {
    final name = JsonCodec.stringOr(
      json['clientName'] ?? IsoDateRange.personName(json['client']),
      'Unknown',
    );
    final logDate = JsonCodec.dateTime(json['logDate']) ??
        DateTime.tryParse(JsonCodec.stringOr(json['logDate'], ''));
    final id = JsonCodec.stringOr(
      json['id'] ??
          '${json['clientId'] ?? name}-${json['logDate'] ?? ''}',
      name,
    );

    return MissingLogEntry(
      id: id,
      staffName: name,
      initials: IsoDateRange.initials(name),
      locationLabel: JsonCodec.stringOr(
        json['residenceName'] ??
            JsonCodec.mapAt(json, 'residence')?['name'] ??
            residenceName,
        '',
      ),
      overdueLabel: logDate == null
          ? JsonCodec.stringOr(json['status'], 'Missing')
          : IsoDateRange.formatShortDate(logDate.toLocal()),
      expectedShiftLabel: 'Daily log',
      assignedStaffName: '—',
      assignedStaffInitials: '—',
    );
  }

  static HandoverEntry _handover(Map<String, dynamic> json) {
    final from = json['fromStaff'] ??
        json['outgoingStaff'] ??
        json['from'] ??
        json['author'];
    // Prefer the latest acknowledger when `acknowledgements` is a list.
    dynamic fromPerson = from;
    final ackList = JsonCodec.listAt(json, 'acknowledgements');
    if (fromPerson == null && ackList.isNotEmpty && ackList.first is Map) {
      final ack = JsonCodec.asMap(ackList.first);
      fromPerson = ack['user'] ?? ack['staff'];
    }

    final to = json['toStaff'] ?? json['incomingStaff'] ?? json['to'];
    final fromName =
        fromPerson == null ? null : IsoDateRange.personName(fromPerson);
    final toName = to == null ? null : IsoDateRange.personName(to);
    final summary = JsonCodec.string(json['summary']);
    final status = (json['status'] ?? '').toString().toLowerCase();
    final acknowledged = JsonCodec.boolean(json['acknowledged']) ??
        (status == 'acknowledged' ||
            status == 'viewed' ||
            JsonCodec.dateTime(json['firstViewedAt']) != null ||
            ackList.isNotEmpty);

    final notes = <HandoverNote>[];
    if (summary != null && summary.trim().isNotEmpty) {
      notes.add(
        HandoverNote(
          type: HandoverNoteType.observation,
          title: 'Summary',
          description: summary.trim(),
        ),
      );
    }
    for (final action in JsonCodec.listAt(json, 'pendingActions')) {
      final text = action?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      notes.add(
        HandoverNote(
          type: HandoverNoteType.task,
          title: 'Pending action',
          description: text,
        ),
      );
    }
    for (final item in JsonCodec.listAt(json, 'notes')) {
      if (item is! Map) continue;
      final row = JsonCodec.asMap(item);
      notes.add(
        HandoverNote(
          type: _noteType(row['type'] ?? row['kind']),
          title: JsonCodec.stringOr(row['title'] ?? row['label'], 'Note'),
          description: JsonCodec.stringOr(
            row['body'] ?? row['text'] ?? row['note'],
            '',
          ),
        ),
      );
    }

    final createdAt = JsonCodec.dateTime(
      json['submittedAt'] ?? json['createdAt'],
    );
    final fromShiftMap = JsonCodec.mapAt(json, 'fromShift');
    final toShiftMap = JsonCodec.mapAt(json, 'toShift');
    final fromShift = JsonCodec.stringOr(
      json['fromShiftName'] ??
          fromShiftMap?['title'] ??
          fromShiftMap?['name'] ??
          json['fromPeriod'],
      createdAt == null
          ? 'Handover'
          : IsoDateRange.formatShortDate(createdAt.toLocal()),
    );
    final toShift = JsonCodec.stringOr(
      json['toShiftName'] ??
          toShiftMap?['title'] ??
          toShiftMap?['name'] ??
          json['toPeriod'],
      JsonCodec.stringOr(json['status'], 'Submitted'),
    );

    final needsAttention = JsonCodec.listAt(json, 'clientUpdates')
        .whereType<Map>()
        .any((row) {
      final s = (row['status'] ?? '').toString().toLowerCase();
      return s.contains('attention') || s.contains('urgent');
    });

    return HandoverEntry(
      id: JsonCodec.stringOr(json['id'], 'handover'),
      fromShiftLabel: fromShift,
      toShiftLabel: toShift,
      isUrgent: JsonCodec.boolean(json['urgent'] ?? json['isUrgent']) ??
          needsAttention,
      tagLabel: JsonCodec.string(json['tag'] ?? json['priority'] ?? json['status']),
      fromStaffName: fromName,
      fromStaffInitials:
          fromName == null ? null : IsoDateRange.initials(fromName),
      toStaffName: toName,
      toStaffInitials: toName == null ? null : IsoDateRange.initials(toName),
      notes: notes,
      isAcknowledged: acknowledged,
      acknowledgementCaption: acknowledged
          ? JsonCodec.string(
                json['acknowledgedByName'] ?? json['acknowledgedLabel'],
              ) ??
              'Acknowledged'
          : JsonCodec.string(json['acknowledgementCaption']) ??
              'Awaiting acknowledgement',
    );
  }

  static List<ClientStatusSummary> _clients(
    dynamic logsBody,
    dynamic flagsBody,
  ) {
    final byClient = <String, ClientStatusSummary>{};
    for (final item in JsonCodec.unwrapList(logsBody).whereType<Map>()) {
      final json = JsonCodec.asMap(item);
      final client = JsonCodec.mapAt(json, 'client') ?? {};
      final name = IsoDateRange.personName(
        client.isEmpty ? json['clientName'] : client,
      );
      if (name == 'Unknown') continue;
      final id = JsonCodec.stringOr(client['id'] ?? json['clientId'], name);
      byClient.putIfAbsent(
        id,
        () => ClientStatusSummary(
          id: id,
          clientName: name,
          statusLabel: JsonCodec.stringOr(json['status'], 'Submitted'),
          isOnTrack: _reviewStatus(json['status']) != LogReviewStatus.flagged,
        ),
      );
    }
    for (final item in JsonCodec.unwrapList(flagsBody).whereType<Map>()) {
      final json = JsonCodec.asMap(item);
      final source = JsonCodec.mapAt(json, 'source') ?? {};
      final client = JsonCodec.mapAt(json, 'client') ?? {};
      final name = IsoDateRange.personName(
        client.isEmpty
            ? (source['clientName'] ?? json['clientName'])
            : client,
      );
      final id = JsonCodec.stringOr(
        client['id'] ?? source['clientId'] ?? json['clientId'],
        name,
      );
      byClient[id] = ClientStatusSummary(
        id: id,
        clientName: name == 'Unknown' ? 'Flagged client' : name,
        statusLabel: JsonCodec.stringOr(
          json['state'] ?? json['status'] ?? json['category'],
          'Flagged',
        ),
        isOnTrack: false,
      );
    }
    return byClient.values.toList();
  }

  static LogReviewStatus _reviewStatus(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase().replaceAll('-', '_')) {
      case 'flagged':
      case 'open':
      case 'attention':
        return LogReviewStatus.flagged;
      case 'review':
      case 'in_review':
      case 'pending':
      case 'submitted':
      case 'needs_review':
        return LogReviewStatus.inReview;
      case 'complete':
      case 'completed':
      case 'approved':
      case 'closed':
        return LogReviewStatus.complete;
      default:
        return LogReviewStatus.inReview;
    }
  }

  static HandoverNoteType _noteType(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'medication':
      case 'mar':
        return HandoverNoteType.medication;
      case 'task':
        return HandoverNoteType.task;
      default:
        return HandoverNoteType.observation;
    }
  }

  const DailyLogsMapper._();
}
