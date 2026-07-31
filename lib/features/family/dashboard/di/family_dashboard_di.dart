import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/family_dashboard_repository_impl.dart';
import '../domain/repositories/family_dashboard_repository.dart';
import '../presentation/controllers/family_dashboard_controller.dart';

/// Registers the Family Dashboard feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by every
/// other feature in the app (see `lib/features/hr/dashboard/di/dashboard_di.dart`).
Future<void> setupFamilyDashboardDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyDashboardRepository>(
    factory: () => FamilyDashboardRepositoryImpl(),
  );

  DIHelper.registerController<FamilyDashboardController>(
    factory: () => FamilyDashboardController(repository: getIt<FamilyDashboardRepository>()),
  );
}
