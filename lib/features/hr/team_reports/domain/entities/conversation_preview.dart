import 'package:flutter/foundation.dart';

/// A single message-thread row. Reused by both the Team tab's compact
/// "Recent Messages" preview and the Messages tab's full "Conversations"
/// list.
@immutable
class ConversationPreview {
  final String id;
  final String senderName;
  final String initials;
  final String timeLabel;
  final String previewText;
  final int unreadCount;
  final bool isOnline;

  /// True for a team/group thread (e.g. "Supervisor Team"), which renders a
  /// group icon avatar instead of initials.
  final bool isGroup;

  const ConversationPreview({
    required this.id,
    required this.senderName,
    required this.initials,
    required this.timeLabel,
    required this.previewText,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = false,
  });
}
