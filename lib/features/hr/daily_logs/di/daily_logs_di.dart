import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/daily_logs_repository_impl.dart';
import '../domain/repositories/daily_logs_repository.dart';
import '../presentation/controllers/daily_logs_controller.dart';

/// Registers the HR Daily Logs feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by every
/// other feature in the `flutter_gems` reference app
/// (see `flutter_gems/lib/di/todo/todo_di.dart`).
Future<void> setupHrDailyLogsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<DailyLogsRepository>(
    factory: () => DailyLogsRepositoryImpl(),
  );

  DIHelper.registerController<DailyLogsController>(
    factory: () => DailyLogsController(repository: getIt<DailyLogsRepository>()),
  );
}
