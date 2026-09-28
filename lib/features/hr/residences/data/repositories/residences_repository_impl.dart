import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/residence_summary.dart';
import '../../domain/repositories/residences_repository.dart';
import '../mappers/residences_mapper.dart';

class ResidencesRepositoryImpl implements ResidencesRepository {
  static const _pageSize = 100;
  static const _maxPages = 5;

  final AppApiClient _api;

  ResidencesRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<List<ResidenceSummary>>> getResidences() async {
    final results = await Future.wait([
      _fetchAllPages(ApiEndpoints.residences),
      _fetchAllPages(ApiEndpoints.clients, silent: true),
    ]);
    final residences = results[0];
    if (residences.isFailure) {
      return Result.failure(
        residences.error ??
            const ApiError(message: 'Could not load residences.'),
      );
    }
    final clients = results[1];
    final counts = clients.isSuccess
        ? ResidencesMapper.residentCountsFrom(clients.value ?? const [])
        : const <String, int>{};
    return Result.success(
      ResidencesMapper.residencesFrom(
        residences.value ?? const [],
        residentCounts: counts,
      ),
    );
  }

  @override
  Future<Result<List<ResidenceRoom>>> getRooms(String residenceId) async {
    final result = await _api.get(
      '${ApiEndpoints.residences}/$residenceId/rooms',
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(ResidencesMapper.roomsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<List<dynamic>>> _fetchAllPages(
    String path, {
    bool silent = false,
  }) async {
    final all = <dynamic>[];
    for (var page = 1; page <= _maxPages; page++) {
      final result = await _api.get(
        path,
        query: {'page': page, 'limit': _pageSize},
        silent: silent,
      );
      if (result.isFailure) {
        return Result.failure(
          result.error ?? const ApiError(message: 'Could not load data.'),
        );
      }
      final rows = JsonCodec.unwrapList(result.value);
      all.addAll(rows);
      final hasNext = JsonCodec.boolean(JsonCodec.metaOf(result.value)?['hasNext']);
      if (hasNext == false || rows.length < _pageSize) break;
    }
    return Result.success(all);
  }
}
