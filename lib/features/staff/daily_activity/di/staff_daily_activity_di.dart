import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../data/repositories/staff_daily_activity_repository_impl.dart';
import '../domain/repositories/staff_daily_activity_repository.dart';
import '../presentation/controllers/staff_daily_activity_controller.dart';

Future<void> setupStaffDailyActivityDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffDailyActivityRepository>(
    factory: () => StaffDailyActivityRepositoryImpl(
      api: getIt<AppApiClient>(),
    ),
  );

  await DIHelper.registerControllerFactory<StaffDailyActivityController>(
    factory: () => StaffDailyActivityController(
      repository: getIt<StaffDailyActivityRepository>(),
    ),
  );
}
