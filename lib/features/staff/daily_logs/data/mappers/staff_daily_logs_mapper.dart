import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/daily_note_attachment.dart';
import '../../domain/entities/daily_note_field.dart';
import '../../domain/entities/daily_note_overview.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';

abstract final class StaffDailyLogsMapper {
  static StaffDailyLogsOverview compose({
    required dynamic clientsBody,
    required List<({String clientId, dynamic body})> draftLogs,
    required List<({String clientId, dynamic body})> submittedLogs,
    required dynamic flagsBody,
  }) {
    final draftByClient = <String, List<Map<String, dynamic>>>{};
    final submittedByClient = <String, List<Map<String, dynamic>>>{};
    final drafts = <StaffClientLogEntry>[];
    final submitted = <StaffClientLogEntry>[];

    for (final pair in draftLogs) {
      final entries = _entriesFromDailyLogBody(pair.body);
      draftByClient.putIfAbsent(pair.clientId, () => []);
      for (final json in entries) {
        final withClient = <String, dynamic>{
          ...json,
          'clientId': json['clientId'] ?? pair.clientId,
          'status': json['status'] ?? 'draft',
        };
        draftByClient[pair.clientId]!.add(withClient);
        drafts.add(_logRow(withClient, ClientLogStatus.inProgress));
      }
    }

    for (final pair in submittedLogs) {
      final entries = _entriesFromDailyLogBody(pair.body);
      submittedByClient.putIfAbsent(pair.clientId, () => []);
      for (final json in entries) {
        final withClient = <String, dynamic>{
          ...json,
          'clientId': json['clientId'] ?? pair.clientId,
          'status': json['status'] ?? 'submitted',
        };
        submittedByClient[pair.clientId]!.add(withClient);
        submitted.add(_logRow(withClient, ClientLogStatus.submitted));
      }
    }

    final clients = JsonCodec.unwrapList(clientsBody).whereType<Map>().map((raw) {
      final json = JsonCodec.asMap(raw);
      final clientId = JsonCodec.stringOr(json['id'], '');
      final clientSubmitted =
          submittedByClient[clientId] ?? const <Map<String, dynamic>>[];
      final clientDrafts =
          draftByClient[clientId] ?? const <Map<String, dynamic>>[];

      // Prefer submitted > draft > pending for the My Clients pill.
      final ClientLogStatus status;
      final Map<String, dynamic>? latest;
      if (clientSubmitted.isNotEmpty) {
        status = ClientLogStatus.submitted;
        latest = clientSubmitted.first;
      } else if (clientDrafts.isNotEmpty) {
        status = ClientLogStatus.inProgress;
        latest = clientDrafts.first;
      } else {
        status = ClientLogStatus.pending;
        latest = null;
      }
      return _clientRow(json, status, latest);
    }).toList();

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

  static List<Map<String, dynamic>> _entriesFromDailyLogBody(dynamic body) {
    if (body == null) return const [];
    final list = JsonCodec.unwrapList(body);
    if (list.isNotEmpty) {
      return [
        for (final item in list)
          if (item is Map) JsonCodec.asMap(item),
      ];
    }
    final map = JsonCodec.unwrapMap(body);
    if (map.isEmpty) return const [];
    if (map.containsKey('id') || map.containsKey('entries')) {
      final nested = JsonCodec.listAt(map, 'entries');
      if (nested.isNotEmpty) {
        return [
          for (final item in nested)
            if (item is Map) JsonCodec.asMap(item),
        ];
      }
      return [map];
    }
    return const [];
  }

  static DailyNoteOverview emptyNote() {
    return DailyNoteOverview(
      fields: _blankFields(),
      body: '',
      entryId: null,
      status: '',
      shift: _shiftForNow(),
    );
  }

  static DailyNoteOverview noteFromEntry(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final observations = JsonCodec.mapAt(json, 'observations') ?? {};
    final bodyText = JsonCodec.stringOr(json['body'] ?? json['notes'], '');
    final status = (JsonCodec.string(json['status'] ?? json['entryStatus']) ??
            'submitted')
        .toLowerCase();
    final wellnessValue = JsonCodec.stringOr(
      observations['wellness'] ?? observations['appointmentNotes'],
      '',
    );
    final wellnessCompleted = JsonCodec.boolean(json['wellnessCheckCompleted']) ??
        wellnessValue.isNotEmpty;
    final flag = json['flagForAttention'];
    final flagForAttention = flag is bool
        ? flag
        : flag is Map
            ? true
            : false;

    final attachmentMaps = JsonCodec.unwrapList(json['attachments'])
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();

    return DailyNoteOverview(
      entryId: JsonCodec.string(json['id'] ?? json['entryId']),
      body: bodyText,
      status: status,
      shift: JsonCodec.stringOr(json['shift'], _shiftForNow()),
      wellnessCheckCompleted: wellnessCompleted,
      flagForAttention: flagForAttention,
      attachments: [
        for (final item in attachmentMaps)
          if ((JsonCodec.string(item['fileUrl'] ?? item['url']) ?? '').isNotEmpty)
            DailyNoteAttachment(
              fileUrl: JsonCodec.stringOr(item['fileUrl'] ?? item['url'], ''),
              fileType: JsonCodec.stringOr(
                item['fileType'] ?? item['mimeType'] ?? item['contentType'],
                'file',
              ),
              fileName: JsonCodec.string(item['fileName'] ?? item['name']),
            ),
      ],
      fields: [
        DailyNoteField(
          key: DailyNoteFieldKey.mood,
          label: 'Mood',
          value: JsonCodec.stringOr(observations['mood'], ''),
        ),
        DailyNoteField(
          key: DailyNoteFieldKey.meals,
          label: 'Meals',
          value: JsonCodec.stringOr(observations['meals'], ''),
        ),
        DailyNoteField(
          key: DailyNoteFieldKey.sleep,
          label: 'Sleep',
          value: JsonCodec.stringOr(observations['sleep'], ''),
        ),
        DailyNoteField(
          key: DailyNoteFieldKey.hygiene,
          label: 'Hygiene',
          value: JsonCodec.stringOr(observations['hygiene'], ''),
        ),
        DailyNoteField(
          key: DailyNoteFieldKey.activities,
          label: 'Activities',
          value: JsonCodec.stringOr(observations['activities'], ''),
        ),
        DailyNoteField(
          key: DailyNoteFieldKey.behavior,
          label: 'Behavior',
          value: JsonCodec.stringOr(
            observations['behaviorNotes'] ?? observations['behavior'],
            '',
          ),
        ),
        DailyNoteField(
          key: DailyNoteFieldKey.wellness,
          label: 'Wellness',
          value: wellnessValue,
        ),
      ],
    );
  }

  static String _shiftForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'night';
  }

