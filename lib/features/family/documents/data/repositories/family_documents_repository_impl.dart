import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../domain/entities/family_documents_overview.dart';
import '../../domain/repositories/family_documents_repository.dart';
import '../mappers/family_documents_mapper.dart';

class FamilyDocumentsRepositoryImpl implements FamilyDocumentsRepository {
  final AppApiClient _api;

  FamilyDocumentsRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<FamilyDocumentsOverview>> getOverview() async {
    final result = await _api.get(ApiEndpoints.familyDocuments);
    return result.when(
      success: (body) async =>
          Result.success(FamilyDocumentsMapper.fromBody(body)),
      failure: (error) async => Result.failure(error),
    );
  }
}
