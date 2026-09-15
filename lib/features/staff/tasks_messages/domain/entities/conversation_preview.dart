import 'package:flutter/foundation.dart';

import 'tasks_messages_enums.dart';

/// A single row in the "Messages" tab's conversation list
/// (`GET /conversations`).
@immutable
class ConversationPreview {
  final String id;

  /// Conversation title (group) or peer name (direct).
  final String name;
  final String initials;
  final String timeLabel;
  final String previewText;
  final MessagePriority priority;

  /// From `unreadCount` on the conversation row.
  final int unreadCount;

  const ConversationPreview({
    required this.id,
    required this.name,
    required this.initials,
    required this.timeLabel,
    required this.previewText,
    required this.priority,
    this.unreadCount = 0,
  });

  bool get hasUnread => unreadCount > 0;

  ConversationPreview copyWith({int? unreadCount, String? previewText}) {
    return ConversationPreview(
      id: id,
      name: name,
      initials: initials,
      timeLabel: timeLabel,
      previewText: previewText ?? this.previewText,
      priority: priority,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
