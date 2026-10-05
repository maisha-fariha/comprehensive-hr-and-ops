import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/network/tenant_store.dart';
import '../../../../../core/network/token_store.dart';
import '../../domain/entities/mar_administration.dart';
import '../../domain/entities/mar_medication.dart';
import '../../domain/entities/mar_options.dart';
import '../../domain/entities/mar_round.dart';
import '../../domain/repositories/medication_repository.dart';
import '../mappers/medication_mapper.dart';
import '../medication_endpoints.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final AppApiClient _api;
  final TokenStore? _tokens;
  final TenantStore? _tenant;
  final Duration _pollInterval;

  MedicationRepositoryImpl({
    required AppApiClient api,
    TokenStore? tokens,
    TenantStore? tenant,
    Duration pollInterval = const Duration(milliseconds: 1200),
  })  : _api = api,
        _tokens = tokens,
        _tenant = tenant,
        _pollInterval = pollInterval;

  static Result<void> _done(Result<dynamic> result) => result.when(
        success: (_) => Result.success(null),
        failure: Result.failure,
      );

  static String? _blank(String? v) => v == null || v.trim().isEmpty ? null : v.trim();

  Future<Result<T>> _get<T>(
    String path,
    T Function(dynamic body) map, {
    Map<String, dynamic>? query,
  }) async {
    final result = await _api.get(path, query: query, silent: true);
    return result.when(success: (body) => Result.success(map(body)), failure: Result.failure);
  }

  Future<Result<void>> _post(String path, [Map<String, dynamic>? data]) async =>
      _done(await _api.post(path, data: data, silent: true, allowQueue: false));

  Future<Result<void>> _patch(String path, Map<String, dynamic> data) async =>
      _done(await _api.patch(path, data: data, silent: true, allowQueue: false));

  Future<Result<void>> _delete(String path) async =>
      _done(await _api.delete(path, silent: true, allowQueue: false));

  static Map<String, dynamic> _page({String? residenceId, String? clientId}) => {
        'page': 1,
        'limit': MedicationEndpoints.maxPageLimit,
        'residenceId': ?_blank(residenceId),
        'clientId': ?_blank(clientId),
      };

  @override
  Future<Result<MarRound>> round({String? residenceId}) => _get(
        MedicationEndpoints.round,
        MedicationMapper.roundFrom,
        query: {'residenceId': ?_blank(residenceId)},
      );

  @override
  Future<Result<List<MarMedication>>> medications({String? residenceId}) => _get(
        MedicationEndpoints.medications,
        MedicationMapper.medicationsFrom,
        query: _page(residenceId: residenceId),
      );

  @override
  Future<Result<List<MarMedication>>> prnMedications({String? residenceId}) => _get(
        MedicationEndpoints.prnMedications,
        MedicationMapper.prnsFrom,
        query: _page(residenceId: residenceId),
      );

  @override
  Future<Result<List<MarAdministration>>> administrations() => _get(
        MedicationEndpoints.administrations,
        MedicationMapper.administrationsFrom,
        query: const {'page': 1, 'limit': 50},
      );

  @override
  Future<Result<MarResidentChart>> residentChart(String clientId) =>
      _get(MedicationEndpoints.residentChart(clientId), MedicationMapper.chartFrom);

  @override
  Future<Result<List<MarOption>>> residences() => _get(
        MedicationEndpoints.residences,
        MedicationMapper.residencesFrom,
        query: _page(),
      );

  @override
  Future<Result<List<MarClientOption>>> clients() => _get(
        MedicationEndpoints.clients,
        MedicationMapper.clientsFrom,
        query: _page(),
      );

  @override
  Future<Result<List<MarOption>>> approvedStaff() => _get(
        MedicationEndpoints.staff,
        MedicationMapper.approvedStaffFrom,
        query: _page(),
      );

  @override
  Future<Result<List<MarOption>>> witnesses(String residenceId) => _get(
        MedicationEndpoints.witnesses,
        MedicationMapper.witnessesFrom,
        query: {'residenceId': residenceId},
      );

  @override
  Future<Result<List<MarOption>>> checkSchedules({String? clientId}) => _get(
        MedicationEndpoints.checkSchedules,
        MedicationMapper.checkSchedulesFrom,
        query: {'clientId': ?_blank(clientId), 'limit': MedicationEndpoints.maxPageLimit},
      );

  @override
  Future<Result<void>> createMedication(MarMedicineDraft draft) =>
      _post(MedicationEndpoints.medications, MedicationMapper.prescriptionBody(draft));

  @override
  Future<Result<void>> createMedicationBatch(List<MarMedicineDraft> drafts) => _post(
        MedicationEndpoints.medicationBatch,
        MedicationMapper.prescriptionBatchBody(drafts),
      );

  @override
  Future<Result<void>> updateMedication(String id, MarMedicineDraft draft) =>
      _patch(
        MedicationEndpoints.medication(id),
        MedicationMapper.prescriptionBody(draft, update: true),
      );

  @override
  Future<Result<void>> discontinueMedication(String id) =>
      _post(MedicationEndpoints.discontinueMedication(id));

  @override
  Future<Result<void>> deleteMedication(String id) =>
      _delete(MedicationEndpoints.medication(id));

  @override
  Future<Result<void>> createPrn(MarMedicineDraft draft) =>
      _post(MedicationEndpoints.prnMedications, MedicationMapper.prnBody(draft));

  @override
  Future<Result<void>> createPrnBatch(List<MarMedicineDraft> drafts) =>
      _post(MedicationEndpoints.prnBatch, MedicationMapper.prnBatchBody(drafts));

  @override
  Future<Result<void>> updatePrn(String id, MarMedicineDraft draft) =>
      _patch(
        MedicationEndpoints.prnMedication(id),
        MedicationMapper.prnBody(draft, update: true),
      );

  @override
  Future<Result<void>> discontinuePrn(String id) =>
      _post(MedicationEndpoints.discontinuePrn(id));

  @override
  Future<Result<void>> deletePrn(String id) =>
      _delete(MedicationEndpoints.prnMedication(id));

  @override
  Future<Result<void>> chartRound(MarRoundDraft draft) =>
      _post(MedicationEndpoints.administrationRound, MedicationMapper.roundBody(draft));

  @override
  Future<Result<void>> fileEvidence({
    required MarEvidenceFile file,
    required String name,
    required String clientId,
  }) async {
    final MultipartFile part;
    try {
      part = await MultipartFile.fromFile(file.path, filename: file.name);
    } catch (_) {
      return Result.failure(ApiError(message: 'Could not read ${file.name}'));
    }
    final upload = await _api.post(
      MedicationEndpoints.uploads,
      data: FormData.fromMap({'file': part}),
      query: const {'category': 'documents'},
      silent: true,
      allowQueue: false,
    );
    if (upload.isFailure) {
      return Result.failure(upload.error ?? const ApiError(message: 'The upload failed'));
    }
    final url = JsonCodec.string(JsonCodec.unwrapMap(upload.value)['fileUrl']);
    if (url == null) {
      return Result.failure(const ApiError(message: 'The upload did not return a file'));
    }
    return _post(MedicationEndpoints.documents, {
      'name': name,
      'fileUrl': url,
      'ownerType': 'client',
      'ownerId': clientId,
      'visibility': 'management_only',
    });
  }

  @override
  Future<Result<void>> amend(
    String administrationId, {
    required String reason,
    String? status,
    String? doseReason,
  }) =>
      _post(MedicationEndpoints.amendments(administrationId), {
        'reason': reason,
        'status': ?status,
        'doseReason': ?doseReason,
      });

  @override
  Future<Result<List<int>>> exportMarCsv() async {
    final server = await _serverExport();
    if (server.isSuccess && (server.value?.isNotEmpty ?? false)) return server;
    return _localExport();
  }

  /// The web flow: create the export, poll it, then download. Roles without
  /// `reports:read` get 403 on the poll and fall back to [_localExport].
  Future<Result<List<int>>> _serverExport() async {
    final create = await _api.post(
      MedicationEndpoints.reportExports,
      data: const {'reportKey': 'mar_administrations', 'format': 'csv'},
      silent: true,
      allowQueue: false,
    );
    if (create.isFailure) {
      return Result.failure(
        create.error ?? const ApiError(message: 'Could not create the export.'),
      );
    }
    final exportId = JsonCodec.string(JsonCodec.unwrapMap(create.value)['id']);
    if (exportId == null) {
      return Result.failure(const ApiError(message: 'The export has no id.'));
    }
    var status = JsonCodec.stringOr(JsonCodec.unwrapMap(create.value)['status'], 'queued')
        .toLowerCase();
    for (var attempt = 0; attempt < 25 && status != 'ready'; attempt++) {
      if (status == 'failed') {
        return Result.failure(const ApiError(message: 'The export failed on the server.'));
      }
      await Future<void>.delayed(_pollInterval);
      final poll = await _api.get(MedicationEndpoints.reportExport(exportId), silent: true);
      if (poll.isFailure) {
        return Result.failure(
          poll.error ?? const ApiError(message: 'Could not check the export.'),
        );
      }
      status = JsonCodec.stringOr(JsonCodec.unwrapMap(poll.value)['status'], status)
          .toLowerCase();
    }
    if (status != 'ready') {
      return Result.failure(
        const ApiError(
          message:
              'Export is still running — it will appear on the Reports page when it finishes.',
        ),
      );
    }
    return _download(MedicationEndpoints.reportExportDownload(exportId));
  }

  Future<Result<List<int>>> _download(String path) async {
    const failed = ApiError(message: 'Could not download the export file.');
    try {
      final token = _tokens?.accessToken;
      final subdomain = _tenant?.subdomain;
      final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      final response = await Dio().get<List<int>>(
        '$base$path',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'text/csv, application/octet-stream, */*',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            if (subdomain != null && subdomain.isNotEmpty) 'X-Tenant-Subdomain': subdomain,
          },
          validateStatus: (code) => code != null && code < 500,
        ),
      );
      final code = response.statusCode ?? 0;
      final bytes = response.data ?? const <int>[];
      if (code < 200 || code >= 300 || bytes.isEmpty) return Result.failure(failed);
      return Result.success(bytes);
    } catch (_) {
      return Result.failure(failed);
    }
  }

  /// Every page of `GET /mar/administrations`.
  Future<Result<List<int>>> _localExport() async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    var totalPages = 1;
    do {
      final result = await _api.get(
        MedicationEndpoints.administrations,
        query: {'page': page, 'limit': MedicationEndpoints.maxPageLimit},
        silent: true,
      );
      if (result.isFailure) {
        return Result.failure(
          result.error ?? const ApiError(message: 'Could not load MAR records for export.'),
        );
      }
      rows.addAll(JsonCodec.unwrapList(result.value).whereType<Map>().map(JsonCodec.asMap));
      totalPages = JsonCodec.integerOr(JsonCodec.metaOf(result.value)?['totalPages'], 1);
      page++;
    } while (page <= totalPages && page <= 50);
    return Result.success(utf8.encode(MedicationMapper.csvFrom(rows)));
  }
}
