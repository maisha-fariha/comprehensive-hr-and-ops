import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../domain/entities/staff_medication_overview.dart';
import '../../domain/repositories/staff_medication_repository.dart';

/// GetX controller for the Staff "Medication MAR" screen.
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

  Future<void> markAdministered(String doseId) =>
      _record(doseId, status: 'administered');

  Future<void> markNotGiven(String doseId) => _record(doseId, status: 'refused');

  Future<void> _record(String doseId, {required String status}) async {
    final dose = _findDose(doseId);
    if (dose == null) return;
    final residenceId = dose.residenceId.isNotEmpty
        ? dose.residenceId
        : (Get.find<UserSession>().residenceId ?? '');
    if (dose.clientId.isEmpty || dose.medicationId.isEmpty || residenceId.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Could not record dose',
        message: 'This dose is missing client or medication details.',
      );
      return;
    }

    setLoading(true);
    final result = await repository.recordAdministration(
      clientId: dose.clientId,
      residenceId: residenceId,
      medicationId: dose.medicationId,
      status: status,
    );
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not record dose',
      );
      return;
    }
    await loadOverview();
  }

  DueDose? _findDose(String doseId) {
    final current = overview;
    if (current == null) return null;
    for (final dose in [...current.dueNowDoses, ...current.laterTodayDoses]) {
      if (dose.id == doseId) return dose;
    }
    return null;
  }

  @override
  Future<void> refresh() => loadOverview();
}
