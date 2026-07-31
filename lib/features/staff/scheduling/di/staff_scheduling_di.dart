import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/staff_schedule_repository_impl.dart';
import '../domain/repositories/staff_schedule_repository.dart';
import '../presentation/controllers/staff_schedule_controller.dart';

/// Registers the Staff Scheduling feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by the HR
/// Dashboard feature (see `lib/features/hr/dashboard/di/dashboard_di.dart`).
Future<void> setupStaffSchedulingDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffScheduleRepository>(
    factory: () => StaffScheduleRepositoryImpl(),
  );

  DIHelper.registerController<StaffScheduleController>(
    factory: () => StaffScheduleController(repository: getIt<StaffScheduleRepository>()),
  );
}
