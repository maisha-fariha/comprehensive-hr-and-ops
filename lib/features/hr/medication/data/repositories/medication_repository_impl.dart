import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/network/tenant_store.dart';
import '../../../../../core/network/token_store.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/client_medication_item.dart';
import '../../domain/entities/medication_overview.dart';
import '../../domain/repositories/medication_repository.dart';
import '../mappers/medication_mapper.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final AppApiClient _api;
  final UserSession _session;
  final TokenStore _tokens;
  final TenantStore _tenant;

  MedicationRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
    required TokenStore tokens,
    required TenantStore tenant,
  })  : _api = api,
        _session = session,
        _tokens = tokens,
        _tenant = tenant;

  @override
  Future<Result<MedicationOverview>> getOverview() async {
    final resolved = await _resolveResidence();
    final residenceId = resolved.$1;
    final residenceName = resolved.$2 ?? _session.residenceName;

    if (residenceId == null || residenceId.isEmpty) {
      return Result.failure(
        const ApiError(
          message:
              'No residence is selected for this account. Choose a residence, then open Medication again.',
        ),
      );
    }

    final dueQuery = <String, dynamic>{
      'date': IsoDateRange.todayDate,
      'residenceId': residenceId,
    };

    final dayScoped = <String, dynamic>{
      'from': IsoDateRange.todayStartIso,
      'to': IsoDateRange.todayEndIso,
      'residenceId': residenceId,
    };

    final seriesQuery = <String, dynamic>{
      'metric': 'mar',
      'from': IsoDateRange.todayStartIso,
      'to': IsoDateRange.todayEndIso,
      'residenceId': residenceId,
    };

    // Overview + Due tab loads (all silent — page owns error UI):
    // - GET /mar/due (Due Today + Priority/Later/Completed)
    // - GET /mar/round (Morning/Afternoon/Evening)
    // - GET /mar/administrations missed|refused
    // - GET /reports/series?metric=mar
    final results = await Future.wait([
      _api.get(ApiEndpoints.marDue, query: dueQuery, silent: true),
      _api.get(ApiEndpoints.marRound, query: dueQuery, silent: true),
      _api.get(
        ApiEndpoints.marAdministrations,
        query: {'status': 'missed', ...dayScoped},
        silent: true,
      ),
      _api.get(
        ApiEndpoints.marAdministrations,
        query: {'status': 'refused', ...dayScoped},
        silent: true,
      ),
      _api.get(
        ApiEndpoints.reportsSeries,
        query: seriesQuery,
        silent: true,
      ),
    ]);

    final due = results[0];
    if (due.isFailure) {
      return Result.failure(
        due.error ??
            const ApiError(
              message:
                  'Could not load doses due for today. Check residence access and try again.',
            ),
      );
    }

    return Result.success(
      MedicationMapper.compose(
        dueBody: due.value,
        roundBody: results[1].isSuccess ? results[1].value : null,
        missedBody: results[2].isSuccess ? results[2].value : null,
        refusedBody: results[3].isSuccess ? results[3].value : null,
        seriesBody: results[4].isSuccess ? results[4].value : null,
        residenceName: residenceName,
      ),
    );
  }

  @override
  Future<Result<List<ClientMedicationItem>>> getClientMedications(
    String clientId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.medications,
      query: {'clientId': clientId, 'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        MedicationMapper.clientMedicationsFrom(body, isPrn: false),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ClientMedicationItem>>> getClientPrnMedications(
    String clientId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.prnMedications,
      query: {'clientId': clientId, 'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        MedicationMapper.clientMedicationsFrom(body, isPrn: true),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> reviewMedicationIssue({
    required String administrationId,
    required String title,
    required String description,
    String? clientId,
    String? residenceId,
    String severity = 'medium',
  }) async {
    final id = administrationId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing administration id.'),
      );
    }

    final resolvedResidence =
        (residenceId?.trim().isNotEmpty ?? false)
            ? residenceId!.trim()
            : (await _resolveResidence()).$1;

    final result = await _api.post(
      ApiEndpoints.complianceFindings,
      data: {
        'sourceType': 'mar_administration',
        'sourceId': id,
        'title': title.trim(),
        'description': description.trim(),
        'severity': severity,
        if (resolvedResidence != null && resolvedResidence.isNotEmpty)
          'residenceId': resolvedResidence,
        if (clientId != null && clientId.trim().isNotEmpty)
          'clientId': clientId.trim(),
      },
      silent: true,
      allowQueue: false,
    );

    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> logMedicationFollowUp({
    required String administrationId,
    required String title,
    required String description,
    String? clientId,
    String? residenceId,
  }) async {
    final id = administrationId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing administration id.'),
      );
    }

    final resolvedResidence =
        (residenceId?.trim().isNotEmpty ?? false)
            ? residenceId!.trim()
            : (await _resolveResidence()).$1;

    final payload = <String, dynamic>{
      'sourceType': 'mar_administration',
      'sourceId': id,
      'title': title.trim(),
      'description': description.trim(),
      'status': 'open',
      if (resolvedResidence != null && resolvedResidence.isNotEmpty)
        'residenceId': resolvedResidence,
      if (clientId != null && clientId.trim().isNotEmpty)
        'clientId': clientId.trim(),
    };

    final corrective = await _api.post(
      ApiEndpoints.complianceCorrectiveActions,
      data: payload,
      silent: true,
      allowQueue: false,
    );
    if (corrective.isSuccess) {
      return Result.success(null);
    }

    // Residence Manager often lacks compliance:write — fall back to a task.
    final task = await _api.post(
      ApiEndpoints.tasks,
      data: {
        'taskType': 'care',
        'title': title.trim(),
        'description': description.trim(),
        'priority': 'medium',
        'status': 'open',
        'requiresReview': false,
        if (resolvedResidence != null && resolvedResidence.isNotEmpty)
          'residenceId': resolvedResidence,
        if (clientId != null && clientId.trim().isNotEmpty)
          'clientId': clientId.trim(),
      },
      silent: true,
      allowQueue: false,
    );

    return task.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(
        corrective.error ?? error,
      ),
    );
  }

  @override
  Future<Result<List<int>>> exportMarCsv() async {
    final server = await _tryServerMarExport();
    if (server.isSuccess && (server.value?.isNotEmpty ?? false)) {
      return server;
    }
    return _buildMarCsvFromApi();
  }

  Future<Result<List<int>>> _tryServerMarExport() async {
    final create = await _api.post(
      ApiEndpoints.reportsExports,
      data: const {
        'reportKey': 'mar_administrations',
        'format': 'csv',
      },
      silent: true,
      allowQueue: false,
    );
    if (create.isFailure) {
      return Result.failure(
        create.error ??
            const ApiError(message: 'Could not create MAR export.'),
      );
    }

    final created = JsonCodec.unwrapMap(create.value);
    final exportId = JsonCodec.string(created['id']) ?? '';
    if (exportId.isEmpty) {
      return Result.failure(
        ApiError(message: 'Export was created but id was missing.'),
      );
    }

    var status = JsonCodec.stringOr(created['status'], 'queued').toLowerCase();
    for (var attempt = 0; attempt < 25 && status != 'ready'; attempt++) {
      if (status == 'failed') {
        return Result.failure(
          ApiError(message: 'The MAR export failed on the server.'),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final poll = await _api.get(
        ApiEndpoints.reportsExportById(exportId),
        silent: true,
      );
      if (poll.isFailure) {
        return Result.failure(
          poll.error ??
              const ApiError(message: 'Could not check export status.'),
        );
      }
      final map = JsonCodec.unwrapMap(poll.value);
      status = JsonCodec.stringOr(map['status'], status).toLowerCase();
      final fileUrl = JsonCodec.string(
        map['fileUrl'] ?? map['downloadUrl'] ?? map['signedUrl'],
      );
      if (status == 'ready') {
        return _downloadExportBytes(exportId, fileUrl);
      }
    }

    return Result.failure(
      ApiError(
        message:
            'Export is still running — it will appear on the Reports page when it finishes.',
      ),
    );
  }

  Future<Result<List<int>>> _downloadExportBytes(
    String exportId,
    String? preferredUrl,
  ) async {
    final preferred = (preferredUrl?.trim().isNotEmpty == true)
        ? preferredUrl!.trim()
        : ApiEndpoints.reportsExportDownload(exportId);
    final usesSignedToken = preferred.contains('token=');

    try {
      final headers = <String, dynamic>{
        'Accept': 'text/csv, application/octet-stream, */*',
      };
      if (!usesSignedToken) {
        final token = _tokens.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        final subdomain = _tenant.subdomain;
        if (subdomain != null && subdomain.isNotEmpty) {
          headers['X-Tenant-Subdomain'] = subdomain;
        }
      }

      final response = await Dio().get<List<int>>(
        _resolveExportUrl(preferred),
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
          validateStatus: (code) => code != null && code < 500,
        ),
      );
      final code = response.statusCode ?? 0;
      final bytes = response.data ?? const <int>[];
      if (code == 403) {
        return Result.failure(
          ApiError(message: 'Missing permission to download this export.'),
        );
      }
      if (code < 200 || code >= 300 || bytes.isEmpty) {
        return Result.failure(
          ApiError(message: 'Could not download the export file.'),
        );
      }
      return Result.success(bytes);
    } catch (_) {
      return Result.failure(
        ApiError(message: 'Could not download the export file.'),
      );
    }
  }

  Future<Result<List<int>>> _buildMarCsvFromApi() async {
    final residenceId = (await _resolveResidence()).$1;
    final result = await _api.get(
      ApiEndpoints.marAdministrations,
      query: {
        'page': 1,
        'limit': 500,
        if (residenceId != null && residenceId.isNotEmpty)
          'residenceId': residenceId,
      },
      silent: true,
    );
    if (result.isFailure) {
      return Result.failure(
        result.error ??
            const ApiError(message: 'Could not load MAR records for export.'),
      );
    }

    final rows = JsonCodec.unwrapList(result.value).whereType<Map>();
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Client,Medication,Dose,Status,Scheduled,Administered,Residence',
    );
    for (final raw in rows) {
      final json = JsonCodec.asMap(raw);
      final client = JsonCodec.mapAt(json, 'client') ?? const {};
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      final medication = JsonCodec.mapAt(json, 'medication') ?? const {};
      final id = JsonCodec.stringOr(json['id'], '');
      final shortId = id.length > 8 ? id.substring(0, 8) : id;
      final clientName = JsonCodec.stringOr(
        client['name'] ??
            client['displayName'] ??
            json['clientName'] ??
            '${JsonCodec.stringOr(client['firstName'], '')} ${JsonCodec.stringOr(client['lastName'], '')}'
                .trim(),
        '',
      );
      final medName = JsonCodec.stringOr(
        medication['name'] ?? json['medicationName'] ?? json['drugName'],
        '',
      );
      final dose = JsonCodec.stringOr(
        medication['dose'] ?? json['dose'] ?? json['dosage'],
        '',
      );
      final status = JsonCodec.stringOr(json['status'], '');
      final scheduled = JsonCodec.stringOr(
        json['scheduledAt'] ?? json['dueAt'] ?? json['scheduledFor'],
        '',
      );
      final administered = JsonCodec.stringOr(
        json['administeredAt'] ?? json['givenAt'],
        '',
      );
      final residenceName = JsonCodec.stringOr(
        residence['name'] ?? json['residenceName'],
        '',
      );
      buffer.writeln(
        [
          _csvCell('#$shortId'),
          _csvCell(clientName),
          _csvCell(medName),
          _csvCell(dose),
          _csvCell(status),
          _csvCell(scheduled),
          _csvCell(administered),
          _csvCell(residenceName),
        ].join(','),
      );
    }

    return Result.success(utf8.encode(buffer.toString()));
  }

  static String _csvCell(String value) {
    final text = value.replaceAll('\r\n', ' ').replaceAll('\n', ' ').trim();
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  static String _resolveExportUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.startsWith('/api/v1/')) {
      final origin = base.replaceAll(RegExp(r'/api/v1$'), '');
      return '$origin$trimmed';
    }
    if (trimmed.startsWith('/')) {
      if (trimmed.startsWith('/reports/')) {
        return '$base$trimmed';
      }
      return '${Uri.parse(base).origin}$trimmed';
    }
    return '$base/$trimmed';
  }

  Future<(String?, String?)> _resolveResidence() async {
    final sessionId = _session.residenceId?.trim();
    final sessionName = _session.residenceName?.trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      return (sessionId, sessionName);
    }

    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 50},
      silent: true,
    );
    if (result.isFailure) return (null, null);

    final rows = JsonCodec.unwrapList(result.value);
    for (final row in rows) {
      if (row is! Map) continue;
      final map = JsonCodec.asMap(row);
      final id = JsonCodec.string(map['id'] ?? map['residenceId'])?.trim();
      if (id == null || id.isEmpty) continue;
      final name = JsonCodec.string(map['name'] ?? map['residenceName']);
      _session.applyStaffContext(residenceId: id, residenceName: name);
      return (id, name);
    }
    return (null, null);
  }
}
