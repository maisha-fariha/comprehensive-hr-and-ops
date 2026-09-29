import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/daily_note_attachment.dart';
import '../../domain/entities/daily_note_field.dart';
import '../../domain/entities/daily_note_overview.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../../domain/entities/staff_day_log_entry.dart';
import '../../domain/entities/staff_house_activity_entry.dart';

abstract final class StaffDailyLogsMapper {
  static StaffDailyLogsOverview compose({
    required dynamic reviewBody,
    required dynamic missingBody,
    required dynamic dayBody,
    required dynamic activitiesBody,
    required dynamic clientsBody,
    dynamic flagsBody,
    String? selectedClientName,
    DateTime? from,
    DateTime? to,
  }) {
    final reviewRows = JsonCodec.unwrapList(reviewBody)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();
    final missingRows = JsonCodec.unwrapList(missingBody)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();

    final review = [
      for (final json in reviewRows)
        _queueRow(json, ClientLogStatus.toReview),
    ];
    final missing = [
      for (final json in missingRows)
        _queueRow(json, ClientLogStatus.missing),
    ];

    final dayMap =
        dayBody == null ? <String, dynamic>{} : JsonCodec.unwrapMap(dayBody);
    final dayEntries = <StaffDayLogEntry>[];
    for (final raw in JsonCodec.listAt(dayMap, 'entries').whereType<Map>()) {
      dayEntries.add(_dayEntry(JsonCodec.asMap(raw)));
    }
    final dayDate = JsonCodec.dateTime(dayMap['logDate']);
    final dayClientName = selectedClientName ??
        JsonCodec.string(
          dayMap['clientName'] ?? IsoDateRange.personName(dayMap['client']),
        );

    final activities = JsonCodec.unwrapList(activitiesBody)
        .whereType<Map>()
        .map((item) => _activity(JsonCodec.asMap(item)))
        .toList();

    final residents = <({String id, String name})>[];
    for (final raw in JsonCodec.unwrapList(clientsBody).whereType<Map>()) {
      final json = JsonCodec.asMap(raw);
      final id = JsonCodec.string(json['id']);
      if (id == null || id.isEmpty) continue;
      residents.add((id: id, name: _clientName(json)));
    }

    final reviewTotal = JsonCodec.integerOr(
      JsonCodec.metaOf(reviewBody)?['total'],
      review.length,
    );
    final missingTotal = JsonCodec.integerOr(
      JsonCodec.metaOf(missingBody)?['total'],
      missing.length,
    );
    final activitiesTotal = JsonCodec.integerOr(
      JsonCodec.metaOf(activitiesBody)?['total'],
      activities.length,
    );
    final openFlags = JsonCodec.integerOr(
      JsonCodec.metaOf(flagsBody)?['total'],
      JsonCodec.unwrapList(flagsBody).length,
    );

    // Web "Entries Logged" = sum of entriesCount on review (to-review) days.
    var entriesLogged = 0;
    for (final row in reviewRows) {
      entriesLogged += JsonCodec.integerOr(row['entriesCount'], 0);
    }

    final rangeSubtitle = (from != null && to != null)
        ? _shortRangeLabel(from, to)
        : null;

    return StaffDailyLogsOverview(
      stats: [
        StaffDailyLogSummaryStat(
          tag: StaffDailyLogStatTag.entriesLogged,
          value: '$entriesLogged',
          label: 'Entries Logged',
          subtitle: rangeSubtitle,
        ),
        StaffDailyLogSummaryStat(
          tag: StaffDailyLogStatTag.daysToReview,
          value: '$reviewTotal',
          label: 'Days to Review',
          subtitle: 'Resident-days with entries',
        ),
        StaffDailyLogSummaryStat(
          tag: StaffDailyLogStatTag.missingLogs,
          value: '$missingTotal',
          label: 'Missing Logs',
          subtitle: 'Resident-days with nothing written',
        ),
        StaffDailyLogSummaryStat(
          tag: StaffDailyLogStatTag.openFlags,
          value: '$openFlags',
          label: 'Open Flags',
          subtitle: 'Raised and not yet resolved',
        ),
      ],
      toReview: review,
      toReviewTotal: reviewTotal,
      missing: missing,
      missingTotal: missingTotal,
      dayEntries: dayEntries,
      dayClientName: dayClientName,
      dayLogDateLabel: dayDate == null
          ? null
          : IsoDateRange.formatShortDate(dayDate.toLocal()),
      houseActivities: activities,
      houseActivitiesTotal: activitiesTotal,
      residents: residents,
    );
  }

