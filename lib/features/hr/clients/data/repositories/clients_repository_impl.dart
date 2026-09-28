import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/client_summary.dart';
import '../../domain/repositories/clients_repository.dart';
import '../mappers/clients_mapper.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  static const _pageSize = 100;
  static const _maxPages = 5;

  final AppApiClient _api;

  ClientsRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<List<ClientSummary>>> getClients() async {
    final all = <dynamic>[];
    for (var page = 1; page <= _maxPages; page++) {
      final result = await _api.get(
        ApiEndpoints.clients,
        query: {'page': page, 'limit': _pageSize},
      );
      if (result.isFailure) {
        return Result.failure(
          result.error ?? const ApiError(message: 'Could not load clients.'),
        );
      }
      final rows = JsonCodec.unwrapList(result.value);
      all.addAll(rows);
      final hasNext = JsonCodec.boolean(JsonCodec.metaOf(result.value)?['hasNext']);
      if (hasNext == false || rows.length < _pageSize) break;
    }
    return Result.success(ClientsMapper.clientsFrom(all));
  }

  @override
  Future<Result<ClientSummary>> getClient(String clientId) async {
    final result = await _api.get(
      '${ApiEndpoints.clients}/$clientId',
      silent: true,
    );
    return result.when(
      success: (body) async {
        final client = ClientsMapper.clientFrom(JsonCodec.unwrap(body));
        return client == null
            ? Result.failure(const ApiError(message: 'Client not found.'))
            : Result.success(client);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<Map<String, String>>> getResidenceNames() async {
    final result = await _api.get(
      ApiEndpoints.residences,
      query: {'page': 1, 'limit': _pageSize},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(ClientsMapper.residenceNamesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }
}
