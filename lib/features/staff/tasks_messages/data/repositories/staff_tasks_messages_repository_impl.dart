import 'package:gems_core/gems_core.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/message_thread.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../domain/entities/tasks_messages_overview.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';

/// Initials used for the tiny sender avatar next to every outgoing chat
/// bubble, representing the signed-in staff member (a placeholder, since
/// there is no logged-in staff user profile wired up yet).
const String _currentStaffInitials = 'DL';

/// Local implementation of [StaffTasksMessagesRepository].
///
/// There is no backend endpoint for this screen yet, so this returns the
/// exact static content shown in the reference screenshot for the
/// Tasks/Messages tabs and the Angela M. conversation thread. Replace the
/// body of these methods with a real `ApiService`/`BaseRepository` call
/// (see `flutter_gems/lib/repositories/todo_repository.dart` for the
/// established pattern) once an API contract exists - the domain layer and
/// every widget above it will keep working unchanged.
class StaffTasksMessagesRepositoryImpl implements StaffTasksMessagesRepository {
  @override
  Future<Result<TasksMessagesOverview>> getOverview() async {
    return Result.success(
      const TasksMessagesOverview(
        tasks: [
          StaffTask(
            id: 'fire-drill',
            title: 'Fire Drill',
            dueTimeLabel: '8:00 AM',
            location: 'Sunrise Home',
            status: TaskStatus.overdue,
          ),
          StaffTask(
            id: 'client-room-checks',
            title: 'Client Room Checks',
            dueTimeLabel: '10:00 AM',
            location: 'Sunrise Home',
            status: TaskStatus.pending,
          ),
          StaffTask(
            id: 'document-vitals',
            title: 'Document Vitals',
            dueTimeLabel: '12:00 PM',
            location: 'Sunrise Home',
            status: TaskStatus.pending,
          ),
          StaffTask(
            id: 'laundry',
            title: 'Laundry',
            dueTimeLabel: '2:00 PM',
            location: 'Sunrise Home',
            status: TaskStatus.pending,
          ),
          StaffTask(
            id: 'morning-med-round',
            title: 'Morning Med Round',
            dueTimeLabel: '7:00 AM',
            location: 'Sunrise Home',
            status: TaskStatus.done,
          ),
          StaffTask(
            id: 'breakfast-assist',
            title: 'Breakfast Assist',
            dueTimeLabel: '7:45 AM',
            location: 'Sunrise Home',
            status: TaskStatus.done,
          ),
        ],
        conversations: [
          ConversationPreview(
            id: 'angela-m',
            name: 'Angela M. (RN)',
            initials: 'AM',
            timeLabel: '9:24 AM',
            previewText: 'Please confirm the fire drill was completed on your shift.',
            priority: MessagePriority.highPriority,
            isOnline: true,
          ),
          ConversationPreview(
            id: 'priya-k',
            name: 'Priya K.',
            initials: 'PK',
            timeLabel: '8:50 AM',
            previewText: 'Handover notes for Room 4 are updated — take a look.',
            priority: MessagePriority.routine,
            isOnline: true,
          ),
          ConversationPreview(
            id: 'robert-t',
            name: 'Robert T. (Supervisor)',
            initials: 'RT',
            timeLabel: 'Yesterday',
            previewText: 'Reminder: training module 3 is due by Friday.',
            priority: MessagePriority.general,
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<MessageThread>> getThread(String conversationId) async {
    final thread = _threadsById[conversationId];
    if (thread == null) {
      return Result.failure(UnknownError(message: 'Conversation not found.'));
    }
    return Result.success(thread);
  }

  static final Map<String, MessageThread> _threadsById = {
    'angela-m': const MessageThread(
      conversationId: 'angela-m',
      contactName: 'Angela M. (RN)',
      contactInitials: 'AM',
      isActiveNow: true,
      isOtherPersonTyping: true,
      messages: [
        ChatMessage(
          id: 'angela-1',
          text: 'Morning! Just checking in — did the fire drill happen on your shift?',
          direction: MessageDirection.incoming,
          timeLabel: '8:58 AM',
        ),
        ChatMessage(
          id: 'angela-2',
          text: "Hi Angela! Not yet — it's scheduled for 8:00 but the alarm panel was being serviced.",
          direction: MessageDirection.outgoing,
          timeLabel: '9:02 AM',
          receiptStatus: 'Seen',
          senderInitials: _currentStaffInitials,
        ),
        ChatMessage(
          id: 'angela-3',
          text: 'Understood. Please run it as soon as the panel is back online and log the time.',
          direction: MessageDirection.incoming,
          timeLabel: '9:05 AM',
        ),
        ChatMessage(
          id: 'angela-4',
          text: "Will do. Technician says it'll be ready by 10.",
          direction: MessageDirection.outgoing,
          timeLabel: '9:06 AM',
          receiptStatus: 'Seen',
          senderInitials: _currentStaffInitials,
        ),
        ChatMessage(
          id: 'angela-5',
          text: "I'll mark the task done and message you the completion time.",
          direction: MessageDirection.outgoing,
          timeLabel: '9:24 AM',
          receiptStatus: 'Delivered',
          senderInitials: _currentStaffInitials,
        ),
      ],
    ),
    'priya-k': const MessageThread(
      conversationId: 'priya-k',
      contactName: 'Priya K.',
      contactInitials: 'PK',
      isActiveNow: true,
      messages: [
        ChatMessage(
          id: 'priya-1',
          text: 'Handover notes for Room 4 are updated — take a look.',
          direction: MessageDirection.incoming,
          timeLabel: '8:50 AM',
        ),
      ],
    ),
    'robert-t': const MessageThread(
      conversationId: 'robert-t',
      contactName: 'Robert T. (Supervisor)',
      contactInitials: 'RT',
      isActiveNow: false,
      messages: [
        ChatMessage(
          id: 'robert-1',
          text: 'Reminder: training module 3 is due by Friday.',
          direction: MessageDirection.incoming,
          timeLabel: 'Yesterday',
        ),
      ],
    ),
  };
}
