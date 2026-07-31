import 'package:flutter/foundation.dart';

import 'tasks_messages_enums.dart';

/// A single bubble in the Message Details (conversation thread) screen.
@immutable
class ChatMessage {
  final String id;
  final String text;
  final MessageDirection direction;

  /// e.g. "8:58 AM".
  final String timeLabel;

  /// e.g. "Seen" or "Delivered" - only ever set for [MessageDirection.outgoing]
  /// messages, rendered as "Seen · 9:02 AM" below the bubble.
  final String? receiptStatus;

  /// Initials shown in the tiny avatar next to an outgoing bubble's receipt
  /// caption (e.g. "DL" for the signed-in staff member).
  final String? senderInitials;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.direction,
    required this.timeLabel,
    this.receiptStatus,
    this.senderInitials,
  });
}
