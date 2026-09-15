import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../data/mappers/staff_tasks_messages_mapper.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/message_contact.dart';
import '../../domain/entities/recurring_check_instance.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../domain/entities/tasks_messages_overview.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';
import '../widgets/staff_task_detail_sheet.dart';

/// GetX controller for the "Tasks & Messages" list screen.
class TasksMessagesController extends BaseController<TasksMessagesOverview> {
  final StaffTasksMessagesRepository repository;

  TasksMessagesController({required this.repository}) {
    loadOverview();
  }

  final Rx<TasksMessagesTab> selectedTab = TasksMessagesTab.tasks.obs;
  final Rx<TaskFilter> selectedFilter = TaskFilter.all.obs;
  final RxList<MessageContact> contacts = <MessageContact>[].obs;
  final RxBool isLoadingContacts = false.obs;
  final RxBool isStartingConversation = false.obs;

  TasksMessagesOverview? get overview => state.value.data;

  List<StaffTask> get _allTasks => overview?.tasks ?? const [];

  List<StaffTask> get filteredTasks =>
      StaffTasksMessagesMapper.filterTasks(_allTasks, selectedFilter.value);

  List<RecurringCheckInstance> get recurringChecks =>
      overview?.recurringChecks ?? const [];

  List<ConversationPreview> get conversations =>
      overview?.conversations ?? const [];

  int countFor(TaskFilter filter) {
    final stats = overview?.stats;
    if (stats == null) return 0;
    return switch (filter) {
      TaskFilter.all => stats.all,
      TaskFilter.overdue => stats.overdue,
      TaskFilter.dueToday => stats.dueToday,
      TaskFilter.done => stats.done,
    };
  }

  void selectTab(TasksMessagesTab tab) {
    selectedTab.value = tab;
    if (tab == TasksMessagesTab.messages && contacts.isEmpty) {
      loadContacts();
    }
  }

  void selectFilter(TaskFilter filter) {
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
  }

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> loadContacts() async {
    isLoadingContacts.value = true;
    final result = await repository.getContacts();
    result.when(
      success: (items) => contacts.assignAll(items),
      failure: (_) {},
    );
    isLoadingContacts.value = false;
  }

  void clearConversationUnread(String conversationId) {
    final current = overview;
    if (current == null) return;
    final updated = current.conversations
        .map(
          (c) => c.id == conversationId ? c.copyWith(unreadCount: 0) : c,
        )
        .toList();
    setSuccess(current.copyWith(conversations: updated));
  }

  Future<void> markAllConversationsRead() async {
    final result = await repository.markAllConversationsRead();
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not mark conversations read',
      );
      return;
    }
    final current = overview;
    if (current != null) {
      setSuccess(
        current.copyWith(
          conversations: current.conversations
              .map((c) => c.copyWith(unreadCount: 0))
              .toList(),
        ),
      );
    }
    AppSnackbar.show('All caught up', 'Conversations marked as read.');
  }

  Future<ConversationPreview?> startConversation({
    required String title,
    required List<String> memberUserIds,
    String firstMessage = '',
  }) async {
    if (isStartingConversation.value) return null;
    isStartingConversation.value = true;
    final result = await repository.startConversation(
      title: title,
      memberUserIds: memberUserIds,
    );
    ConversationPreview? created;
    if (result.isSuccess) {
      final conversation = result.value;
      if (conversation != null) {
        created = conversation;
        final current = overview;
        if (current != null) {
          final list = <ConversationPreview>[
            conversation,
            ...current.conversations.where((c) => c.id != conversation.id),
          ];
          setSuccess(current.copyWith(conversations: list));
        }
        final text = firstMessage.trim();
        if (text.isNotEmpty) {
          await repository.sendMessage(
            conversationId: conversation.id,
            body: text,
          );
        }
        AppSnackbar.show('Conversation started', conversation.name);
      }
    } else {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not start conversation',
      );
    }
    isStartingConversation.value = false;
    return created;
  }

  Future<void> openTask(StaffTask task) async {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    await showStaffTaskDetailSheet(context, taskId: task.id, controller: this);
  }

  Future<void> completeTask(String taskId) async {
    final result = await repository.completeTask(taskId);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not complete task',
      );
      return;
    }
    AppSnackbar.show('Task completed', 'Marked as completed.');
    await loadOverview();
  }

  Future<void> addTaskNote({
    required String taskId,
    required String body,
  }) async {
    final text = body.trim();
    if (text.isEmpty) return;
    final result = await repository.addTaskNote(taskId: taskId, body: text);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not add note',
      );
      return;
    }
    AppSnackbar.show('Note added', 'Your note was saved.');
  }

  Future<void> completeRecurringCheck(RecurringCheckInstance check) async {
    final result = await repository.updateRecurringCheck(
      instanceId: check.id,
      status: 'completed',
      statusNote: 'Completed from Tasks tab',
    );
    if (result.isFailure) {
      final skip = await repository.updateRecurringCheck(
        instanceId: check.id,
        status: 'skipped',
        statusNote: 'Recorded from Tasks tab',
      );
      if (skip.isFailure) {
        AppErrorDialog.showResultError(
          result.error ?? skip.error,
          fallbackTitle: 'Could not update check',
        );
        return;
      }
    }
    AppSnackbar.show('Check updated', check.title);
    await loadOverview();
  }

  @override
  Future<void> refresh() => loadOverview();
}
