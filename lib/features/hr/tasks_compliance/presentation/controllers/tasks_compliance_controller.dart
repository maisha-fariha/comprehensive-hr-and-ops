import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/tasks_compliance_enums.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import '../../domain/repositories/tasks_compliance_repository.dart';

/// GetX controller for the "Tasks & Compliance" screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the selected-tab state for
/// the screen's top segmented control (Tasks / Compliance / Corrective),
/// since all 3 Figma frames share one header/layout and only swap their
/// body content.
class TasksComplianceController extends BaseController<TasksComplianceOverview> {
  final TasksComplianceRepository repository;

  TasksComplianceController({required this.repository}) {
    loadOverview();
  }

  final Rx<TasksComplianceTab> selectedTab = TasksComplianceTab.tasks.obs;

  TasksComplianceOverview? get overview => state.value.data;

  void selectTab(TasksComplianceTab tab) => selectedTab.value = tab;

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
