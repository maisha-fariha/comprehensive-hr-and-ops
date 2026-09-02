import 'package:gems_core/gems_core.dart';

import '../entities/family_document.dart';
import '../entities/family_documents_overview.dart';

abstract class FamilyDocumentsRepository {
  Future<Result<FamilyDocumentsOverview>> getOverview();

  Future<Result<String?>> resolveDownloadUrl(FamilyDocument document);
}
