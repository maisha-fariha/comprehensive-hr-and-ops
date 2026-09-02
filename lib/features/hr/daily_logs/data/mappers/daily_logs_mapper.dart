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
  }) {
    final submitted = JsonCodec.unwrapList(reviewBody)
        .whereType<Map>()
        .map((item) => _submitted(JsonCodec.asMap(item)))
        .toList();
    final flags = JsonCodec.unwrapList(flagsBody).whereType<Map>().toList();
    final missing = JsonCodec.unwrapList(missingBody)
        .whereType<Map>()
        .map((item) => _missing(JsonCodec.asMap(item)))
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
    final overdue = missing
        .where((item) => item.overdueLabel.toLowerCase().contains('overdue'))
        .length;
    final pendingAck = handovers
        .where((item) => item.acknowledgementCaption != null)
        .length;
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
          value: '${overdue == 0 ? missing.length : overdue}',
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

  static SubmittedLogEntry _submitted(Map<String, dynamic> json) {
    final author = json['author'] ??
        json['staff'] ??
        json['submittedBy'] ??
        json['createdBy'];
    final name = IsoDateRange.personName(author);
    final at = JsonCodec.dateTime(json['submittedAt'] ?? json['createdAt']);
    return SubmittedLogEntry(
      id: JsonCodec.stringOr(json['id'], name),
      initials: IsoDateRange.initials(name),
      shiftLabel: JsonCodec.stringOr(
        json['shiftName'] ??
            JsonCodec.mapAt(json, 'shift')?['name'] ??
            json['period'],
        'Shift',
      ),
      staffName: name,
      submittedTimeLabel: at == null
          ? JsonCodec.stringOr(json['status'], 'Submitted')
          : 'Submitted ${IsoDateRange.timeLabel(at.toLocal())}',
      status: _reviewStatus(json['status'] ?? json['reviewStatus']),
    );
  }

  static MissingLogEntry _missing(Map<String, dynamic> json) {
    final staff = json['staff'] ?? json['assignedTo'] ?? json['expectedStaff'];
    final name = IsoDateRange.personName(staff);
    final assigned = json['assignedStaff'] ?? json['supervisor'] ?? staff;
    final assignedName = IsoDateRange.personName(assigned);
    final due = JsonCodec.dateTime(json['dueAt'] ?? json['expectedAt']);
    return MissingLogEntry(
      id: JsonCodec.stringOr(json['id'], name),
      staffName: name,
      initials: IsoDateRange.initials(name),
      locationLabel: JsonCodec.stringOr(
        json['residenceName'] ??
            JsonCodec.mapAt(json, 'residence')?['name'] ??
            json['location'],
        '',
      ),
      overdueLabel: due == null
          ? JsonCodec.stringOr(json['status'], 'Missing')
          : IsoDateRange.timeAgo(due),
      expectedShiftLabel: JsonCodec.stringOr(
        json['shiftName'] ?? json['period'] ?? json['expectedShift'],
        'Shift',
      ),
      assignedStaffName: assignedName,
      assignedStaffInitials: IsoDateRange.initials(assignedName),
    );
  }

  static HandoverEntry _handover(Map<String, dynamic> json) {
    final from = json['fromStaff'] ?? json['outgoingStaff'] ?? json['from'];
    final to = json['toStaff'] ?? json['incomingStaff'] ?? json['to'];
    final fromName = from == null ? null : IsoDateRange.personName(from);
    final toName = to == null ? null : IsoDateRange.personName(to);
    final notes = JsonCodec.listAt(json, 'notes').isEmpty
        ? JsonCodec.listAt(json, 'items')
        : JsonCodec.listAt(json, 'notes');
    final acknowledged = JsonCodec.boolean(json['acknowledged']) ?? false;
    return HandoverEntry(
      id: JsonCodec.stringOr(json['id'], 'handover'),
      fromShiftLabel: JsonCodec.stringOr(
        json['fromShiftName'] ??
            JsonCodec.mapAt(json, 'fromShift')?['name'] ??
            json['fromPeriod'],
        'Outgoing',
      ),
      toShiftLabel: JsonCodec.stringOr(
        json['toShiftName'] ??
            JsonCodec.mapAt(json, 'toShift')?['name'] ??
            json['toPeriod'],
        'Incoming',
      ),
      isUrgent: JsonCodec.boolean(json['urgent'] ?? json['isUrgent']) ?? false,
      tagLabel: JsonCodec.string(json['tag'] ?? json['priority']),
      fromStaffName: fromName,
      fromStaffInitials: fromName == null ? null : IsoDateRange.initials(fromName),
      toStaffName: toName,
      toStaffInitials: toName == null ? null : IsoDateRange.initials(toName),
      notes: notes.whereType<Map>().map((item) {
        final row = JsonCodec.asMap(item);
        return HandoverNote(
          type: _noteType(row['type'] ?? row['kind']),
          title: JsonCodec.stringOr(row['title'] ?? row['label'], 'Note'),
          description: JsonCodec.stringOr(row['body'] ?? row['text'] ?? row['note'], ''),
        );
      }).toList(),
      acknowledgementCaption: acknowledged
          ? JsonCodec.string(json['acknowledgedByName'] ?? json['acknowledgedLabel'])
          : JsonCodec.string(json['acknowledgementCaption']) ?? 'Awaiting acknowledgement',
    );
  }

  static List<ClientStatusSummary> _clients(dynamic logsBody, dynamic flagsBody) {
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
      final client = JsonCodec.mapAt(json, 'client') ?? {};
      final name = IsoDateRange.personName(
        client.isEmpty ? json['clientName'] : client,
      );
      final id = JsonCodec.stringOr(client['id'] ?? json['clientId'], name);
      byClient[id] = ClientStatusSummary(
        id: id,
        clientName: name,
        statusLabel: JsonCodec.stringOr(json['state'] ?? json['status'], 'Flagged'),
        isOnTrack: false,
      );
    }
    return byClient.values.toList();
  }

  static LogReviewStatus _reviewStatus(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'flagged':
      case 'open':
        return LogReviewStatus.flagged;
      case 'review':
      case 'in_review':
      case 'pending':
        return LogReviewStatus.inReview;
      default:
        return LogReviewStatus.complete;
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
