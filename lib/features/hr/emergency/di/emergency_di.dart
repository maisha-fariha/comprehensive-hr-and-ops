import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/emergency_repository_impl.dart';
import '../domain/repositories/emergency_repository.dart';
import '../presentation/controllers/emergency_controller.dart';

Future<void> setupHrEmergencyDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<EmergencyRepository>(
    factory: () => EmergencyRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<EmergencyController>(
    factory: () => EmergencyController(
      repository: getIt<EmergencyRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
