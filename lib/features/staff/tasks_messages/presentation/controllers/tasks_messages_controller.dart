import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/staff_task.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../domain/entities/tasks_messages_overview.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';

/// GetX controller for the "Tasks & Messages" list screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the selected top-level tab
/// ("Tasks"/"Messages") and the selected filter chip on the "Tasks" tab.
class TasksMessagesController extends BaseController<TasksMessagesOverview> {
  final StaffTasksMessagesRepository repository;

  TasksMessagesController({required this.repository}) {
    loadOverview();
  }

  final Rx<TasksMessagesTab> selectedTab = TasksMessagesTab.tasks.obs;
  final Rx<TaskFilter> selectedFilter = TaskFilter.all.obs;

  TasksMessagesOverview? get overview => state.value.data;

  /// Tasks matching the currently selected filter chip.
  List<StaffTask> get filteredTasks {
    final tasks = overview?.tasks ?? const <StaffTask>[];
    return switch (selectedFilter.value) {
      TaskFilter.all => tasks,
      TaskFilter.overdue => tasks.where((task) => task.status == TaskStatus.overdue).toList(),
      TaskFilter.dueToday => tasks.where((task) => task.status == TaskStatus.pending).toList(),
      TaskFilter.done => tasks.where((task) => task.status == TaskStatus.done).toList(),
    };
  }

  /// Count shown next to a filter chip's label, e.g. "Overdue (1)".
  int countFor(TaskFilter filter) {
    final tasks = overview?.tasks ?? const <StaffTask>[];
    return switch (filter) {
      TaskFilter.all => tasks.length,
      TaskFilter.overdue => tasks.where((task) => task.status == TaskStatus.overdue).length,
      TaskFilter.dueToday => tasks.where((task) => task.status == TaskStatus.pending).length,
      TaskFilter.done => tasks.where((task) => task.status == TaskStatus.done).length,
    };
  }

  void selectTab(TasksMessagesTab tab) => selectedTab.value = tab;

  void selectFilter(TaskFilter filter) => selectedFilter.value = filter;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadOverview();
}
