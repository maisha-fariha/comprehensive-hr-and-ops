import 'package:flutter/foundation.dart';

import 'announcement.dart';
import 'conversation_preview.dart';
import 'stat_tile_data.dart';
import 'team_reports_enums.dart';

/// Everything shown on the "Messages" segment of the Team & Reports screen.
@immutable
class MessagesTabOverview {
  final List<StatTileData<MessageStatTag>> stats;
  final List<ConversationPreview> conversations;
  final List<Announcement> announcements;

  const MessagesTabOverview({
    required this.stats,
    required this.conversations,
    required this.announcements,
  });
}
