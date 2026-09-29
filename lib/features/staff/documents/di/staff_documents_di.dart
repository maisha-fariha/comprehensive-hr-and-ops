import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../data/repositories/staff_documents_repository_impl.dart';
import '../domain/repositories/staff_documents_repository.dart';
import '../presentation/controllers/staff_documents_controller.dart';

Future<void> setupStaffDocumentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffDocumentsRepository>(
    factory: () => StaffDocumentsRepositoryImpl(
      api: getIt<AppApiClient>(),
    ),
  );

  await DIHelper.registerControllerFactory<StaffDocumentsController>(
    factory: () => StaffDocumentsController(
      repository: getIt<StaffDocumentsRepository>(),
    ),
  );
}
