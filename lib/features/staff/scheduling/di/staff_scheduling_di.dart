import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../data/repositories/staff_schedule_repository_impl.dart';
import '../domain/repositories/staff_schedule_repository.dart';
import '../presentation/controllers/staff_schedule_controller.dart';

Future<void> setupStaffSchedulingDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffScheduleRepository>(
    factory: () => StaffScheduleRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<StaffScheduleController>(
    factory: () =>
        StaffScheduleController(repository: getIt<StaffScheduleRepository>()),
  );
}
