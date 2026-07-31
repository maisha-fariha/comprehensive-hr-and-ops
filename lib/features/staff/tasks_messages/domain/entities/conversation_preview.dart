import 'package:flutter/foundation.dart';

import 'tasks_messages_enums.dart';

/// A single row in the "Messages" tab's conversation list.
@immutable
class ConversationPreview {
  final String id;

  /// Full display name, including any role suffix already baked in (e.g.
  /// "Angela M. (RN)", "Robert T. (Supervisor)"), matching the reference
  /// design exactly.
  final String name;
  final String initials;
  final String timeLabel;
  final String previewText;
  final MessagePriority priority;
  final bool isOnline;

  const ConversationPreview({
    required this.id,
    required this.name,
    required this.initials,
    required this.timeLabel,
    required this.previewText,
    required this.priority,
    this.isOnline = false,
  });
}
