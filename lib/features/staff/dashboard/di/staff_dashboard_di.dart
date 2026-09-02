import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../data/repositories/staff_dashboard_repository_impl.dart';
import '../domain/repositories/staff_dashboard_repository.dart';
import '../presentation/controllers/staff_dashboard_controller.dart';

Future<void> setupStaffDashboardDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffDashboardRepository>(
    factory: () => StaffDashboardRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<StaffDashboardController>(
    factory: () =>
        StaffDashboardController(repository: getIt<StaffDashboardRepository>()),
  );
}
