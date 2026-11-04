import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/daily_log.dart';

abstract final class DailyLogsMapper {
  static String _day(dynamic value) {
    final text = JsonCodec.string(value) ?? '';
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  static DailySummary dailySummaryFrom(Map<String, dynamic> json) {
    final attentionRaw = json['attentionJson'] ?? json['attention'];
    final sourcesRaw = json['sourcesJson'] ?? json['sources'];
    final sources = <String, int>{};
    if (sourcesRaw is Map) {
      for (final entry in sourcesRaw.entries) {
        final key = '${entry.key}';
        final value = entry.value;
        final count = value is int
            ? value
            : value is num
                ? value.toInt()
                : int.tryParse('$value') ?? 0;
        if (key.isNotEmpty && count > 0) sources[key] = count;
      }
    }
    return DailySummary(
      id: JsonCodec.stringOr(json['id'], ''),
      clientId: JsonCodec.stringOr(json['clientId'], ''),
      residenceId: JsonCodec.string(json['residenceId']),
      day: _day(json['day']),
      summary: JsonCodec.stringOr(json['summary'], ''),
      familySummary: JsonCodec.string(json['familySummary']),
      attention: [
        for (final item in attentionRaw is List ? attentionRaw : const [])
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
      ],
      sources: sources,
      model: JsonCodec.string(json['model']),
      generatedBy: JsonCodec.string(json['generatedBy']),
      generatedAt: JsonCodec.dateTime(json['generatedAt']),
      editedAt: JsonCodec.dateTime(json['editedAt']),
      sharedAt: JsonCodec.dateTime(json['sharedAt']),
    );
  }

  static String _personName(Map row) => [row['firstName'], row['lastName']]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' ');

  static DailyLogPage<T> _page<T>(dynamic body, T? Function(Map<String, dynamic>) map) {
    final items = [
      for (final row in JsonCodec.unwrapList(body).whereType<Map>())
        ?map(JsonCodec.asMap(row)),
    ];
    final meta = JsonCodec.metaOf(body);
    return DailyLogPage(
      items: items,
      total: JsonCodec.integer(meta?['total']) ?? items.length,
      totalPages: JsonCodec.integer(meta?['totalPages']) ?? (items.isEmpty ? 0 : 1),
    );
  }

