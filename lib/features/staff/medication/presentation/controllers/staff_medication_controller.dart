import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/due_dose.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../domain/entities/staff_medication_overview.dart';
import '../../domain/repositories/staff_medication_repository.dart';

/// GetX controller for the Staff "Medication MAR" screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app. All 4 Figma screens ("Due", "Administered",
/// "Missed", "Refused") are implemented as tabs of a single page sharing
/// one header, so tab selection lives here as a simple `Rx` instead of 4
/// separate controllers/pages.
class StaffMedicationController extends BaseController<StaffMedicationOverview> {
  final StaffMedicationRepository repository;

  final Rx<StaffMedicationTab> selectedTab = StaffMedicationTab.due.obs;

  StaffMedicationController({required this.repository}) {
    loadOverview();
  }

  StaffMedicationOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  void selectTab(StaffMedicationTab tab) => selectedTab.value = tab;

  /// Marks the given "Due" tab dose as administered. This only updates the
  /// in-memory mock state held by this controller — there is no backend for
  /// dose actions yet.
  void markAdministered(String doseId) => _updateDueDoseStatus(doseId, DueDoseStatus.administered);

  /// Marks the given "Due" tab dose as not given. This only updates the
  /// in-memory mock state held by this controller — there is no backend for
  /// dose actions yet.
  void markNotGiven(String doseId) => _updateDueDoseStatus(doseId, DueDoseStatus.notGiven);

  void _updateDueDoseStatus(String doseId, DueDoseStatus status) {
    final current = overview;
    if (current == null) return;

    List<DueDose> apply(List<DueDose> doses) {
      return [
        for (final dose in doses)
          if (dose.id == doseId) dose.copyWith(status: status) else dose,
      ];
    }

    setSuccess(
      current.copyWith(
        dueNowDoses: apply(current.dueNowDoses),
        laterTodayDoses: apply(current.laterTodayDoses),
      ),
    );
  }

  @override
  Future<void> refresh() => loadOverview();
}