  static String _shortRangeLabel(DateTime from, DateTime to) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[from.month - 1]} ${from.day} – ${months[to.month - 1]} ${to.day}';
  }

  static StaffClientLogEntry _queueRow(
    Map<String, dynamic> json,
    ClientLogStatus status,
  ) {
    final name = JsonCodec.stringOr(
      json['clientName'] ?? IsoDateRange.personName(json['client']),
      'Resident',
    );
    final logDate = JsonCodec.dateTime(json['logDate']) ??
        DateTime.tryParse(JsonCodec.stringOr(json['logDate'], ''));
    final created = JsonCodec.dateTime(json['createdAt']);
    final entriesCount = JsonCodec.integerOr(json['entriesCount'], 0);
    final dateLabel = logDate == null
        ? '—'
        : IsoDateRange.formatShortDate(logDate.toLocal());

    final subtitle = status == ClientLogStatus.missing
        ? 'No log for $dateLabel'
        : (entriesCount > 0
            ? '$entriesCount ${entriesCount == 1 ? 'entry' : 'entries'}'
            : (created == null
                ? 'Awaiting review'
                : 'Submitted ${IsoDateRange.timeLabel(created.toLocal())}'));

    return StaffClientLogEntry(
      id: JsonCodec.stringOr(
        json['id'] ?? '${json['clientId']}-$dateLabel',
        name,
      ),
      initials: IsoDateRange.initials(name),
      shiftLabel: dateLabel,
      clientName: name,
      subtitleLabel: subtitle,
      status: status,
      dobLabel: '',
      roomLabel: '',
      clientId: JsonCodec.stringOr(json['clientId'], ''),
      residenceId: JsonCodec.string(json['residenceId']),
      entryId: JsonCodec.string(json['id']),
      logDateIso: logDate?.toUtc().toIso8601String() ??
          JsonCodec.string(json['logDate']),
      entriesCount: entriesCount,
    );
  }

  static StaffDayLogEntry _dayEntry(Map<String, dynamic> json) {
    final at = JsonCodec.dateTime(
      json['occurredAt'] ?? json['createdAt'],
    );
    final author = JsonCodec.mapAt(json, 'author') ?? {};
    return StaffDayLogEntry(
      id: JsonCodec.stringOr(json['id'], ''),
      body: JsonCodec.stringOr(json['body'] ?? json['notes'], ''),
      authorName: JsonCodec.stringOr(
        author['name'] ?? IsoDateRange.personName(author),
        'Staff',
      ),
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      logType: JsonCodec.stringOr(json['logType'] ?? json['source'], ''),
      shift: JsonCodec.string(json['shift']),
    );
  }

  static StaffHouseActivityEntry _activity(Map<String, dynamic> json) {
    final client = JsonCodec.mapAt(json, 'client') ?? {};
    final name = _clientName(client.isEmpty ? json : client);
    final date = JsonCodec.dateTime(
      json['activityDate'] ?? json['occurredAt'] ?? json['createdAt'],
    );
    final author = JsonCodec.mapAt(json, 'author') ??
        JsonCodec.mapAt(json, 'recordedByStaff') ??
        {};
    return StaffHouseActivityEntry(
      id: JsonCodec.stringOr(json['id'], ''),
      clientName: name,
      activityType: JsonCodec.stringOr(
        json['activityType'] ?? json['type'],
        'Activity',
      ),
      status: JsonCodec.stringOr(json['status'], ''),
      dateLabel: date == null
          ? '—'
          : IsoDateRange.formatShortDate(date.toLocal()),
      notes: JsonCodec.stringOr(json['notes'] ?? json['description'], ''),
      authorName: JsonCodec.stringOr(
        author['name'] ?? IsoDateRange.personName(author),
        '',
      ),
    );
  }

  static String _clientName(Map<String, dynamic> json) {
    final preferred = JsonCodec.string(json['preferredName']);
    if (preferred != null && preferred.isNotEmpty) return preferred;
    final full = JsonCodec.string(json['fullName'] ?? json['name']);
    if (full != null && full.isNotEmpty) return full;
    final first = JsonCodec.string(json['firstName']) ?? '';
    final last = JsonCodec.string(json['lastName']) ?? '';
    final joined = '$first $last'.trim();
    if (joined.isNotEmpty) return joined;
    return IsoDateRange.personName(json);
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
    final wellnessCompleted =
        JsonCodec.boolean(json['wellnessCheckCompleted']) ??
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
          if ((JsonCodec.string(item['fileUrl'] ?? item['url']) ?? '')
              .isNotEmpty)
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

  const StaffDailyLogsMapper._();
}
