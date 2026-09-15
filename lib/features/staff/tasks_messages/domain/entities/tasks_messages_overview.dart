import 'package:flutter/foundation.dart';

import 'conversation_preview.dart';
import 'recurring_check_instance.dart';
import 'staff_task.dart';
import 'task_stats.dart';

/// Aggregate for the Tasks & Messages list screen.
@immutable
class TasksMessagesOverview {
  final List<StaffTask> tasks;
  final List<ConversationPreview> conversations;
  final TaskStats stats;
  final List<RecurringCheckInstance> recurringChecks;

  const TasksMessagesOverview({
    required this.tasks,
    required this.conversations,
    this.stats = const TaskStats(),
    this.recurringChecks = const [],
  });

  TasksMessagesOverview copyWith({
    List<StaffTask>? tasks,
    List<ConversationPreview>? conversations,
    TaskStats? stats,
    List<RecurringCheckInstance>? recurringChecks,
  }) {
    return TasksMessagesOverview(
      tasks: tasks ?? this.tasks,
      conversations: conversations ?? this.conversations,
      stats: stats ?? this.stats,
      recurringChecks: recurringChecks ?? this.recurringChecks,
    );
  }
}
