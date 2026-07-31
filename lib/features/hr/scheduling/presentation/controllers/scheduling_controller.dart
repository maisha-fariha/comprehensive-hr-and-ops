import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../../domain/repositories/scheduling_repository.dart';

/// GetX controller for the HR/Manager Scheduling screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the selected-segmented-tab
/// state (Calendar / Board / Requests) since all 3 tabs live on one screen.
class SchedulingController extends BaseController<SchedulingOverview> {
  final SchedulingRepository repository;

  final Rx<SchedulingTab> selectedTab = SchedulingTab.calendar.obs;

  SchedulingController({required this.repository}) {
    loadOverview();
  }

  SchedulingOverview? get overview => state.value.data;

  void selectTab(SchedulingTab tab) => selectedTab.value = tab;

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
