import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/family_document.dart';
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

  @override
  Future<Result<String?>> resolveDownloadUrl(FamilyDocument document) async {
    if (document.downloadUrl != null && document.downloadUrl!.isNotEmpty) {
      return Result.success(document.downloadUrl);
    }
    final uploadId = document.uploadId;
    if (uploadId == null || uploadId.isEmpty) {
      return Result.success(null);
    }
    final result = await _api.get(ApiEndpoints.uploadDownload(uploadId));
    return result.when(
      success: (body) async {
        if (body is String && body.trim().startsWith('http')) {
          return Result.success(body.trim());
        }
        final json = JsonCodec.unwrapMap(body);
        return Result.success(
          JsonCodec.string(json['url'] ?? json['downloadUrl'] ?? json['href']),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }
}
