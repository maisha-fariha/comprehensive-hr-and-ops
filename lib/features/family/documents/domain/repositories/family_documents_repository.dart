import 'package:gems_core/gems_core.dart';

import '../entities/family_document.dart';
import '../entities/family_documents_overview.dart';

abstract class FamilyDocumentsRepository {
  Future<Result<FamilyDocumentsOverview>> getOverview();

  /// Resolves and downloads file bytes via `GET /files/.../link` (preferred)
  /// or documented fallbacks, so the UI can open the file.
  Future<Result<FamilyDocumentOpenPayload>> openDocument(
    FamilyDocument document,
  );
}
