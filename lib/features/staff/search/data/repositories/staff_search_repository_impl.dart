import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../domain/entities/staff_search_record.dart';
import '../../domain/repositories/staff_search_repository.dart';
import '../mappers/staff_search_mapper.dart';

class StaffSearchRepositoryImpl implements StaffSearchRepository {
  final AppApiClient _api;

  StaffSearchRepositoryImpl({required AppApiClient api}) : _api = api;

  /// Web session endpoint; `/mobile/me` omits `tenant.modules`.
  static const String meEndpoint = '/me';

  @override
  Future<Result<StaffTenantModules>> getTenantModules() async {
    final result = await _api.get(meEndpoint, silent: true);
    return result.when(
      success: (body) => Result.success(StaffSearchMapper.modulesFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffSearchRecord>>> searchRecords(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Result.success(const <StaffSearchRecord>[]);

    final result = await _api.get(
      ApiEndpoints.search,
      query: {'q': trimmed},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(StaffSearchMapper.recordsFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }
}
