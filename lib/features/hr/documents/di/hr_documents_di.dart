import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/network/tenant_store.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/hr_documents_repository_impl.dart';
import '../domain/repositories/hr_documents_repository.dart';
import '../presentation/controllers/hr_documents_controller.dart';

Future<void> setupHrDocumentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<HrDocumentsRepository>(
    factory: () => HrDocumentsRepositoryImpl(
      api: getIt<AppApiClient>(),
      tokens: getIt<TokenStore>(),
      tenant: getIt<TenantStore>(),
    ),
  );

  DIHelper.registerController<HrDocumentsController>(
    factory: () => HrDocumentsController(
      repository: getIt<HrDocumentsRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
