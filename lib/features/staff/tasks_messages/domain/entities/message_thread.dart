import 'package:flutter/foundation.dart';

import 'chat_message.dart';

/// Everything shown on the Message Details (conversation thread) screen for
/// a single conversation.
@immutable
class MessageThread {
  final String conversationId;
  final String contactName;
  final String contactInitials;
  final bool isActiveNow;
  final List<ChatMessage> messages;

  /// Whether the "..." typing indicator bubble is shown at the bottom of
  /// the thread, representing the other participant currently typing.
  final bool isOtherPersonTyping;

  const MessageThread({
    required this.conversationId,
    required this.contactName,
    required this.contactInitials,
    required this.isActiveNow,
    required this.messages,
    this.isOtherPersonTyping = false,
  });
}
