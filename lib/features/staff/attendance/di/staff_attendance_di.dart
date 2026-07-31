import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/staff_attendance_repository_impl.dart';
import '../domain/repositories/staff_attendance_repository.dart';
import '../presentation/controllers/staff_attendance_controller.dart';

/// Registers the Staff Attendance feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by the HR
/// Dashboard feature (see `lib/features/hr/dashboard/di/dashboard_di.dart`).
Future<void> setupStaffAttendanceDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffAttendanceRepository>(
    factory: () => StaffAttendanceRepositoryImpl(),
  );

  DIHelper.registerController<StaffAttendanceController>(
    factory: () => StaffAttendanceController(repository: getIt<StaffAttendanceRepository>()),
  );
}
