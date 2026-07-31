import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/staff_daily_logs_repository_impl.dart';
import '../domain/repositories/staff_daily_logs_repository.dart';
import '../presentation/controllers/daily_note_controller.dart';
import '../presentation/controllers/staff_daily_logs_controller.dart';

/// Registers the Staff Daily Logs feature's repository + controllers in
/// the shared `get_it` service locator, mirroring the pattern used by the
/// Manager Daily Logs feature (see
/// `lib/features/hr/daily_logs/di/daily_logs_di.dart`).
///
/// NOTE: this must be called explicitly from wherever the app wires up its
/// service locator (e.g. `lib/core/di/service_locator.dart`) - it is not
/// invoked automatically by this feature module.
Future<void> setupStaffDailyLogsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffDailyLogsRepository>(
    factory: () => StaffDailyLogsRepositoryImpl(),
  );

  DIHelper.registerController<StaffDailyLogsController>(
    factory: () => StaffDailyLogsController(repository: getIt<StaffDailyLogsRepository>()),
  );

  DIHelper.registerController<DailyNoteController>(
    factory: () => DailyNoteController(repository: getIt<StaffDailyLogsRepository>()),
  );
}
