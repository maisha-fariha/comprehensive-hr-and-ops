import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/network/tenant_store.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/residences_repository_impl.dart';
import '../domain/repositories/residences_repository.dart';
import '../presentation/controllers/residences_controller.dart';

Future<void> setupHrResidencesDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<ResidencesRepositoryImpl>(
    factory: () => ResidencesRepositoryImpl(
      api: getIt<AppApiClient>(),
      tokens: getIt<TokenStore>(),
      tenant: getIt<TenantStore>(),
    ),
  );
  DIHelper.registerRepository<ResidencesRepository>(
    factory: () => getIt<ResidencesRepositoryImpl>(),
  );
  DIHelper.registerRepository<ResidenceAdminRepository>(
    factory: () => getIt<ResidencesRepositoryImpl>(),
  );

  DIHelper.registerController<ResidencesController>(
    factory: () => ResidencesController(
      repository: getIt<ResidencesRepository>(),
      admin: getIt<ResidenceAdminRepository>(),
      session: Get.isRegistered<UserSession>() ? Get.find<UserSession>() : null,
    ),
  );
}
