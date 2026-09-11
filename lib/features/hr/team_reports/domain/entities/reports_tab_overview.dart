import 'package:flutter/foundation.dart';

import 'available_report_item.dart';
import 'report_analytics_item.dart';
import 'report_document_item.dart';
import 'report_export_item.dart';
import 'report_insight.dart';
import 'stat_tile_data.dart';
import 'team_reports_enums.dart';

/// Everything shown on the "Reports" segment of Team & Reports.
@immutable
class ReportsTabOverview {
  final List<StatTileData<ReportStatTag>> stats;
  final List<AvailableReportItem> availableReports;
  final List<ReportInsight> insights;
  final List<ReportAnalyticsItem> analytics;
  final List<ReportExportItem> exports;
  final ReportDocumentsSummary? documentsSummary;
  final List<ReportDocumentItem> documents;
  final List<String> documentTypeNames;

  const ReportsTabOverview({
    required this.stats,
    required this.availableReports,
    this.insights = const [],
    this.analytics = const [],
    this.exports = const [],
    this.documentsSummary,
    this.documents = const [],
    this.documentTypeNames = const [],
  });
}
