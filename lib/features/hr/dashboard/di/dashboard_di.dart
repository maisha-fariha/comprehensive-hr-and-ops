import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/dashboard_repository_impl.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../presentation/controllers/dashboard_controller.dart';

/// Registers the HR Dashboard feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by every
/// other feature in the `flutter_gems` reference app
/// (see `flutter_gems/lib/di/todo/todo_di.dart`).
Future<void> setupHrDashboardDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<DashboardRepository>(
    factory: () => DashboardRepositoryImpl(),
  );

  DIHelper.registerController<DashboardController>(
    factory: () => DashboardController(repository: getIt<DashboardRepository>()),
  );
}
