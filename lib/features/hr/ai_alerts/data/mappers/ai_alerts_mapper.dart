import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/ai_report.dart';

abstract final class AiAlertsMapper {
  static AiFeatureGate gateFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    return AiFeatureGate(
      addon: json['addon'] == true,
      configured: json['configured'] == true,
      enabled: json['enabled'] == true,
    );
  }

  static AiReportsPage reportsPageFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final kinds = <AiReportKindOption>[];
    for (final row in JsonCodec.listAt(json, 'kinds')) {
      if (row is! Map) continue;
      final map = JsonCodec.asMap(row);
      final kind = JsonCodec.stringOr(map['kind'], '');
      if (kind.isEmpty) continue;
      kinds.add(
        AiReportKindOption(
          kind: kind,
          label: JsonCodec.stringOr(map['label'], kind),
        ),
      );
    }
    final homes = <AiReportHomeOption>[];
    for (final row in JsonCodec.listAt(json, 'homes')) {
      if (row is! Map) continue;
      final map = JsonCodec.asMap(row);
      final id = JsonCodec.stringOr(map['id'], '');
      if (id.isEmpty) continue;
      homes.add(
        AiReportHomeOption(
          id: id,
          name: JsonCodec.stringOr(map['name'], 'Residence'),
        ),
      );
    }
    final items = <AiReportListItem>[];
    for (final row in JsonCodec.listAt(json, 'items')) {
      if (row is! Map) continue;
      items.add(listItemFrom(JsonCodec.asMap(row)));
    }
    return AiReportsPage(
      items: items,
      total: JsonCodec.integerOr(json['total'], items.length),
      unread: JsonCodec.integerOr(json['unread'], 0),
      page: JsonCodec.integerOr(json['page'], 1),
      limit: JsonCodec.integerOr(json['limit'], 30),
      kinds: kinds,
      homes: homes,
    );
  }

  static AiReportListItem listItemFrom(Map<String, dynamic> map) {
    final severity =
        AiReportSeverityX.parse(JsonCodec.string(map['severity'])) ??
            AiReportSeverity.info;
    return AiReportListItem(
      id: JsonCodec.stringOr(map['id'], ''),
      kind: JsonCodec.stringOr(map['kind'], ''),
      subjectType: JsonCodec.string(map['subjectType']),
      subjectId: JsonCodec.string(map['subjectId']),
      residenceId: JsonCodec.string(map['residenceId']),
      period: JsonCodec.string(map['period']),
      title: JsonCodec.stringOr(map['title'], 'Report'),
      severity: severity,
      createdAt: JsonCodec.dateTime(map['createdAt']),
      sharedAt: JsonCodec.dateTime(map['sharedAt']),
      label: JsonCodec.string(map['label']),
      residence: _residence(map['residence']),
      read: map['read'] != false,
      waitingOnYou: map['waitingOnYou'] == true,
    );
  }

  static AiReportDetail detailFrom(dynamic body, {String? id}) {
    final map = JsonCodec.unwrapMap(body);
    final severity =
        AiReportSeverityX.parse(JsonCodec.string(map['severity'])) ??
            AiReportSeverity.info;
    final actions = map['actions'];
    var editAndShare = false;
    if (actions is Map) {
      editAndShare = JsonCodec.asMap(actions)['editAndShare'] == true;
    }
    return AiReportDetail(
      id: JsonCodec.stringOr(map['id'], id ?? ''),
      kind: JsonCodec.stringOr(map['kind'], ''),
      title: JsonCodec.stringOr(map['title'], 'Report'),
      severity: severity,
      label: JsonCodec.string(map['label']),
      period: JsonCodec.string(map['period']),
      description: JsonCodec.string(map['description']),
      body: JsonCodec.stringOr(map['body'], ''),
      schedule: JsonCodec.string(map['schedule']),
      model: JsonCodec.string(map['model']),
      createdAt: JsonCodec.dateTime(map['createdAt']),
      residence: _residence(map['residence']),
      reorder: _reorder(map['dataJson']),
      editAndShare: editAndShare,
    );
  }

  static AiReportAutomationsPage automationsFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final items = <AiReportAutomation>[];
    for (final row in JsonCodec.listAt(json, 'items')) {
      if (row is! Map) continue;
      items.add(_automation(JsonCodec.asMap(row)));
    }
    return AiReportAutomationsPage(
      timeZone: JsonCodec.string(json['timeZone']),
      items: items,
    );
  }

  static AiReportAutomation _automation(Map<String, dynamic> map) {
    final severity = AiReportSeverityX.parse(JsonCodec.string(map['severity']));
    return AiReportAutomation(
      kind: JsonCodec.stringOr(map['kind'], ''),
      label: JsonCodec.stringOr(map['label'], ''),
      description: JsonCodec.string(map['description']),
      schedule: JsonCodec.string(map['schedule']),
      severity: severity,
      continuous: map['continuous'] == true,
      lastCheckedAt: JsonCodec.dateTime(map['lastCheckedAt']),
      lastOutcome: JsonCodec.string(map['lastOutcome']),
      lastReports: JsonCodec.integerOr(map['lastReports'], 0),
      lastError: JsonCodec.string(map['lastError']),
      lastSucceededAt: JsonCodec.dateTime(map['lastSucceededAt']),
      nextCheckAt: JsonCodec.dateTime(map['nextCheckAt']),
      reportsLast30Days: JsonCodec.integerOr(map['reportsLast30Days'], 0),
    );
  }

  static AiReportResidence? _residence(dynamic raw) {
    if (raw is! Map) return null;
    final map = JsonCodec.asMap(raw);
    final id = JsonCodec.stringOr(map['id'], '');
    if (id.isEmpty) return null;
    return AiReportResidence(
      id: id,
      name: JsonCodec.stringOr(map['name'], 'Residence'),
    );
  }

  static AiReportReorderData? _reorder(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final map = JsonCodec.asMap(raw);
    final lines = <AiReportReorderLine>[];
    for (final row in JsonCodec.listAt(map, 'items')) {
      if (row is! Map) continue;
      final item = JsonCodec.asMap(row);
      lines.add(
        AiReportReorderLine(
          item: JsonCodec.stringOr(item['item'], ''),
          unit: JsonCodec.string(item['unit']),
          stock: JsonCodec.number(item['stock']) ?? 0,
          daysLeft: item['daysLeft'] == null
              ? null
              : JsonCodec.number(item['daysLeft']),
          onOrder: JsonCodec.number(item['onOrder']) ?? 0,
          suggestedOrder: JsonCodec.number(item['suggestedOrder']) ?? 0,
          atOrBelowReorderLevel: item['atOrBelowReorderLevel'] == true,
        ),
      );
    }
    if (lines.isEmpty &&
        map['toOrder'] == null &&
        map['usageDays'] == null &&
        map['underReorderLevel'] == null) {
      return null;
    }
    return AiReportReorderData(
      items: lines,
      toOrder: map['toOrder'] == null ? null : JsonCodec.number(map['toOrder']),
      usageDays:
          map['usageDays'] == null ? null : JsonCodec.integer(map['usageDays']),
      underReorderLevel: map['underReorderLevel'] == null
          ? null
          : JsonCodec.number(map['underReorderLevel']),
    );
  }
}
