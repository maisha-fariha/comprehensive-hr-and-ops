import 'package:flutter/foundation.dart';

import 'conversation_preview.dart';
import 'stat_tile_data.dart';
import 'team_reports_enums.dart';
import 'top_report_item.dart';

/// Everything shown on the "Team" segment of the Team & Reports screen.
@immutable
class TeamTabOverview {
  final List<StatTileData<TeamStatTag>> stats;
  final List<TopReportItem> topReports;
  final ConversationPreview recentMessage;

  const TeamTabOverview({
    required this.stats,
    required this.topReports,
    required this.recentMessage,
  });
}
