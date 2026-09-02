import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/message_thread.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../domain/entities/tasks_messages_overview.dart';

abstract final class StaffTasksMessagesMapper {
  static TasksMessagesOverview overview({
    required dynamic tasksBody,
    required dynamic conversationsBody,
  }) {
    return TasksMessagesOverview(
      tasks: JsonCodec.unwrapList(tasksBody)
          .whereType<Map>()
          .map((item) => taskFrom(JsonCodec.asMap(item)))
          .toList(),
      conversations: JsonCodec.unwrapList(conversationsBody)
          .whereType<Map>()
          .map((item) => conversationFrom(JsonCodec.asMap(item)))
          .toList(),
    );
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
            text: JsonCodec.stringOr(json['body'] ?? json['text'] ?? json['content'], ''),
            direction:
                outgoing ? MessageDirection.outgoing : MessageDirection.incoming,
            timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
            receiptStatus: null,
            senderInitials: outgoing ? IsoDateRange.initials(contactName) : null,
          );
        })
        .toList();

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

  const StaffTasksMessagesMapper._();
}
