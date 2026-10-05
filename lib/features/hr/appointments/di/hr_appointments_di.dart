import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/network/tenant_store.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/hr_appointments_repository_impl.dart';
import '../domain/repositories/hr_appointments_repository.dart';
import '../presentation/controllers/hr_appointments_controller.dart';

Future<void> setupHrAppointmentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<HrAppointmentsRepository>(
    factory: () => HrAppointmentsRepositoryImpl(
      api: getIt<AppApiClient>(),
      tokens: getIt<TokenStore>(),
      tenant: getIt<TenantStore>(),
    ),
  );

  DIHelper.registerController<HrAppointmentsController>(
    factory: () => HrAppointmentsController(
      repository: getIt<HrAppointmentsRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
