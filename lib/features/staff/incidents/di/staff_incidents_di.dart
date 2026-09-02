import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../data/repositories/staff_incidents_repository_impl.dart';
import '../domain/repositories/staff_incidents_repository.dart';
import '../presentation/controllers/incident_creation_controller.dart';
import '../presentation/controllers/incident_details_controller.dart';
import '../presentation/controllers/staff_incidents_controller.dart';

Future<void> setupStaffIncidentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffIncidentsRepository>(
    factory: () => StaffIncidentsRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<StaffIncidentsController>(
    factory: () => StaffIncidentsController(
      repository: getIt<StaffIncidentsRepository>(),
    ),
  );

  DIHelper.registerController<IncidentDetailsController>(
    factory: () => IncidentDetailsController(
      repository: getIt<StaffIncidentsRepository>(),
    ),
  );

  DIHelper.registerController<IncidentCreationController>(
    factory: () => IncidentCreationController(),
  );
}
