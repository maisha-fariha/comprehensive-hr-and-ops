import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../data/mappers/staff_tasks_messages_mapper.dart';
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

  TasksMessagesOverview? get overview => state.value.data;

  /// Full list from `GET /tasks`; chips filter this in-memory.
  List<StaffTask> get _allTasks => overview?.tasks ?? const [];

  List<StaffTask> get filteredTasks =>
      StaffTasksMessagesMapper.filterTasks(_allTasks, selectedFilter.value);

  List<RecurringCheckInstance> get recurringChecks =>
      overview?.recurringChecks ?? const [];

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

  void selectTab(TasksMessagesTab tab) => selectedTab.value = tab;

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
