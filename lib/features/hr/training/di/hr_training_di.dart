import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/hr_training_repository_impl.dart';
import '../domain/repositories/hr_training_repository.dart';
import '../presentation/controllers/hr_training_controller.dart';

Future<void> setupHrTrainingDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<HrTrainingRepository>(
    factory: () => HrTrainingRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<HrTrainingController>(
    factory: () => HrTrainingController(
      repository: getIt<HrTrainingRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
