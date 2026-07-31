import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/tasks_compliance_repository_impl.dart';
import '../domain/repositories/tasks_compliance_repository.dart';
import '../presentation/controllers/tasks_compliance_controller.dart';

/// Registers the HR Tasks & Compliance feature's repository + controller in
/// the shared `get_it` service locator, mirroring the pattern used by every
/// other feature in the `flutter_gems` reference app
/// (see `flutter_gems/lib/di/todo/todo_di.dart`).
Future<void> setupHrTasksComplianceDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<TasksComplianceRepository>(
    factory: () => TasksComplianceRepositoryImpl(),
  );

  DIHelper.registerController<TasksComplianceController>(
    factory: () => TasksComplianceController(repository: getIt<TasksComplianceRepository>()),
  );
}
