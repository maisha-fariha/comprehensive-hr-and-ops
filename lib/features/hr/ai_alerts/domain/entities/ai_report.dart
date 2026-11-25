import 'package:flutter/foundation.dart';

enum AiReportSeverity { info, attention, urgent }

extension AiReportSeverityX on AiReportSeverity {
  static AiReportSeverity? parse(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'info':
        return AiReportSeverity.info;
      case 'attention':
        return AiReportSeverity.attention;
      case 'urgent':
        return AiReportSeverity.urgent;
      default:
        return null;
    }
  }

  String get apiValue => switch (this) {
        AiReportSeverity.info => 'info',
        AiReportSeverity.attention => 'attention',
        AiReportSeverity.urgent => 'urgent',
      };
}

enum AiAlertsTab { reports, automations }

@immutable
class AiReportKindOption {
  final String kind;
  final String label;

  const AiReportKindOption({required this.kind, required this.label});
}

@immutable
class AiReportHomeOption {
  final String id;
  final String name;

  const AiReportHomeOption({required this.id, required this.name});
}

@immutable
class AiReportResidence {
  final String id;
  final String name;

  const AiReportResidence({required this.id, required this.name});
}

@immutable
class AiReportListItem {
  final String id;
  final String kind;
  final String? subjectType;
  final String? subjectId;
  final String? residenceId;
  final String? period;
  final String title;
  final AiReportSeverity severity;
  final DateTime? createdAt;
  final DateTime? sharedAt;
  final String? label;
  final AiReportResidence? residence;
  final bool read;
  final bool waitingOnYou;

  const AiReportListItem({
    required this.id,
    required this.kind,
    this.subjectType,
    this.subjectId,
    this.residenceId,
    this.period,
    required this.title,
    required this.severity,
    this.createdAt,
    this.sharedAt,
    this.label,
    this.residence,
    this.read = true,
    this.waitingOnYou = false,
  });

  AiReportListItem markRead() => AiReportListItem(
        id: id,
        kind: kind,
        subjectType: subjectType,
        subjectId: subjectId,
        residenceId: residenceId,
        period: period,
        title: title,
        severity: severity,
        createdAt: createdAt,
        sharedAt: sharedAt,
        label: label,
        residence: residence,
        read: true,
        waitingOnYou: waitingOnYou,
      );
}

@immutable
class AiReportsPage {
  final List<AiReportListItem> items;
  final int total;
  final int unread;
  final int page;
  final int limit;
  final List<AiReportKindOption> kinds;
  final List<AiReportHomeOption> homes;

  const AiReportsPage({
    this.items = const [],
    this.total = 0,
    this.unread = 0,
    this.page = 1,
    this.limit = 30,
    this.kinds = const [],
    this.homes = const [],
  });
}

@immutable
class AiReportReorderLine {
  final String item;
  final String? unit;
  final num stock;
  final num? daysLeft;
  final num onOrder;
  final num suggestedOrder;
  final bool atOrBelowReorderLevel;

  const AiReportReorderLine({
    required this.item,
    this.unit,
    this.stock = 0,
    this.daysLeft,
    this.onOrder = 0,
    this.suggestedOrder = 0,
    this.atOrBelowReorderLevel = false,
  });
}

@immutable
class AiReportReorderData {
  final List<AiReportReorderLine> items;
  final num? toOrder;
  final int? usageDays;
  final num? underReorderLevel;

  const AiReportReorderData({
    this.items = const [],
    this.toOrder,
    this.usageDays,
    this.underReorderLevel,
  });
}

@immutable
class AiReportDetail {
  final String id;
  final String kind;
  final String title;
  final AiReportSeverity severity;
  final String? label;
  final String? period;
  final String? description;
  final String body;
  final String? schedule;
  final String? model;
  final DateTime? createdAt;
  final AiReportResidence? residence;
  final AiReportReorderData? reorder;
  final bool editAndShare;

  const AiReportDetail({
    required this.id,
    required this.kind,
    required this.title,
    required this.severity,
    this.label,
    this.period,
    this.description,
    this.body = '',
    this.schedule,
    this.model,
    this.createdAt,
    this.residence,
    this.reorder,
    this.editAndShare = false,
  });
}

@immutable
class AiReportAutomation {
  final String kind;
  final String label;
  final String? description;
  final String? schedule;
  final AiReportSeverity? severity;
  final bool continuous;
  final DateTime? lastCheckedAt;
  final String? lastOutcome;
  final int lastReports;
  final String? lastError;
  final DateTime? lastSucceededAt;
  final DateTime? nextCheckAt;
  final int reportsLast30Days;

  const AiReportAutomation({
    required this.kind,
    required this.label,
    this.description,
    this.schedule,
    this.severity,
    this.continuous = false,
    this.lastCheckedAt,
    this.lastOutcome,
    this.lastReports = 0,
    this.lastError,
    this.lastSucceededAt,
    this.nextCheckAt,
    this.reportsLast30Days = 0,
  });
}

@immutable
class AiReportAutomationsPage {
  final String? timeZone;
  final List<AiReportAutomation> items;

  const AiReportAutomationsPage({
    this.timeZone,
    this.items = const [],
  });
}

@immutable
class AiFeatureGate {
  final bool addon;
  final bool configured;
  final bool enabled;

  const AiFeatureGate({
    this.addon = false,
    this.configured = false,
    this.enabled = false,
  });

  bool get isAvailable => enabled;
}
