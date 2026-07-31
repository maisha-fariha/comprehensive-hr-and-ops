import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/staff_medication_repository_impl.dart';
import '../domain/repositories/staff_medication_repository.dart';
import '../presentation/controllers/staff_medication_controller.dart';

/// Registers the Staff Medication feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by the HR
/// Medication feature (`lib/features/hr/medication/di/medication_di.dart`).
///
/// This is intentionally NOT called from the app's shared bootstrap — the
/// feature's page self-resolves its controller (see
/// `StaffMedicationPage._resolveController`), so callers only need to invoke
/// this once before first navigating to the page.
Future<void> setupStaffMedicationDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffMedicationRepository>(
    factory: () => StaffMedicationRepositoryImpl(),
  );

  DIHelper.registerController<StaffMedicationController>(
    factory: () => StaffMedicationController(repository: getIt<StaffMedicationRepository>()),
  );
}
