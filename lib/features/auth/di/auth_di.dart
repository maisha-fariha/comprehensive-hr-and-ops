import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/network/response_cache.dart';
import '../../../core/network/tenant_store.dart';
import '../../../core/network/token_store.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../presentation/controllers/auth_controller.dart';

Future<void> setupAuthDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<TenantStore>(
    factory: () => TenantStore(getIt<SharedPreferences>()),
    lazy: false,
  );
  await getIt<TenantStore>().load();

  DIHelper.registerRepository<TokenStore>(
    factory: () => TokenStore(
      getIt<SharedPreferences>(),
      getIt<ApiService>(),
    ),
    lazy: false,
  );
  getIt<TokenStore>().applyToClient();

  final cache = ResponseCache(getIt<DatabaseService>());
  await cache.ensureReady();
  DIHelper.registerRepository<ResponseCache>(
    factory: () => cache,
    lazy: false,
  );

  DIHelper.registerRepository<AppApiClient>(
    factory: () => AppApiClient(
      getIt<ApiService>(),
      getIt<TenantStore>(),
      cache: getIt<ResponseCache>(),
      sync: getIt<SyncService>(),
      connectivity: Get.isRegistered<ConnectivityMonitor>()
          ? Get.find<ConnectivityMonitor>()
          : null,
    ),
  );

  DIHelper.registerRepository<AuthRepository>(
    factory: () => AuthRepositoryImpl(
      api: getIt<AppApiClient>(),
      tokens: getIt<TokenStore>(),
      tenant: getIt<TenantStore>(),
      cache: getIt<ResponseCache>(),
    ),
  );

  DIHelper.registerController<AuthController>(
    factory: () => AuthController(repository: getIt<AuthRepository>()),
  );
}
