import 'package:gems_core/gems_core.dart';

import '../entities/staff_document.dart';

abstract class StaffDocumentsRepository {
  Future<Result<StaffDocumentsSummary>> getSummary();

  Future<Result<StaffDocumentsPageResult>> listDocuments({
    int page = 1,
    int limit = 20,
    String? search,
    String? ownerType,
    String? documentTypeId,
    String? status,
    String? visibility,
    bool includeDeleted = false,
  });

  Future<Result<List<StaffDocumentType>>> listTypes({
    bool includeArchived = false,
  });

  Future<Result<StaffDocumentType>> createType({
    required String name,
    required String appliesTo,
  });

  Future<Result<void>> archiveType(String id);

  Future<Result<void>> restoreType(String id);

  Future<Result<String>> uploadFile({
    required String localPath,
    required String fileName,
  });

  Future<Result<StaffDocument>> createDocument(StaffCreateDocumentInput input);

  Future<Result<void>> withdrawDocument(String id);

  Future<Result<void>> restoreDocument(String id);

  Future<Result<List<StaffDocumentOwnerOption>>> listClients();

  Future<Result<List<StaffDocumentOwnerOption>>> listStaff();

  Future<Result<List<StaffDocumentOwnerOption>>> listResidences();
}
