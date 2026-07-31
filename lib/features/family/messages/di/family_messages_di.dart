import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/family_messages_repository_impl.dart';
import '../domain/repositories/family_messages_repository.dart';
import '../presentation/controllers/compose_message_controller.dart';
import '../presentation/controllers/family_messages_controller.dart';

/// Registers the Family "Messages" feature's repository + controllers in the
/// shared `get_it` service locator, mirroring the pattern used by
/// `lib/features/staff/tasks_messages/di/staff_tasks_messages_di.dart`.
///
/// NOTE: unlike the HR feature DI files, this is intentionally **not**
/// wired into `lib/core/di/service_locator.dart` yet - call this from the
/// app's startup once the Family portal shell is ready to be assembled.
///
/// [ComposeMessageController] is registered for consistency with the rest
/// of the app's feature modules, but `ComposeMessagePage` always constructs
/// a fresh instance directly (mirroring
/// `lib/features/staff/incidents/presentation/pages/create_incident_page.dart`'s
/// `IncidentCreationController` handling) rather than resolving it through
/// `GetIt`, so re-opening the compose screen never resurfaces a previous
/// draft's field values.
Future<void> setupFamilyMessagesDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyMessagesRepository>(
    factory: () => FamilyMessagesRepositoryImpl(),
  );

  DIHelper.registerController<FamilyMessagesController>(
    factory: () => FamilyMessagesController(repository: getIt<FamilyMessagesRepository>()),
  );

  DIHelper.registerController<ComposeMessageController>(
    factory: () => ComposeMessageController(),
  );
}
