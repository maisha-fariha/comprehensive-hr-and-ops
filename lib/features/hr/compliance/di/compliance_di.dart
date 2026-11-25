import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/compliance_repository_impl.dart';
import '../domain/repositories/compliance_repository.dart';
import '../presentation/controllers/compliance_controller.dart';

Future<void> setupHrComplianceDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<ComplianceRepository>(
    factory: () => ComplianceRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<ComplianceController>(
    factory: () => ComplianceController(
      repository: getIt<ComplianceRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
