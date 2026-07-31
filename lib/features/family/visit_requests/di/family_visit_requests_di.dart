import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/visit_requests_repository_impl.dart';
import '../domain/repositories/visit_requests_repository.dart';
import '../presentation/controllers/family_visit_requests_controller.dart';
import '../presentation/controllers/visit_request_details_controller.dart';

/// Registers the Family Visit Requests feature's repository + controllers
/// in the shared `get_it` service locator, mirroring the pattern used by
/// every other feature module (see
/// `lib/features/staff/incidents/di/staff_incidents_di.dart`).
///
/// NOTE: unlike the HR feature DI files, this is intentionally **not**
/// wired into `lib/core/di/service_locator.dart` yet - call this from the
/// app's startup once the Family portal's "More" hub is assembled.
Future<void> setupFamilyVisitRequestsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<VisitRequestsRepository>(
    factory: () => VisitRequestsRepositoryImpl(),
  );

  DIHelper.registerController<FamilyVisitRequestsController>(
    factory: () => FamilyVisitRequestsController(repository: getIt<VisitRequestsRepository>()),
  );

  DIHelper.registerController<VisitRequestDetailsController>(
    factory: () => VisitRequestDetailsController(repository: getIt<VisitRequestsRepository>()),
  );
}
