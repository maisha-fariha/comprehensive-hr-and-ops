import 'package:gems_core/gems_core.dart';

import '../entities/family_document.dart';
import '../entities/family_documents_overview.dart';

class FamilyDocumentResident {
  final String id;
  final String name;

  const FamilyDocumentResident({required this.id, required this.name});
}

abstract class FamilyDocumentsRepository {
  Future<Result<FamilyDocumentsOverview>> getOverview();

  Future<Result<List<FamilyDocumentResident>>> linkedResidents();

  /// Uploads to `family-uploads`, then `POST /family/documents`.
  Future<Result<void>> sendDocument({
    required String clientId,
    required String name,
    required String category,
    required String localPath,
    required String fileName,
    String? notes,
  });

  /// Resolves and downloads file bytes via `GET /files/.../link` (preferred)
  /// or documented fallbacks, so the UI can open the file.
  Future<Result<FamilyDocumentOpenPayload>> openDocument(
    FamilyDocument document,
  );

  /// `POST /family/documents/{id}/sign`.
  Future<Result<void>> signDocument(String id);
}
