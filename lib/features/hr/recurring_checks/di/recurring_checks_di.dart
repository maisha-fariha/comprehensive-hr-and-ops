import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/recurring_checks_repository_impl.dart';
import '../domain/repositories/recurring_checks_repository.dart';
import '../presentation/controllers/recurring_checks_controller.dart';

Future<void> setupHrRecurringChecksDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<RecurringChecksRepository>(
    factory: () => RecurringChecksRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<RecurringChecksController>(
    factory: () => RecurringChecksController(
      repository: getIt<RecurringChecksRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
