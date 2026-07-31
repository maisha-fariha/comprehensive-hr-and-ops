import 'package:flutter/foundation.dart';

import 'family_messages_enums.dart';

/// A single row in the "Messages" list screen's conversation list.
@immutable
class ConversationPreview {
  final String id;
  final String name;

  /// Role/team label shown under the name, e.g. "Care Manager • Sunrise
  /// Home" or "Family Group".
  final String subtitle;

  final ConversationAvatarType avatarType;

  /// Initials shown in the avatar when [avatarType] is
  /// [ConversationAvatarType.initials]; ignored otherwise.
  final String initials;

  final ConversationAccent accent;
  final String timeLabel;
  final String previewText;

  /// Number shown in the small teal unread-count badge; `0` hides the badge.
  final int unreadCount;

  const ConversationPreview({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.avatarType,
    required this.initials,
    required this.accent,
    required this.timeLabel,
    required this.previewText,
    this.unreadCount = 0,
  });
}
