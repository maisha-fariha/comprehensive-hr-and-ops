import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/family_appointments_repository_impl.dart';
import '../domain/repositories/family_appointments_repository.dart';
import '../presentation/controllers/appointment_request_controller.dart';
import '../presentation/controllers/family_appointments_controller.dart';

/// Registers the Family Appointments feature's repository + controllers in
/// the shared `get_it` service locator, mirroring the pattern used by the
/// Staff Incidents feature (see
/// `../../../staff/incidents/di/staff_incidents_di.dart`).
///
/// Intentionally NOT called from `lib/core/di/service_locator.dart` yet
/// (wired centrally afterward) - each page in this feature safely
/// self-resolves its controller via `Get.find`/`Get.put(GetIt.instance<X>())`
/// regardless of whether this has been wired into app bootstrap.
Future<void> setupFamilyAppointmentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyAppointmentsRepository>(
    factory: () => FamilyAppointmentsRepositoryImpl(),
  );

  DIHelper.registerController<FamilyAppointmentsController>(
    factory: () => FamilyAppointmentsController(repository: getIt<FamilyAppointmentsRepository>()),
  );

  DIHelper.registerController<AppointmentRequestController>(
    factory: () => AppointmentRequestController(),
  );
}
