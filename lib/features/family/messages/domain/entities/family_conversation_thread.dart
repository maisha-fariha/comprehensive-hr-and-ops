import 'package:flutter/foundation.dart';

enum FamilyMessageDirection { incoming, outgoing }

@immutable
class FamilyChatMessage {
  final String id;
  final String text;
  final FamilyMessageDirection direction;
  final String timeLabel;
  final String senderName;

  const FamilyChatMessage({
    required this.id,
    required this.text,
    required this.direction,
    required this.timeLabel,
    required this.senderName,
  });
}

@immutable
class FamilyConversationThread {
  final String id;
  final String title;
  final List<FamilyChatMessage> messages;

  const FamilyConversationThread({
    required this.id,
    required this.title,
    required this.messages,
  });
}
