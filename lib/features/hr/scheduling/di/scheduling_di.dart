import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/scheduling_repository_impl.dart';
import '../domain/repositories/scheduling_repository.dart';
import '../presentation/controllers/scheduling_controller.dart';

/// Registers the HR Scheduling feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by the HR
/// Dashboard feature (see `dashboard_di.dart`).
Future<void> setupHrSchedulingDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<SchedulingRepository>(
    factory: () => SchedulingRepositoryImpl(),
  );

  DIHelper.registerController<SchedulingController>(
    factory: () => SchedulingController(repository: getIt<SchedulingRepository>()),
  );
}
