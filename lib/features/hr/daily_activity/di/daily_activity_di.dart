import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/daily_activity_repository_impl.dart';
import '../domain/repositories/daily_activity_repository.dart';
import '../presentation/controllers/daily_activity_controller.dart';

Future<void> setupHrDailyActivityDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<DailyActivityRepository>(
    factory: () => DailyActivityRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<DailyActivityController>(
    factory: () => DailyActivityController(
      repository: getIt<DailyActivityRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
