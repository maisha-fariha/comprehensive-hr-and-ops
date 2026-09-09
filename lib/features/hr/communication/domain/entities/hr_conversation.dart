import 'package:flutter/foundation.dart';

import 'communication_enums.dart';

@immutable
class HrConversation {
  final String id;
  final String title;
  final String preview;
  final String dateLabel;
  final String subtitle;
  final ConversationFilter kind;
  final int memberCount;
  final int unreadCount;
  final bool isActive;
  final bool isGroup;

  const HrConversation({
    required this.id,
    required this.title,
    required this.preview,
    required this.dateLabel,
    required this.subtitle,
    required this.kind,
    required this.memberCount,
    this.unreadCount = 0,
    this.isActive = true,
    this.isGroup = true,
  });
}

@immutable
class HrChatMessage {
  final String id;
  final String senderName;
  final String senderInitials;
  final String text;
  final String timeLabel;
  final ChatMessageDirection direction;

  const HrChatMessage({
    required this.id,
    required this.senderName,
    required this.senderInitials,
    required this.text,
    required this.timeLabel,
    required this.direction,
  });
}
