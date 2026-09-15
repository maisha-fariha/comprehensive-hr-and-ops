import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/message_thread.dart';
import '../../domain/entities/recurring_check_instance.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/entities/staff_task_detail.dart';
import '../../domain/entities/task_stats.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../domain/entities/tasks_messages_overview.dart';

abstract final class StaffTasksMessagesMapper {
  static TasksMessagesOverview overview({
    required dynamic tasksBody,
    required dynamic conversationsBody,
    dynamic statsBody,
    dynamic recurringBody,
  }) {
    return TasksMessagesOverview(
      tasks: tasksFrom(tasksBody),
      conversations: JsonCodec.unwrapList(conversationsBody)
          .whereType<Map>()
          .map((item) => conversationFrom(JsonCodec.asMap(item)))
          .toList(),
      stats: statsFrom(statsBody),
      recurringChecks: recurringFrom(recurringBody),
    );
  }

  static List<StaffTask> tasksFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => taskFrom(JsonCodec.asMap(item)))
        .toList();
  }

  /// Chip counts from the loaded list so they always match visible rows.
  static TaskStats statsFromTasks(List<StaffTask> tasks) {
    var overdue = 0;
    var pending = 0;
    var done = 0;
    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.overdue:
          overdue++;
        case TaskStatus.pending:
          pending++;
        case TaskStatus.done:
          done++;
      }
    }
    return TaskStats(
      all: tasks.length,
      overdue: overdue,
      dueToday: pending,
      done: done,
    );
  }

  static TaskStats statsFrom(dynamic body) {
    if (body == null) return const TaskStats();
    final json = JsonCodec.unwrapMap(body);
    final status = JsonCodec.mapAt(json, 'status') ?? const {};

    // Real GET /tasks/stats shape:
    //   status: { overdue, pending, completed }
    //   today:  { due, completed, percent }  ← daily KPI, not chip buckets
    // Chips map 1:1 to status.* (UI "Due Today" = pending, same as
    // status=pending filter / Pending rows in the design mock).
    final overdue = JsonCodec.integerOr(status['overdue'], 0);
    final pending = JsonCodec.integerOr(status['pending'], 0);
    final done = JsonCodec.integerOr(
      status['completed'] ?? status['done'],
      0,
    );
    final all = JsonCodec.integerOr(
      json['total'] ?? json['all'],
      overdue + pending + done,
    );

    return TaskStats(
      all: all,
      overdue: overdue,
      dueToday: pending,
      done: done,
    );
  }

  static List<RecurringCheckInstance> recurringFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body).whereType<Map>().map((item) {
      final json = JsonCodec.asMap(item);
      final due = JsonCodec.dateTime(
        json['dueAt'] ?? json['scheduledAt'] ?? json['windowStart'],
      );
      final name = JsonCodec.stringOr(
        json['name'] ??
            json['title'] ??
            JsonCodec.mapAt(json, 'schedule')?['name'] ??
            json['checkType'],
        'Room check',
      );
      return RecurringCheckInstance(
        id: JsonCodec.stringOr(json['id'] ?? json['instanceId'], name),
        title: name,
        statusRaw: JsonCodec.stringOr(json['status'], ''),
        dueLabel: due == null
            ? JsonCodec.stringOr(json['dueLabel'], '')
            : IsoDateRange.timeLabel(due.toLocal()),
        location: JsonCodec.stringOr(
          json['residenceName'] ??
              JsonCodec.mapAt(json, 'residence')?['name'] ??
              json['location'],
          '',
        ),
      );
    }).toList();
  }

  static StaffTask taskFrom(Map<String, dynamic> json) {
    final due = JsonCodec.dateTime(
      json['dueAt'] ?? json['dueDate'] ?? json['due'],
    );
    return StaffTask(
      id: JsonCodec.stringOr(json['id'], json['title'] ?? 'task'),
      title: JsonCodec.stringOr(json['title'] ?? json['name'], 'Task'),
      dueTimeLabel: due == null
          ? JsonCodec.stringOr(json['dueLabel'], '')
          : IsoDateRange.timeLabel(due.toLocal()),
      location: JsonCodec.stringOr(
        json['residenceName'] ??
            JsonCodec.mapAt(json, 'residence')?['name'] ??
            json['location'],
        '',
      ),
      status: _taskStatus(json['status'], due),
    );
  }

  static StaffTaskDetail taskDetailFrom({
    required dynamic detailBody,
    required dynamic notesBody,
  }) {
    final json = JsonCodec.unwrapMap(detailBody);
    final due = JsonCodec.dateTime(
      json['dueAt'] ?? json['dueDate'] ?? json['due'],
    );
    return StaffTaskDetail(
      id: JsonCodec.stringOr(json['id'], 'task'),
      title: JsonCodec.stringOr(json['title'] ?? json['name'], 'Task'),
      description: JsonCodec.stringOr(
        json['description'] ?? json['body'] ?? json['notes'],
        '',
      ),
      statusRaw: JsonCodec.stringOr(json['status'], ''),
      dueLabel: due == null
          ? JsonCodec.stringOr(json['dueLabel'], '')
          : IsoDateRange.timeLabel(due.toLocal()),
      location: JsonCodec.stringOr(
        json['residenceName'] ??
            JsonCodec.mapAt(json, 'residence')?['name'] ??
            json['location'],
        '',
      ),
      notes: notesFrom(notesBody),
    );
  }

  static List<StaffTaskNote> notesFrom(dynamic body) {
    return JsonCodec.unwrapList(body).whereType<Map>().map((item) {
      final json = JsonCodec.asMap(item);
      final at = JsonCodec.dateTime(json['createdAt'] ?? json['at']);
      return StaffTaskNote(
        id: JsonCodec.stringOr(json['id'], json.hashCode.toString()),
        body: JsonCodec.stringOr(
          json['body'] ?? json['text'] ?? json['note'] ?? json['content'],
          '',
        ),
        authorName: IsoDateRange.personName(
          json['author'] ?? json['createdBy'] ?? json['staff'] ?? json['user'],
        ),
        timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      );
    }).toList();
  }

  static List<Map<String, String>> simpleRowsFrom(
    dynamic body, {
    required String titleKey,
    String subtitleKey = '',
  }) {
    return JsonCodec.unwrapList(body).whereType<Map>().map((item) {
      final json = JsonCodec.asMap(item);
      final title = JsonCodec.stringOr(
        json[titleKey] ??
            json['title'] ??
            json['name'] ??
            json['courseName'] ??
            json['fileName'] ??
            json['subject'],
        'Item',
      );
      final subtitle = subtitleKey.isEmpty
          ? JsonCodec.stringOr(
              json['status'] ??
                  json['description'] ??
                  json['body'] ??
                  json['category'],
              '',
            )
          : JsonCodec.stringOr(json[subtitleKey], '');
      return {
        'id': JsonCodec.stringOr(json['id'], title),
        'title': title,
        'subtitle': subtitle,
      };
    }).toList();
  }

  static ConversationPreview conversationFrom(Map<String, dynamic> json) {
    final name = JsonCodec.stringOr(
      json['title'] ??
          json['name'] ??
          json['subject'] ??
          IsoDateRange.personName(json['otherParticipant'] ?? json['peer']),
      'Conversation',
    );
    final last = JsonCodec.mapAt(json, 'lastMessage') ?? json;
    final at = JsonCodec.dateTime(
      last['createdAt'] ?? last['sentAt'] ?? json['updatedAt'],
    );
    return ConversationPreview(
      id: JsonCodec.stringOr(json['id'], name),
      name: name,
      initials: IsoDateRange.initials(name),
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      previewText: JsonCodec.stringOr(
        last['body'] ?? last['text'] ?? last['preview'] ?? json['preview'],
        '',
      ),
      priority: _priority(last['priority'] ?? json['priority']),
      isOnline: false,
    );
  }

  static MessageThread threadFrom({
    required String conversationId,
    required String contactName,
    required dynamic messagesBody,
    required String selfId,
  }) {
    final messages = JsonCodec.unwrapList(messagesBody)
        .whereType<Map>()
        .map((item) {
      final json = JsonCodec.asMap(item);
      final senderId = JsonCodec.string(
        json['senderId'] ??
            json['authorId'] ??
            JsonCodec.mapAt(json, 'sender')?['id'],
      );
      final outgoing = senderId != null && senderId == selfId;
      final at = JsonCodec.dateTime(json['createdAt'] ?? json['sentAt']);
      return ChatMessage(
        id: JsonCodec.stringOr(json['id'], json.hashCode.toString()),
        text: JsonCodec.stringOr(
          json['body'] ?? json['text'] ?? json['content'],
          '',
        ),
        direction:
            outgoing ? MessageDirection.outgoing : MessageDirection.incoming,
        timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
        receiptStatus: null,
        senderInitials: outgoing ? IsoDateRange.initials(contactName) : null,
      );
    }).toList();

    return MessageThread(
      conversationId: conversationId,
      contactName: contactName,
      contactInitials: IsoDateRange.initials(contactName),
      isActiveNow: false,
      messages: messages,
    );
  }

  static TaskStatus _taskStatus(dynamic raw, DateTime? due) {
    final status = (raw ?? '').toString().toLowerCase();
    if (status.contains('complete') || status == 'done') return TaskStatus.done;
    if (status.contains('overdue')) return TaskStatus.overdue;
    if (due != null && due.isBefore(DateTime.now()) && status != 'completed') {
      return TaskStatus.overdue;
    }
    return TaskStatus.pending;
  }

  static MessagePriority _priority(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'high':
      case 'high_priority':
      case 'highpriority':
        return MessagePriority.highPriority;
      case 'routine':
        return MessagePriority.routine;
      default:
        return MessagePriority.general;
    }
  }

  /// Filters the loaded task list for a chip (API status values are
  /// open / in_progress / done — not pending / completed / overdue).
  static List<StaffTask> filterTasks(
    List<StaffTask> tasks,
    TaskFilter filter,
  ) {
    return switch (filter) {
      TaskFilter.all => tasks,
      TaskFilter.overdue =>
        tasks.where((t) => t.status == TaskStatus.overdue).toList(),
      TaskFilter.dueToday =>
        tasks.where((t) => t.status == TaskStatus.pending).toList(),
      TaskFilter.done =>
        tasks.where((t) => t.status == TaskStatus.done).toList(),
    };
  }

  const StaffTasksMessagesMapper._();
}
