import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/family_appointments_repository_impl.dart';
import '../domain/repositories/family_appointments_repository.dart';
import '../presentation/controllers/appointment_request_controller.dart';
import '../presentation/controllers/family_appointments_controller.dart';

Future<void> setupFamilyAppointmentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyAppointmentsRepository>(
    factory: () => FamilyAppointmentsRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<FamilyAppointmentsController>(
    factory: () => FamilyAppointmentsController(
      repository: getIt<FamilyAppointmentsRepository>(),
    ),
  );

  DIHelper.registerController<AppointmentRequestController>(
    factory: () => AppointmentRequestController(),
  );
}
