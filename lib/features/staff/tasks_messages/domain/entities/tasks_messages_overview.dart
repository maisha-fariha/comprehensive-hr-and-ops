import 'package:flutter/foundation.dart';

import 'conversation_preview.dart';
import 'staff_task.dart';

/// Aggregate root for the whole "Tasks & Messages" list screen: both
/// segmented tabs share a single header/tab-bar and are loaded together in
/// one call.
@immutable
class TasksMessagesOverview {
  final List<StaffTask> tasks;
  final List<ConversationPreview> conversations;

  const TasksMessagesOverview({
    required this.tasks,
    required this.conversations,
  });
}
