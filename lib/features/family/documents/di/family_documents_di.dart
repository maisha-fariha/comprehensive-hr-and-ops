import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/family_documents_repository_impl.dart';
import '../domain/repositories/family_documents_repository.dart';
import '../presentation/controllers/family_documents_controller.dart';

/// Registers the Family "Documents" feature's repository + controller in the
/// shared `get_it` service locator, mirroring the pattern used by every HR/
/// Staff feature module (see `lib/features/hr/dashboard/di/dashboard_di.dart`).
///
/// NOTE: unlike the HR feature DI files, this is intentionally **not**
/// wired into `lib/core/di/service_locator.dart` yet — call this from the
/// app's startup once the Family portal's "More" hub is assembled.
Future<void> setupFamilyDocumentsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyDocumentsRepository>(
    factory: () => FamilyDocumentsRepositoryImpl(),
  );

  DIHelper.registerController<FamilyDocumentsController>(
    factory: () => FamilyDocumentsController(repository: getIt<FamilyDocumentsRepository>()),
  );
}
