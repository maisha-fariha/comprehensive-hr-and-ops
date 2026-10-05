import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/network/tenant_store.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/clients_repository_impl.dart';
import '../domain/repositories/clients_repository.dart';
import '../presentation/controllers/clients_controller.dart';

Future<void> setupHrClientsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<ClientsRepository>(
    factory: () => ClientsRepositoryImpl(
      api: getIt<AppApiClient>(),
      tokens: getIt<TokenStore>(),
      tenant: getIt<TenantStore>(),
    ),
  );

  DIHelper.registerController<ClientsController>(
    factory: () => ClientsController(
      repository: getIt<ClientsRepository>(),
      session: Get.isRegistered<UserSession>() ? Get.find<UserSession>() : null,
    ),
  );
}
