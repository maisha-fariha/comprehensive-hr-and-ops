import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/medication_repository_impl.dart';
import '../domain/repositories/medication_repository.dart';
import '../presentation/controllers/medication_controller.dart';

/// Registers the HR Medication feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by the HR
/// Dashboard feature (`lib/features/hr/dashboard/di/dashboard_di.dart`).
Future<void> setupHrMedicationDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<MedicationRepository>(
    factory: () => MedicationRepositoryImpl(),
  );

  DIHelper.registerController<MedicationController>(
    factory: () => MedicationController(repository: getIt<MedicationRepository>()),
  );
}
