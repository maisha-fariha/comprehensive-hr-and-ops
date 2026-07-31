import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/staff_tasks_messages_repository_impl.dart';
import '../domain/repositories/staff_tasks_messages_repository.dart';
import '../presentation/controllers/tasks_messages_controller.dart';

/// Registers the Staff "Tasks & Messages" feature's repository + list-page
/// controller in the shared `get_it` service locator, mirroring the pattern
/// used by every HR feature module (see
/// `lib/features/hr/dashboard/di/dashboard_di.dart`).
///
/// NOTE: unlike the HR feature DI files, this is intentionally **not**
/// wired into `lib/core/di/service_locator.dart` yet - call this from the
/// app's startup once the Staff portal shell is ready to be assembled.
///
/// The per-conversation [MessageThreadController] (used by
/// `MessageThreadPage`) is deliberately not registered here: it needs a
/// fresh instance per conversation, so `MessageThreadPage` constructs and
/// tags it directly, resolving only the repository through `GetIt`.
Future<void> setupStaffTasksMessagesDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffTasksMessagesRepository>(
    factory: () => StaffTasksMessagesRepositoryImpl(),
  );

  DIHelper.registerController<TasksMessagesController>(
    factory: () => TasksMessagesController(repository: getIt<StaffTasksMessagesRepository>()),
  );
}
