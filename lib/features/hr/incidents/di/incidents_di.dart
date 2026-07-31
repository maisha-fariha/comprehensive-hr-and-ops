import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/incidents_repository_impl.dart';
import '../domain/repositories/incidents_repository.dart';
import '../presentation/controllers/incident_creation_controller.dart';
import '../presentation/controllers/incidents_controller.dart';

/// Registers the HR Incidents feature's repository + controllers in the
/// shared `get_it` service locator, mirroring the pattern used by the
/// Dashboard feature (see `dashboard_di.dart`).
Future<void> setupHrIncidentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<IncidentsRepository>(
    factory: () => IncidentsRepositoryImpl(),
  );

  DIHelper.registerController<IncidentsController>(
    factory: () => IncidentsController(repository: getIt<IncidentsRepository>()),
  );

  DIHelper.registerController<IncidentCreationController>(
    factory: () => IncidentCreationController(),
  );
}
