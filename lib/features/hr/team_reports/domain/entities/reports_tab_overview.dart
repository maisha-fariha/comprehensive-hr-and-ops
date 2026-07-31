import 'package:flutter/foundation.dart';

import 'available_report_item.dart';
import 'stat_tile_data.dart';
import 'team_reports_enums.dart';

/// Everything shown on the "Reports" segment of the Team & Reports screen.
@immutable
class ReportsTabOverview {
  final List<StatTileData<ReportStatTag>> stats;
  final List<AvailableReportItem> availableReports;

  const ReportsTabOverview({
    required this.stats,
    required this.availableReports,
  });
}
