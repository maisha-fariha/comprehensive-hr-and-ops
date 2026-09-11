import 'package:flutter/foundation.dart';

import 'conversation_preview.dart';
import 'stat_tile_data.dart';
import 'team_reports_enums.dart';
import 'team_staff_member.dart';
import 'top_report_item.dart';

/// Everything shown on the "Team" segment of the Team & Reports screen.
@immutable
class TeamTabOverview {
  final List<StatTileData<TeamStatTag>> stats;
  final List<TopReportItem> topReports;
  final List<ConversationPreview> recentMessages;
  final List<TeamStaffMember> staffMembers;

  /// Convenience for older single-message UI; prefers [recentMessages].first.
  ConversationPreview get recentMessage => recentMessages.isEmpty
      ? const ConversationPreview(
          id: 'none',
          senderName: 'No recent messages',
          initials: '--',
          timeLabel: '',
          previewText: 'Team conversations will appear here.',
        )
      : recentMessages.first;

  const TeamTabOverview({
    required this.stats,
    required this.topReports,
    this.recentMessages = const [],
    this.staffMembers = const [],
  });
}