  static List<DailyNoteField> _blankFields() => const [
        DailyNoteField(key: DailyNoteFieldKey.mood, label: 'Mood', value: ''),
        DailyNoteField(key: DailyNoteFieldKey.meals, label: 'Meals', value: ''),
        DailyNoteField(key: DailyNoteFieldKey.sleep, label: 'Sleep', value: ''),
        DailyNoteField(
          key: DailyNoteFieldKey.hygiene,
          label: 'Hygiene',
          value: '',
        ),
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
      ];

  static StaffClientLogEntry _clientRow(
    Map<String, dynamic> json,
    ClientLogStatus status,
    Map<String, dynamic>? latestLog,
  ) {
    final name = JsonCodec.stringOr(
      json['preferredName'] ?? json['fullName'] ?? json['name'],
      'Client',
    );
    final clientId = JsonCodec.stringOr(json['id'], name);
    final updated = latestLog == null
        ? null
        : JsonCodec.dateTime(
            latestLog['updatedAt'] ??
                latestLog['submittedAt'] ??
                latestLog['createdAt'],
          );
    final subtitle = switch (status) {
      ClientLogStatus.pending => JsonCodec.stringOr(
          json['room'] ?? json['roomNumber'] ?? json['location'],
          'No note yet today',
        ),
      ClientLogStatus.inProgress => updated == null
          ? 'Draft in progress'
          : 'Updated ${IsoDateRange.timeLabel(updated.toLocal())}',
      ClientLogStatus.submitted => updated == null
          ? 'Submitted'
          : 'Submitted ${IsoDateRange.timeLabel(updated.toLocal())}',
    };

    return StaffClientLogEntry(
      id: clientId,
      initials: IsoDateRange.initials(name),
      shiftLabel: JsonCodec.stringOr(
        latestLog?['shift'] ?? json['shift'] ?? json['shiftLabel'],
        'Today',
      ),
      clientName: name,
      subtitleLabel: subtitle,
      status: status,
      dobLabel: _dobLabel(json),
      roomLabel: JsonCodec.stringOr(json['room'] ?? json['roomNumber'], ''),
      clientId: clientId,
      residenceId: JsonCodec.string(
        json['residenceId'] ?? JsonCodec.mapAt(json, 'residence')?['id'],
      ),
      entryId: JsonCodec.string(
        latestLog?['id'] ?? latestLog?['entryId'],
      ),
    );
  }

  static String _dobLabel(Map<String, dynamic> json) {
    final raw = JsonCodec.string(json['dateOfBirth'] ?? json['dob']);
    if (raw == null) return '';
    final parsed = JsonCodec.dateTime(raw);
    if (parsed == null) return raw.startsWith('DOB') ? raw : 'DOB $raw';
    final local = parsed.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return 'DOB $mm/$dd/${local.year}';
  }

  static StaffClientLogEntry _logRow(
    Map<String, dynamic> json,
    ClientLogStatus status,
  ) {
    final client = JsonCodec.mapAt(json, 'client') ?? json;
    final name = JsonCodec.stringOr(
      client['preferredName'] ??
          client['fullName'] ??
          client['name'] ??
          json['clientName'],
      'Client',
    );
    final updated = JsonCodec.dateTime(
      json['updatedAt'] ?? json['submittedAt'] ?? json['createdAt'],
    );
    return StaffClientLogEntry(
      id: JsonCodec.stringOr(
        json['id'] ?? json['entryId'] ?? client['id'],
        name,
      ),
      initials: IsoDateRange.initials(name),
      shiftLabel: JsonCodec.stringOr(json['shift'] ?? json['shiftLabel'], 'Shift'),
      clientName: name,
      subtitleLabel: updated == null
          ? JsonCodec.stringOr(json['status'], status.name)
          : '${status == ClientLogStatus.submitted ? 'Submitted' : 'Updated'} ${IsoDateRange.timeLabel(updated.toLocal())}',
      status: status,
      dobLabel: _dobLabel(JsonCodec.asMap(client)),
      roomLabel: JsonCodec.stringOr(client['room'] ?? client['roomNumber'], ''),
      clientId: JsonCodec.stringOr(json['clientId'] ?? client['id'], ''),
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