  static List<DailyLogOption> residencesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            DailyLogOption(id: id, label: JsonCodec.stringOr(row['name'], 'Residence')),
      ];

  static List<DailyLogOption> clientsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            DailyLogOption(
              id: id,
              label: _personName(row),
              residenceId: JsonCodec.string(row['residenceId']) ??
                  JsonCodec.string(JsonCodec.mapAt(JsonCodec.asMap(row), 'residence')?['id']),
            ),
      ];

  static List<DailyLogOption> staffFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            DailyLogOption(id: id, label: _personName(row)),
      ];

  static DailyLogPage<DailyLogReviewRow> reviewFrom(dynamic body) => _page(
        body,
        (row) => DailyLogReviewRow(
          id: JsonCodec.stringOr(row['id'], ''),
          clientId: JsonCodec.stringOr(row['clientId'], ''),
          clientName: JsonCodec.stringOr(row['clientName'], ''),
          logDate: _day(row['logDate']),
          entriesCount: JsonCodec.integerOr(row['entriesCount'], 0),
          shiftLabel: JsonCodec.string(row['shiftLabel']),
          summary: JsonCodec.string(row['summary']),
        ),
      );

  static DailyLogPage<DailyLogMissingRow> missingFrom(dynamic body) => _page(
        body,
        (row) => DailyLogMissingRow(
          clientId: JsonCodec.stringOr(row['clientId'], ''),
          clientName: JsonCodec.stringOr(row['clientName'], ''),
          logDate: _day(row['logDate']),
          gaps: [
            for (final gap in JsonCodec.listAt(row, 'gaps').whereType<Map>())
              DailyLogGap(
                type: JsonCodec.stringOr(gap['type'], 'no_entries'),
                detail: JsonCodec.stringOr(gap['detail'], ''),
              ),
          ],
        ),
      );

  static DailyLogDay? dayFrom(dynamic body) {
    final data = JsonCodec.unwrap(body);
    if (data is! Map) return null;
    final json = JsonCodec.asMap(data);
    return DailyLogDay(
      entries: [
        for (final row in JsonCodec.listAt(json, 'entries').whereType<Map>())
          entryFrom(JsonCodec.asMap(row)),
      ],
      checks: [
        for (final row in JsonCodec.listAt(json, 'checks').whereType<Map>())
          _checkFrom(JsonCodec.asMap(row)),
      ],
    );
  }

  static DailyLogEntry entryFrom(Map<String, dynamic> json) {
    final flag = JsonCodec.mapAt(json, 'flag');
    return DailyLogEntry(
      id: JsonCodec.stringOr(json['id'], ''),
      body: JsonCodec.stringOr(json['body'], ''),
      clientId: JsonCodec.string(json['clientId']),
      occurredAt: JsonCodec.dateTime(json['occurredAt']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      authorName: JsonCodec.string(JsonCodec.mapAt(json, 'author')?['name']),
      amendsEntryId: JsonCodec.string(json['amendsEntryId']),
      amendmentReason: JsonCodec.string(json['amendmentReason']),
      isSuperseded: JsonCodec.boolean(json['isSuperseded']) ?? false,
      shift: JsonCodec.string(json['shift']),
      logType: JsonCodec.string(json['logType']),
      source: JsonCodec.string(json['source']),
      recordedAfterLock: JsonCodec.boolean(json['recordedAfterLock']) ?? false,
      observations: Map<String, Object?>.from(JsonCodec.asMap(json['observations'])),
      wellnessCheckCompleted: JsonCodec.boolean(json['wellnessCheckCompleted']),
      bedCheckCompleted: JsonCodec.boolean(json['bedCheckCompleted']),
      remindAt: JsonCodec.dateTime(json['remindAt']),
      attachments: [
        for (final row in JsonCodec.listAt(json, 'attachments').whereType<Map>())
          if (JsonCodec.string(row['fileUrl']) case final url?)
            DailyLogAttachment(id: JsonCodec.stringOr(row['id'], url), fileUrl: url),
      ],
      flag: flag == null
          ? null
          : DailyLogEntryFlag(
              category: JsonCodec.stringOr(flag['category'], 'other'),
              note: JsonCodec.string(flag['note']),
              raisedAt: JsonCodec.dateTime(flag['raisedAt']),
              resolvedAt: JsonCodec.dateTime(flag['resolvedAt']),
            ),
      amendmentChain: [
        for (final row in JsonCodec.listAt(json, 'amendmentChain').whereType<Map>())
          entryFrom(JsonCodec.asMap(row)),
      ],
    );
  }

  static DailyLogCheck _checkFrom(Map<String, dynamic> json) => DailyLogCheck(
        id: JsonCodec.stringOr(json['id'], ''),
        checkedAt: JsonCodec.dateTime(json['checkedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        checkName: JsonCodec.string(json['checkName']),
        note: JsonCodec.stringOr(json['note'], ''),
        result: Map<String, Object?>.from(JsonCodec.asMap(json['result'])),
        outcome: JsonCodec.string(json['outcome']),
        recordedBy: JsonCodec.string(json['recordedBy']),
      );

  static List<DailyLogShiftRow> shiftLogsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          DailyLogShiftRow(
            id: JsonCodec.stringOr(row['id'], ''),
            status: JsonCodec.stringOr(row['status'], 'open'),
            summary: JsonCodec.string(row['summary']),
            clientName: JsonCodec.string(row['clientName']),
            shiftTitle: JsonCodec.string(row['shiftTitle']),
            shiftType: JsonCodec.string(row['shiftType']),
            shiftStartsAt: JsonCodec.dateTime(row['shiftStartsAt']),
            shiftEndsAt: JsonCodec.dateTime(row['shiftEndsAt']),
            completedByName: row['completedBy'] is Map
                ? JsonCodec.string((row['completedBy'] as Map)['name'])
                : null,
            lockedByName: row['lockedBy'] is Map
                ? JsonCodec.string((row['lockedBy'] as Map)['name'])
                : null,
          ),
      ];

  static DailyLogPage<ResidenceActivityRow> activityFrom(dynamic body) => _page(
        body,
        (row) => ResidenceActivityRow(
          id: JsonCodec.stringOr(row['id'], ''),
          module: JsonCodec.stringOr(row['module'], ''),
          activityType: JsonCodec.stringOr(row['activityType'], ''),
          summary: JsonCodec.stringOr(row['summary'], ''),
          occurredAt: JsonCodec.dateTime(row['occurredAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
          clientName: JsonCodec.string(row['clientName']),
          staffName: JsonCodec.string(row['staffName']),
          residenceName: JsonCodec.string(row['residenceName']),
          entityType: JsonCodec.string(row['entityType']),
          entityId: JsonCodec.string(row['entityId']),
        ),
      );

  static DailyLogPage<CareFlag> flagsFrom(dynamic body) => _page(body, (row) {
        final source = JsonCodec.mapAt(row, 'source');
        return CareFlag(
          id: JsonCodec.stringOr(row['id'], ''),
          category: JsonCodec.stringOr(row['category'], 'other'),
          note: JsonCodec.string(row['note']),
          raisedAt: JsonCodec.dateTime(row['raisedAt']),
          raisedBy: JsonCodec.string(row['raisedBy']),
          resolvedAt: JsonCodec.dateTime(row['resolvedAt']),
          residenceName: JsonCodec.string(row['residenceName']),
          source: source == null
              ? null
              : CareFlagSource(
                  kind: JsonCodec.stringOr(source['kind'], ''),
                  clientName: JsonCodec.string(source['clientName']),
                  logDate: JsonCodec.string(source['logDate']),
                  excerpt: JsonCodec.stringOr(source['excerpt'], ''),
                ),
        );
      });

  static DailyLogUpload? uploadFrom(dynamic body, String fileName) {
    final map = JsonCodec.unwrapMap(body);
    final url = JsonCodec.string(map['fileUrl'] ?? map['url']);
    if (url == null) return null;
    return DailyLogUpload(
      fileUrl: url,
      fileType: JsonCodec.string(map['mimeType']),
      fileName: JsonCodec.string(map['originalName']) ?? fileName,
    );
  }

  static DailyLogBoardNextNote _boardNoteFrom(Map<String, dynamic> row) =>
      DailyLogBoardNextNote(
        id: JsonCodec.stringOr(row['id'], ''),
        clientId: JsonCodec.stringOr(row['clientId'], ''),
        clientName: JsonCodec.stringOr(row['clientName'], ''),
        body: JsonCodec.stringOr(row['body'], ''),
        occurredAt:
            JsonCodec.dateTime(row['occurredAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        author: JsonCodec.string(row['author']),
        inHandover: JsonCodec.boolean(row['inHandover']) ?? false,
      );

  static DailyLogBoard boardFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final counts = JsonCodec.mapAt(json, 'counts') ?? const {};
    return DailyLogBoard(
      residenceId: JsonCodec.stringOr(json['residenceId'], ''),
      date: _day(json['date']),
      forNextShift: [
        for (final row in JsonCodec.listAt(json, 'forNextShift').whereType<Map>())
          _boardNoteFrom(JsonCodec.asMap(row)),
      ],
      notHandedOver: [
        for (final row in JsonCodec.listAt(json, 'notHandedOver').whereType<Map>())
          _boardNoteFrom(JsonCodec.asMap(row)),
      ],
      counts: DailyLogBoardCounts(
        notesMissing: JsonCodec.integerOr(counts['notesMissing'], 0),
        dosesMissing: JsonCodec.integerOr(counts['dosesMissing'], 0),
        checksMissing: JsonCodec.integerOr(counts['checksMissing'], 0),
        openFlags: JsonCodec.integerOr(counts['openFlags'], 0),
      ),
      residents: [
        for (final row in JsonCodec.listAt(json, 'residents').whereType<Map>())
          DailyLogBoardResident(
            clientId: JsonCodec.stringOr(row['clientId'], ''),
            name: JsonCodec.stringOr(row['name'], ''),
            room: JsonCodec.string(row['room']),
            photoUrl: JsonCodec.string(row['photoUrl']),
            notes: JsonCodec.integerOr(row['notes'], 0),
            lastNoteAt: JsonCodec.dateTime(row['lastNoteAt']),
            lastNoteBy: JsonCodec.string(row['lastNoteBy']),
            gaps: [
              for (final gap in JsonCodec.listAt(JsonCodec.asMap(row), 'gaps').whereType<Map>())
                DailyLogBoardGap(
                  type: JsonCodec.stringOr(gap['type'], 'no_entries'),
                  detail: JsonCodec.stringOr(gap['detail'], ''),
                ),
            ],
            flags: [
              for (final flag in JsonCodec.listAt(JsonCodec.asMap(row), 'flags').whereType<Map>())
                DailyLogBoardFlag(
                  id: JsonCodec.stringOr(flag['id'], ''),
                  category: JsonCodec.stringOr(flag['category'], 'other'),
                ),
            ],
          ),
      ],
      shifts: [
        for (final row in JsonCodec.listAt(json, 'shifts').whereType<Map>())
          DailyLogBoardShift(
            id: JsonCodec.stringOr(row['id'], ''),
            title: JsonCodec.string(row['title']),
            shiftType: JsonCodec.string(row['shiftType']),
            startsAt:
                JsonCodec.dateTime(row['startsAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
            endsAt: JsonCodec.dateTime(row['endsAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
            onDuty: [
              for (final s in JsonCodec.listAt(JsonCodec.asMap(row), 'onDuty').whereType<Map>())
                DailyLogBoardOnDuty(
                  staffId: JsonCodec.stringOr(s['staffId'], ''),
                  name: JsonCodec.stringOr(s['name'], ''),
                  clockedInAt: JsonCodec.dateTime(s['clockedInAt']),
                  clockedOutAt: JsonCodec.dateTime(s['clockedOutAt']),
                  late: JsonCodec.boolean(s['late']) ?? false,
                ),
            ],
          ),
      ],
      handovers: [
        for (final row in JsonCodec.listAt(json, 'handovers').whereType<Map>())
          DailyLogBoardHandover(
            id: JsonCodec.stringOr(row['id'], ''),
            status: JsonCodec.stringOr(row['status'], ''),
            submittedAt: JsonCodec.dateTime(row['submittedAt']),
            from: JsonCodec.string(row['from']),
            to: JsonCodec.string(row['to']),
            givenBy: JsonCodec.string(row['givenBy']),
            takenAt: JsonCodec.dateTime(row['takenAt']),
            takenBy: [
              for (final name in JsonCodec.listAt(JsonCodec.asMap(row), 'takenBy'))
                if ('$name'.trim().isNotEmpty) '$name'.trim(),
            ],
            tasks: JsonCodec.integerOr(row['tasks'], 0),
            tasksWaiting: JsonCodec.integerOr(row['tasksWaiting'], 0),
          ),
      ],
    );
  }

  static DailyActivityFeed activityFeedFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final countsRaw = json['counts'];
    final counts = <String, int>{};
    if (countsRaw is Map) {
      for (final entry in countsRaw.entries) {
        final key = '${entry.key}';
        final value = entry.value;
        final count = value is int
            ? value
            : value is num
                ? value.toInt()
                : int.tryParse('$value') ?? 0;
        if (key.isNotEmpty) counts[key] = count;
      }
    }
    return DailyActivityFeed(
      clientId: JsonCodec.stringOr(json['clientId'], ''),
      date: _day(json['date']),
      items: [
        for (final row in JsonCodec.listAt(json, 'items').whereType<Map>())
          DailyActivityFeedItem(
            id: JsonCodec.stringOr(row['id'], ''),
            module: JsonCodec.stringOr(row['module'], ''),
            type: JsonCodec.stringOr(row['type'], ''),
            title: JsonCodec.stringOr(row['title'], ''),
            detail: JsonCodec.stringOr(row['detail'], ''),
            occurredAt:
                JsonCodec.dateTime(row['occurredAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
            staffName: JsonCodec.string(row['staffName'] ?? row['authorName']),
            status: JsonCodec.string(row['status'] ?? row['detail']),
          ),
      ],
      counts: counts,
    );
  }
}
