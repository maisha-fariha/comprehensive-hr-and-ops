import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../data/repositories/staff_training_repository_impl.dart';
import '../domain/repositories/staff_training_repository.dart';
import '../presentation/controllers/staff_training_controller.dart';
import '../presentation/controllers/staff_training_course_controller.dart';

Future<void> setupStaffTrainingDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffTrainingRepository>(
    factory: () => StaffTrainingRepositoryImpl(
      api: getIt<AppApiClient>(),
    ),
  );

  await DIHelper.registerControllerFactory<StaffTrainingController>(
    factory: () => StaffTrainingController(
      repository: getIt<StaffTrainingRepository>(),
    ),
  );

  await DIHelper.registerControllerFactory<StaffTrainingCourseController>(
    factory: () => StaffTrainingCourseController(
      repository: getIt<StaffTrainingRepository>(),
    ),
  );
}
