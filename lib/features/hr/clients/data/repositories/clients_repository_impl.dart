import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/network/tenant_store.dart';
import '../../../../../core/network/token_store.dart';
import '../../domain/entities/client_extras.dart';
import '../../domain/entities/client_goals.dart';
import '../../domain/entities/client_summary.dart';
import '../../domain/repositories/clients_repository.dart';
import '../clients_endpoints.dart';
import '../mappers/clients_mapper.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  static const _optionsLimit = 100;
  static const _exportPageSize = 100;
  static const _exportMaxPages = 20;

  final AppApiClient _api;
  final TokenStore? _tokens;
  final TenantStore? _tenant;

  ClientsRepositoryImpl({
    required AppApiClient api,
    TokenStore? tokens,
    TenantStore? tenant,
  })  : _api = api,
        _tokens = tokens,
        _tenant = tenant;

  @override
  Future<Result<ClientPage>> getClients({
    required int page,
    required int limit,
    String? search,
    String? residenceId,
  }) async {
    final q = search?.trim() ?? '';
    final result = await _api.get(
      ClientsEndpoints.clients,
      query: {
        'page': page,
        'limit': limit,
        if (q.isNotEmpty) 'search': q,
        if (residenceId != null && residenceId.isNotEmpty)
          'residenceId': residenceId,
      },
    );
    return result.when(
      success: (body) => Result.success(ClientsMapper.pageFrom(body, limit: limit)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<ClientSummary>> getClient(String clientId) async {
    final result = await _api.get(ClientsEndpoints.client(clientId), silent: true);
    return result.when(
      success: (body) => _clientResult(body),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<Map<String, String>>> getResidenceNames() async {
    final result = await _api.get(
      ClientsEndpoints.residences,
      query: {'page': 1, 'limit': _optionsLimit},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(ClientsMapper.residenceNamesFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<int?>> getClientLimit() async {
    final result = await _api.get(ClientsEndpoints.me, silent: true);
    return result.when(
      success: (body) => Result.success(ClientsMapper.clientLimitFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<ClientSummary>> createClient(
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    final result = idempotencyKey == null
        ? await _api.post(
            ClientsEndpoints.clients,
            data: body,
            silent: true,
            allowQueue: false,
          )
        : await _api.postWithKey(
            ClientsEndpoints.clients,
            idempotencyKey: idempotencyKey,
            data: body,
            silent: true,
          );
    return result.when(success: _clientResult, failure: Result.failure);
  }

  @override
  Future<Result<ClientSummary>> updateClient(
    String clientId,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.patch(
      ClientsEndpoints.client(clientId),
      data: body,
      silent: true,
      allowQueue: false,
    );
    return result.when(success: _clientResult, failure: Result.failure);
  }

  @override
  Future<Result<void>> deleteClient(String clientId, {String? reason}) async {
    final result = await _api.delete(
      ClientsEndpoints.client(clientId),
      data: reason == null || reason.isEmpty ? null : {'reason': reason},
      silent: true,
      allowQueue: false,
    );
    return _done(result);
  }

  @override
  Future<Result<List<DeletedClient>>> getDeletedClients({String? search}) async {
    final q = search?.trim() ?? '';
    final result = await _api.get(
      ClientsEndpoints.deletedClients,
      query: {'page': 1, 'limit': _optionsLimit, if (q.isNotEmpty) 'search': q},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(ClientsMapper.deletedFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> restoreClient(String clientId) async => _done(
        await _api.post(ClientsEndpoints.restore(clientId), silent: true, allowQueue: false),
      );

  @override
  Future<Result<List<ClientGoalCategory>>> getGoalCategories() async {
    final result = await _api.get(ClientsEndpoints.goalCategories, silent: true);
    return result.when(
      success: (body) => Result.success(ClientsMapper.goalCategoriesFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<ClientGoal>>> getGoals(String clientId) async {
    final result = await _api.get(
      ClientsEndpoints.goals(clientId),
      query: const {'includeClosed': true},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(ClientsMapper.goalsFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> createGoal(String clientId, Map<String, dynamic> body) async => _done(
        await _api.post(
          ClientsEndpoints.goals(clientId),
          data: body,
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> updateGoal(
    String clientId,
    String goalId,
    Map<String, dynamic> body,
  ) async =>
      _done(
        await _api.patch(
          ClientsEndpoints.goal(clientId, goalId),
          data: body,
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> deleteGoal(String clientId, String goalId) async => _done(
        await _api.delete(
          ClientsEndpoints.goal(clientId, goalId),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<ClientGoalOutcomes>> getGoalOutcomes(String clientId) async {
    final result = await _api.get(ClientsEndpoints.goalOutcomes(clientId), silent: true);
    return result.when(
      success: (body) => Result.success(ClientsMapper.goalOutcomesFrom(body)),
      failure: Result.failure,
    );
  }

  static Result<void> _done(Result<dynamic> result) => result.when(
        success: (_) => Result.success(null),
        failure: Result.failure,
      );

  @override
  Future<Result<ClientSummary>> transferClient(
    String clientId,
    ClientTransferRequest request,
  ) async {
    final result = await _api.post(
      ClientsEndpoints.transfer(clientId),
      data: request.toJson(),
      silent: true,
      allowQueue: false,
    );
    return result.when(success: _clientResult, failure: Result.failure);
  }

  @override
  Future<Result<List<ClientFamilyMember>>> getFamily(String clientId) async {
    final result = await _api.get(ClientsEndpoints.family(clientId), silent: true);
    return result.when(
      success: (body) => Result.success(ClientsMapper.familyFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> addFamilyMember(
    String clientId,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.post(
      ClientsEndpoints.family(clientId),
      data: body,
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) => Result.success(null),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> updateFamilyMember(
    String clientId,
    String memberId,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.patch(
      ClientsEndpoints.familyMember(clientId, memberId),
      data: body,
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) => Result.success(null),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> removeFamilyMember(String clientId, String memberId) async {
    final result = await _api.delete(
      ClientsEndpoints.familyMember(clientId, memberId),
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) => Result.success(null),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<ClientRoom>>> getRooms(String residenceId) async {
    final result = await _api.get(ClientsEndpoints.rooms(residenceId), silent: true);
    return result.when(
      success: (body) => Result.success(ClientsMapper.roomsFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<ClientSpend>> getSpend(String clientId) async {
    final result = await _api.get(ClientsEndpoints.clientSpend(clientId), silent: true);
    return result.when(
      success: (body) => Result.success(ClientsMapper.spendFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<String>> uploadFile(ClientPickedFile file, String category) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });
      final result = await _api.post(
        ClientsEndpoints.uploads,
        data: form,
        query: {'category': category},
        silent: true,
        allowQueue: false,
      );
      return result.when(
        success: (body) {
          final map = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(map['fileUrl'] ?? map['url']);
          return url == null
              ? Result.failure(
                  const ApiError(message: 'Upload succeeded but file URL was missing.'),
                )
              : Result.success(url);
        },
        failure: Result.failure,
      );
    } catch (_) {
      return Result.failure(const ApiError(message: 'upload failed'));
    }
  }

  @override
  Future<Result<void>> fileCarePlanDocument({
    required String clientId,
    required String name,
    required String fileUrl,
  }) async {
    final result = await _api.post(
      ClientsEndpoints.documents,
      data: {
        'name': name,
        'fileUrl': fileUrl,
        'ownerType': 'client',
        'ownerId': clientId,
        'visibility': 'staff_only',
      },
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) => Result.success(null),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<int>>> exportRosterCsv() async {
    final server = await _tryServerRosterExport();
    if (server.isSuccess && (server.value?.isNotEmpty ?? false)) return server;
    if (server.error?.message == stillRunningMessage) return server;
    return _buildRosterCsvFromApi();
  }

  static const stillRunningMessage =
      'Export is still running — it will appear on the Reports page when it finishes.';

  Future<Result<List<int>>> _tryServerRosterExport() async {
    final create = await _api.post(
      ClientsEndpoints.reportExports,
      data: const {'reportKey': 'client_roster', 'format': 'csv'},
      silent: true,
      allowQueue: false,
    );
    if (create.isFailure) {
      return Result.failure(
        create.error ?? const ApiError(message: 'Could not create the export.'),
      );
    }
    final created = JsonCodec.unwrapMap(create.value);
    final exportId = JsonCodec.string(created['id']);
    if (exportId == null) {
      return Result.failure(
        const ApiError(message: 'Export was created but id was missing.'),
      );
    }

    var status = JsonCodec.stringOr(created['status'], 'queued').toLowerCase();
    for (var attempt = 0; attempt < 25; attempt++) {
      if (status == 'ready') return _downloadExportBytes(exportId);
      if (status == 'failed') {
        return Result.failure(
          const ApiError(message: 'The export failed on the server.'),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final poll = await _api.get(ClientsEndpoints.reportExport(exportId), silent: true);
      if (poll.isFailure) {
        return Result.failure(
          poll.error ?? const ApiError(message: 'Could not check export status.'),
        );
      }
      status = JsonCodec.stringOr(
        JsonCodec.unwrapMap(poll.value)['status'],
        status,
      ).toLowerCase();
    }
    if (status == 'ready') return _downloadExportBytes(exportId);
    return Result.failure(const ApiError(message: stillRunningMessage));
  }

  Future<Result<List<int>>> _downloadExportBytes(String exportId) async {
    try {
      final headers = <String, dynamic>{
        'Accept': 'text/csv, application/octet-stream, */*',
      };
      final token = _tokens?.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final subdomain = _tenant?.subdomain;
      if (subdomain != null && subdomain.isNotEmpty) {
        headers['X-Tenant-Subdomain'] = subdomain;
      }
      final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      final response = await Dio().get<List<int>>(
        '$base${ClientsEndpoints.reportExportDownload(exportId)}',
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
          validateStatus: (code) => code != null && code < 500,
        ),
      );
      final code = response.statusCode ?? 0;
      final bytes = response.data ?? const <int>[];
      if (code < 200 || code >= 300 || bytes.isEmpty) {
        return Result.failure(
          const ApiError(message: 'Could not download the export file.'),
        );
      }
      return Result.success(bytes);
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Could not download the export file.'),
      );
    }
  }

  Future<Result<List<int>>> _buildRosterCsvFromApi() async {
    final rows = <ClientSummary>[];
    for (var page = 1; page <= _exportMaxPages; page++) {
      final result = await _api.get(
        ClientsEndpoints.clients,
        query: {'page': page, 'limit': _exportPageSize},
        silent: true,
      );
      if (result.isFailure) {
        return Result.failure(
          result.error ?? const ApiError(message: 'Could not load clients for export.'),
        );
      }
      final parsed = ClientsMapper.pageFrom(result.value, limit: _exportPageSize);
      rows.addAll(parsed.items);
      if (page >= parsed.totalPages || parsed.items.length < _exportPageSize) break;
    }
    return Result.success(utf8.encode(rosterCsv(rows)));
  }

  /// The roster CSV built on the device.
  static String rosterCsv(List<ClientSummary> rows) {
    final buffer = StringBuffer()
      ..writeln(
        'Client Name,Client ID,Residence,Care Level,DOB,Room,Status,'
        'Admission Date,Gender,Funding Source',
      );
    for (final c in rows) {
      buffer.writeln(
        [
          c.fullName,
          c.id,
          c.residenceName ?? '',
          c.careLevel ?? '',
          _isoDate(c.dateOfBirth),
          c.room ?? '',
          c.status,
          _isoDate(c.admissionDate),
          c.gender ?? '',
          c.fundingSource ?? '',
        ].map(_csvCell).join(','),
      );
    }
    return buffer.toString();
  }

  static String _isoDate(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  static String _csvCell(String value) {
    final text = value.replaceAll('\r\n', ' ').replaceAll('\n', ' ').trim();
    if (text.contains(',') || text.contains('"')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  Result<ClientSummary> _clientResult(dynamic body) {
    final client = ClientsMapper.clientFrom(JsonCodec.unwrap(body));
    return client == null
        ? Result.failure(const ApiError(message: 'Client not found.'))
        : Result.success(client);
  }
}
