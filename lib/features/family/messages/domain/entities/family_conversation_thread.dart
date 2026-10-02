import 'package:flutter/foundation.dart';

enum FamilyMessageDirection { incoming, outgoing }

/// Delivery state of an outgoing bubble. Messages loaded from the server are
/// always [sent]; [sending] / [queued] only exist for locally appended ones.
enum FamilyMessageDelivery { sending, sent, queued }

@immutable
class FamilyChatMessage {
  final String id;
  final String text;
  final FamilyMessageDirection direction;
  final String timeLabel;
  final String senderName;
  final FamilyMessageDelivery delivery;

  const FamilyChatMessage({
    required this.id,
    required this.text,
    required this.direction,
    required this.timeLabel,
    required this.senderName,
    this.delivery = FamilyMessageDelivery.sent,
  });

  FamilyChatMessage copyWith({
    FamilyMessageDirection? direction,
    String? timeLabel,
    String? senderName,
    FamilyMessageDelivery? delivery,
  }) {
    return FamilyChatMessage(
      id: id,
      text: text,
      direction: direction ?? this.direction,
      timeLabel: timeLabel ?? this.timeLabel,
      senderName: senderName ?? this.senderName,
      delivery: delivery ?? this.delivery,
    );
  }
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

  FamilyConversationThread copyWith({List<FamilyChatMessage>? messages}) {
    return FamilyConversationThread(
      id: id,
      title: title,
      messages: messages ?? this.messages,
    );
  }
}
