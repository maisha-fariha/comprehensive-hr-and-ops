import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../data/repositories/staff_tasks_messages_repository_impl.dart';
import '../domain/repositories/staff_tasks_messages_repository.dart';
import '../presentation/controllers/tasks_messages_controller.dart';

Future<void> setupStaffTasksMessagesDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffTasksMessagesRepository>(
    factory: () => StaffTasksMessagesRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<TasksMessagesController>(
    factory: () => TasksMessagesController(
      repository: getIt<StaffTasksMessagesRepository>(),
    ),
  );
}
