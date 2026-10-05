import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/inventory_repository_impl.dart';
import '../domain/repositories/inventory_repository.dart';
import '../presentation/controllers/inventory_stock_controller.dart';
import '../presentation/controllers/purchasing_controller.dart';
import '../presentation/controllers/stock_counts_controller.dart';
import '../presentation/controllers/stock_transfers_controller.dart';

Future<void> setupHrInventoryDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<InventoryRepository>(
    factory: () => InventoryRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<InventoryStockController>(
    factory: () => InventoryStockController(
      repository: getIt<InventoryRepository>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<StockCountsController>(
    factory: () => StockCountsController(
      repository: getIt<InventoryRepository>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<StockTransfersController>(
    factory: () => StockTransfersController(
      repository: getIt<InventoryRepository>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<PurchasingController>(
    factory: () => PurchasingController(
      repository: getIt<InventoryRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
