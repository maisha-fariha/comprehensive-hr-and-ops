import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/staff_incidents_repository_impl.dart';
import '../domain/repositories/staff_incidents_repository.dart';
import '../presentation/controllers/incident_creation_controller.dart';
import '../presentation/controllers/incident_details_controller.dart';
import '../presentation/controllers/staff_incidents_controller.dart';

/// Registers the Staff Incidents feature's repository + controllers in the
/// shared `get_it` service locator, mirroring the pattern used by the
/// Manager Incidents feature (see `../../hr/incidents/di/incidents_di.dart`).
///
/// Intentionally NOT called from `lib/main.dart`/`lib/app.dart` yet (out of
/// scope for this task) - each page in this feature safely self-resolves
/// its controller via `Get.find`/`Get.put(GetIt.instance<X>())` regardless
/// of whether this has been wired into app bootstrap.
Future<void> setupStaffIncidentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffIncidentsRepository>(
    factory: () => StaffIncidentsRepositoryImpl(),
  );

  DIHelper.registerController<StaffIncidentsController>(
    factory: () => StaffIncidentsController(repository: getIt<StaffIncidentsRepository>()),
  );

  DIHelper.registerController<IncidentDetailsController>(
    factory: () => IncidentDetailsController(repository: getIt<StaffIncidentsRepository>()),
  );

  DIHelper.registerController<IncidentCreationController>(
    factory: () => IncidentCreationController(),
  );
}
