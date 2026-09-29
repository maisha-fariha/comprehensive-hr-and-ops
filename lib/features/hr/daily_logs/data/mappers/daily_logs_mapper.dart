import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/daily_log.dart';

abstract final class DailyLogsMapper {
  static String _day(dynamic value) {
    final text = JsonCodec.string(value) ?? '';
    return text.length >= 10 ? text.substring(0, 10) : text;
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
        ),
      );

  static DailyLogPage<DailyLogMissingRow> missingFrom(dynamic body) => _page(
        body,
        (row) => DailyLogMissingRow(
          clientId: JsonCodec.stringOr(row['clientId'], ''),
          clientName: JsonCodec.stringOr(row['clientName'], ''),
          logDate: _day(row['logDate']),
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
}
