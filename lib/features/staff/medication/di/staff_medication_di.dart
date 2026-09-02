import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../data/repositories/staff_medication_repository_impl.dart';
import '../domain/repositories/staff_medication_repository.dart';
import '../presentation/controllers/staff_medication_controller.dart';

Future<void> setupStaffMedicationDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffMedicationRepository>(
    factory: () => StaffMedicationRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<StaffMedicationController>(
    factory: () => StaffMedicationController(
      repository: getIt<StaffMedicationRepository>(),
    ),
  );
}
