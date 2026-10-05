import 'package:gems_core/gems_core.dart';

import '../entities/hr_document.dart';

abstract class HrDocumentsRepository {
  /// `GET /documents`.
  Future<Result<HrDocumentPage>> list({
    required HrDocumentFilters filters,
    required int page,
    required int limit,
  });

  /// `GET /documents/summary` with the registry filters.
  Future<Result<HrDocumentsSummary>> summary(HrDocumentFilters filters);

  /// `GET /document-types`.
  Future<Result<List<HrDocumentType>>> types({bool includeArchived = false});

  Future<Result<HrDocumentType>> createType({
    required String name,
    required String appliesTo,
  });

  Future<Result<void>> archiveType(String id);

  Future<Result<void>> restoreType(String id);

  /// `POST /uploads?category=documents`; returns the stored `fileUrl`.
  Future<Result<String>> uploadFile(HrPickedFile file);

  Future<Result<HrDocument>> create(Map<String, dynamic> body);

  Future<Result<HrDocument>> update(String id, Map<String, dynamic> body);

  Future<Result<void>> withdraw(String id);

  Future<Result<void>> restore(String id);

  /// Queues the `document_expiry` CSV report.
  Future<Result<void>> exportReport();

  /// Authenticated download of a stored `fileUrl`.
  Future<Result<HrDocumentFile>> download(String fileUrl, String fallbackName);

  /// Records a document can be filed against: `client`, `staff` or
  /// `residence`.
  Future<Result<List<HrDocumentOwner>>> owners(String ownerType);
}
