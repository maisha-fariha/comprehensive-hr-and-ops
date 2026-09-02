import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/family_daily_updates_repository_impl.dart';
import '../domain/repositories/family_daily_updates_repository.dart';
import '../presentation/controllers/family_daily_updates_controller.dart';

Future<void> setupFamilyDailyUpdatesDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyDailyUpdatesRepository>(
    factory: () => FamilyDailyUpdatesRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<FamilyDailyUpdatesController>(
    factory: () => FamilyDailyUpdatesController(
      repository: getIt<FamilyDailyUpdatesRepository>(),
    ),
  );
}
