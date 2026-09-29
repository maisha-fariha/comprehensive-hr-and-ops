import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/daily_logs_repository_impl.dart';
import '../domain/repositories/daily_logs_repository.dart';
import '../presentation/controllers/daily_logs_controller.dart';

Future<void> setupHrDailyLogsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<DailyLogsRepository>(
    factory: () => DailyLogsRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<DailyLogsController>(
    factory: () => DailyLogsController(
      repository: getIt<DailyLogsRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
