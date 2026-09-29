import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../data/repositories/staff_appointments_repository_impl.dart';
import '../domain/repositories/staff_appointments_repository.dart';
import '../presentation/controllers/staff_appointments_controller.dart';

Future<void> setupStaffAppointmentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffAppointmentsRepository>(
    factory: () => StaffAppointmentsRepositoryImpl(
      api: getIt<AppApiClient>(),
    ),
  );

  await DIHelper.registerControllerFactory<StaffAppointmentsController>(
    factory: () => StaffAppointmentsController(
      repository: getIt<StaffAppointmentsRepository>(),
    ),
  );
}
