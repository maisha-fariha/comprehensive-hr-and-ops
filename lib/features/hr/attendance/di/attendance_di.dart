import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/attendance_repository_impl.dart';
import '../domain/repositories/attendance_repository.dart';
import '../presentation/controllers/attendance_controller.dart';

/// Registers the HR Attendance feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by the HR
/// Dashboard feature (see `dashboard_di.dart`).
Future<void> setupHrAttendanceDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<AttendanceRepository>(
    factory: () => AttendanceRepositoryImpl(),
  );

  DIHelper.registerController<AttendanceController>(
    factory: () => AttendanceController(repository: getIt<AttendanceRepository>()),
  );
}
