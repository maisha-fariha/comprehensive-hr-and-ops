import 'package:flutter/foundation.dart';

import 'communication_enums.dart';

@immutable
class HrConversationParticipant {
  final String userId;
  final String name;

  const HrConversationParticipant({
    required this.userId,
    required this.name,
  });
}

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
  final bool isMonitored;
  final bool isArchived;
  final List<HrConversationParticipant> participants;

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
    this.isMonitored = false,
    this.isArchived = false,
    this.participants = const [],
  });

  HrConversation copyWith({
    String? preview,
    String? dateLabel,
    int? unreadCount,
    bool? isActive,
  }) {
    return HrConversation(
      id: id,
      title: title,
      preview: preview ?? this.preview,
      dateLabel: dateLabel ?? this.dateLabel,
      subtitle: subtitle,
      kind: kind,
      memberCount: memberCount,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      isGroup: isGroup,
      isMonitored: isMonitored,
      isArchived: isArchived,
      participants: participants,
    );
  }
}

@immutable
class HrChatMessage {
  final String id;
  final String senderName;
  final String senderInitials;
  final String text;
  final String timeLabel;
  final ChatMessageDirection direction;
  final int sortKey;

  const HrChatMessage({
    required this.id,
    required this.senderName,
    required this.senderInitials,
    required this.text,
    required this.timeLabel,
    required this.direction,
    this.sortKey = 0,
  });
}
