import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../data/repositories/family_documents_repository_impl.dart';
import '../domain/repositories/family_documents_repository.dart';
import '../presentation/controllers/family_documents_controller.dart';

Future<void> setupFamilyDocumentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyDocumentsRepository>(
    factory: () => FamilyDocumentsRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<FamilyDocumentsController>(
    factory: () => FamilyDocumentsController(
      repository: getIt<FamilyDocumentsRepository>(),
    ),
  );
}
