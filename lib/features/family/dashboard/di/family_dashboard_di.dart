import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/family_dashboard_repository_impl.dart';
import '../domain/repositories/family_dashboard_repository.dart';
import '../presentation/controllers/family_dashboard_controller.dart';

Future<void> setupFamilyDashboardDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyDashboardRepository>(
    factory: () => FamilyDashboardRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<FamilyDashboardController>(
    factory: () =>
        FamilyDashboardController(repository: getIt<FamilyDashboardRepository>()),
  );
}
