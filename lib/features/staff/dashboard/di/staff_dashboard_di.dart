import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/staff_dashboard_repository_impl.dart';
import '../domain/repositories/staff_dashboard_repository.dart';
import '../presentation/controllers/staff_dashboard_controller.dart';

/// Registers the Staff Dashboard feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by the HR
/// Dashboard feature (see `lib/features/hr/dashboard/di/dashboard_di.dart`).
Future<void> setupStaffDashboardDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffDashboardRepository>(
    factory: () => StaffDashboardRepositoryImpl(),
  );

  DIHelper.registerController<StaffDashboardController>(
    factory: () => StaffDashboardController(repository: getIt<StaffDashboardRepository>()),
  );
}
