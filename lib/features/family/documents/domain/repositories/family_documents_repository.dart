import 'package:gems_core/gems_core.dart';

import '../entities/family_documents_overview.dart';

/// Contract for fetching the list of documents shared with a family member.
/// The presentation layer only ever depends on this interface, so swapping
/// the mocked [FamilyDocumentsRepositoryImpl] for a real API-backed
/// implementation later requires no changes above the data layer.
abstract class FamilyDocumentsRepository {
  Future<Result<FamilyDocumentsOverview>> getOverview();
}
