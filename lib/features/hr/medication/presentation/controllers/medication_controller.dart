import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/medication_overview.dart';
import '../../domain/entities/schedule_dose.dart';
import '../../domain/repositories/medication_repository.dart';

/// GetX controller for the "Medication MAR" screen.
class MedicationController extends BaseController<MedicationOverview> {
  final MedicationRepository repository;

  final Rx<MedicationTab> selectedTab = MedicationTab.overview.obs;
  final Rx<SchedulePeriod> selectedSchedulePeriod = SchedulePeriod.today.obs;

  int _loadGeneration = 0;

  MedicationController({required this.repository}) {
    loadOverview();
  }

  MedicationOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getOverview();
    if (generation != _loadGeneration) return;
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  void selectTab(MedicationTab tab) => selectedTab.value = tab;

  void selectSchedulePeriod(SchedulePeriod period) =>
      selectedSchedulePeriod.value = period;

  List<ScheduleDose> dosesForPeriod(List<ScheduleDose> doses) {
    final period = selectedSchedulePeriod.value;
    if (period == SchedulePeriod.today) return doses;
    return doses.where((dose) {
      final hour = dose.scheduledHour;
      if (hour == null) return true;
      return switch (period) {
        SchedulePeriod.morning => hour >= 5 && hour < 12,
        SchedulePeriod.afternoon => hour >= 12 && hour < 17,
        SchedulePeriod.evening => hour >= 17 || hour < 5,
        SchedulePeriod.today => true,
      };
    }).toList();
  }

  @override
  Future<void> refresh() => loadOverview();
}
