import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/network/tenant_store.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/roles/user_session.dart';

import '../data/repositories/medication_repository_impl.dart';
import '../domain/repositories/medication_repository.dart';
import '../presentation/controllers/medication_controller.dart';

/// Registers the manager Medication (MAR) repository and controller.
Future<void> setupHrMedicationDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<MedicationRepository>(
    factory: () => MedicationRepositoryImpl(
      api: getIt<AppApiClient>(),
      tokens: getIt<TokenStore>(),
      tenant: getIt<TenantStore>(),
    ),
  );

  DIHelper.registerController<MedicationController>(
    factory: () => MedicationController(
      repository: getIt<MedicationRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
