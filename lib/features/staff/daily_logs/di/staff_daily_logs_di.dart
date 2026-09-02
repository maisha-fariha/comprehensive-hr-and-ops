import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../data/repositories/staff_daily_logs_repository_impl.dart';
import '../domain/repositories/staff_daily_logs_repository.dart';
import '../presentation/controllers/daily_note_controller.dart';
import '../presentation/controllers/staff_daily_logs_controller.dart';

Future<void> setupStaffDailyLogsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffDailyLogsRepository>(
    factory: () => StaffDailyLogsRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<StaffDailyLogsController>(
    factory: () => StaffDailyLogsController(
      repository: getIt<StaffDailyLogsRepository>(),
    ),
  );

  DIHelper.registerController<DailyNoteController>(
    factory: () => DailyNoteController(
      repository: getIt<StaffDailyLogsRepository>(),
    ),
  );
}
