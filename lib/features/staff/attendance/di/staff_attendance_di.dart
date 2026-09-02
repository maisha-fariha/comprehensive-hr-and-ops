import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../data/repositories/staff_attendance_repository_impl.dart';
import '../domain/repositories/staff_attendance_repository.dart';
import '../presentation/controllers/staff_attendance_controller.dart';

Future<void> setupStaffAttendanceDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffAttendanceRepository>(
    factory: () => StaffAttendanceRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<StaffAttendanceController>(
    factory: () => StaffAttendanceController(
      repository: getIt<StaffAttendanceRepository>(),
    ),
  );
}
