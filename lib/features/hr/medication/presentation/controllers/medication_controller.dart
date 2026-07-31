import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/medication_overview.dart';
import '../../domain/repositories/medication_repository.dart';

/// GetX controller for the "Medication MAR" screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app. All 4 Figma screens ("Overview", "Due", "Missed",
/// "Refused") are implemented as tabs of a single page sharing one header,
/// so tab selection lives here as a simple `Rx` instead of 4 separate
/// controllers/pages.
class MedicationController extends BaseController<MedicationOverview> {
  final MedicationRepository repository;

  final Rx<MedicationTab> selectedTab = MedicationTab.overview.obs;
  final Rx<SchedulePeriod> selectedSchedulePeriod = SchedulePeriod.today.obs;

  MedicationController({required this.repository}) {
    loadOverview();
  }

  MedicationOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  void selectTab(MedicationTab tab) => selectedTab.value = tab;

  void selectSchedulePeriod(SchedulePeriod period) => selectedSchedulePeriod.value = period;

  @override
  Future<void> refresh() => loadOverview();
}
