import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/daily_note_field.dart';
import '../../domain/entities/daily_note_overview.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';

abstract final class StaffDailyLogsMapper {
  static StaffDailyLogsOverview compose({
    required dynamic clientsBody,
    required List<dynamic> logBodies,
    required dynamic flagsBody,
  }) {
    final clients = JsonCodec.unwrapList(clientsBody)
        .whereType<Map>()
        .map((item) => _clientRow(JsonCodec.asMap(item), ClientLogStatus.pending))
        .toList();
    final drafts = <StaffClientLogEntry>[];
    final submitted = <StaffClientLogEntry>[];
    for (final body in logBodies) {
      for (final item in JsonCodec.unwrapList(body)) {
        if (item is! Map) continue;
        final json = JsonCodec.asMap(item);
        final status = (JsonCodec.string(json['status'] ?? json['entryStatus']) ??
                'submitted')
            .toLowerCase();
        if (status == 'draft') {
          drafts.add(_logRow(json, ClientLogStatus.inProgress));
        } else {
          submitted.add(_logRow(json, ClientLogStatus.submitted));
        }
      }
    }
    final flagged = JsonCodec.unwrapList(flagsBody).length;

    return StaffDailyLogsOverview(
      stats: [
        StaffDailyLogSummaryStat(
          tag: StaffDailyLogStatTag.submittedToday,
          value: '${submitted.length}',
          label: 'Submitted Today',
        ),
        StaffDailyLogSummaryStat(
          tag: StaffDailyLogStatTag.pendingReview,
          value: '${drafts.length}',
          label: 'In Progress',
        ),
        StaffDailyLogSummaryStat(
          tag: StaffDailyLogStatTag.flaggedNotes,
          value: '$flagged',
          label: 'Flagged Notes',
        ),
      ],
      myClients: clients,
      myClientsTotalCount: JsonCodec.integerOr(
        JsonCodec.metaOf(clientsBody)?['total'],
        clients.length,
      ),
      inProgressClients: drafts,
      submittedClients: submitted,
      submittedTotalCount: submitted.length,
    );
  }

  static DailyNoteOverview emptyNote() {
    return const DailyNoteOverview(
      fields: [
        DailyNoteField(key: DailyNoteFieldKey.mood, label: 'Mood', value: ''),
        DailyNoteField(key: DailyNoteFieldKey.meals, label: 'Meals', value: ''),
        DailyNoteField(key: DailyNoteFieldKey.sleep, label: 'Sleep', value: ''),
        DailyNoteField(key: DailyNoteFieldKey.hygiene, label: 'Hygiene', value: ''),
        DailyNoteField(
          key: DailyNoteFieldKey.activities,
          label: 'Activities',
          value: '',
        ),
        DailyNoteField(
          key: DailyNoteFieldKey.behavior,
          label: 'Behavior',
          value: '',
        ),
        DailyNoteField(
          key: DailyNoteFieldKey.wellness,
          label: 'Wellness',
          value: '',
        ),
      ],
    );
  }

  static StaffClientLogEntry _clientRow(
    Map<String, dynamic> json,
    ClientLogStatus status,
  ) {
    final name = JsonCodec.stringOr(
      json['preferredName'] ?? json['fullName'] ?? json['name'],
      'Client',
    );
    final clientId = JsonCodec.stringOr(json['id'], name);
    return StaffClientLogEntry(
      id: clientId,
      initials: IsoDateRange.initials(name),
      shiftLabel: JsonCodec.stringOr(json['shift'] ?? json['shiftLabel'], 'Today'),
      clientName: name,
      subtitleLabel: JsonCodec.stringOr(
        json['room'] ?? json['roomNumber'] ?? json['location'],
        '',
      ),
      status: status,
      dobLabel: JsonCodec.stringOr(json['dateOfBirth'] ?? json['dob'], ''),
      roomLabel: JsonCodec.stringOr(json['room'] ?? json['roomNumber'], ''),
      clientId: clientId,
      residenceId: JsonCodec.string(
        json['residenceId'] ?? JsonCodec.mapAt(json, 'residence')?['id'],
      ),
    );
  }

  static StaffClientLogEntry _logRow(
    Map<String, dynamic> json,
    ClientLogStatus status,
  ) {
    final client = JsonCodec.mapAt(json, 'client') ?? json;
    final name = JsonCodec.stringOr(
      client['preferredName'] ?? client['fullName'] ?? client['name'] ?? json['clientName'],
      'Client',
    );
    final updated = JsonCodec.dateTime(
      json['updatedAt'] ?? json['submittedAt'] ?? json['createdAt'],
    );
    return StaffClientLogEntry(
      id: JsonCodec.stringOr(json['id'] ?? json['entryId'] ?? client['id'], name),
      initials: IsoDateRange.initials(name),
      shiftLabel: JsonCodec.stringOr(json['shift'] ?? json['shiftLabel'], 'Shift'),
      clientName: name,
      subtitleLabel: updated == null
          ? JsonCodec.stringOr(json['status'], status.name)
          : '${status == ClientLogStatus.submitted ? 'Submitted' : 'Updated'} ${IsoDateRange.timeLabel(updated.toLocal())}',
      status: status,
      dobLabel: JsonCodec.stringOr(client['dateOfBirth'] ?? client['dob'], ''),
      roomLabel: JsonCodec.stringOr(client['room'] ?? client['roomNumber'], ''),
      clientId: JsonCodec.stringOr(
        json['clientId'] ?? client['id'],
        '',
      ),
      residenceId: JsonCodec.string(
        json['residenceId'] ??
            client['residenceId'] ??
            JsonCodec.mapAt(json, 'residence')?['id'],
      ),
      entryId: JsonCodec.string(json['id'] ?? json['entryId']),
    );
  }

  const StaffDailyLogsMapper._();
}
