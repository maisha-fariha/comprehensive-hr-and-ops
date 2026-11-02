import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/finance_repository_impl.dart';
import '../domain/repositories/finance_repository.dart';
import '../presentation/controllers/finance_controller.dart';

Future<void> setupHrFinanceDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FinanceRepository>(
    factory: () => FinanceRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<FinanceController>(
    factory: () => FinanceController(
      repository: getIt<FinanceRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
