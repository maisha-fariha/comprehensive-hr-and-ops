import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/network/tenant_store.dart';
import '../../../../../core/network/token_store.dart';
import '../../domain/entities/hr_appointment.dart';
import '../../domain/repositories/hr_appointments_repository.dart';
import '../hr_appointments_endpoints.dart';
import '../mappers/hr_appointments_mapper.dart';

class HrAppointmentsRepositoryImpl implements HrAppointmentsRepository {
  final AppApiClient _api;
  final TokenStore? _tokens;
  final TenantStore? _tenant;
  final Duration _pollInterval;

  HrAppointmentsRepositoryImpl({
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

  Future<Result<void>> _post(String path, Map<String, dynamic> data) async =>
      _done(await _api.post(path, data: data, silent: true, allowQueue: false));

  static String? _iso(DateTime? value) => value?.toUtc().toIso8601String();

  @override
  Future<Result<HrAppointmentPage>> list(HrAppointmentQuery query) async {
    String? blank(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final result = await _api.get(
      HrAppointmentsEndpoints.appointments,
      query: {
        'page': query.page,
        'limit': query.limit,
        'status': ?blank(query.status),
        'type': ?blank(query.type),
        'residenceId': ?blank(query.residenceId),
        'search': ?blank(query.search),
      },
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(HrAppointmentsMapper.pageFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<HrAppointmentSummary>> summary() async {
    final result = await _api.get(HrAppointmentsEndpoints.summary, silent: true);
    return result.when(
      success: (body) => Result.success(HrAppointmentsMapper.summaryFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> create(HrAppointmentInput input) =>
      _post(HrAppointmentsEndpoints.appointments, {
        'type': input.type,
        'clientId': input.clientId,
        'residenceId': ?input.residenceId,
        'scheduledAt': ?_iso(input.scheduledAt),
        'location': ?input.location,
        'purpose': ?input.purpose,
        'notes': ?input.notes,
      });

  @override
  Future<Result<void>> reschedule(String id, HrAppointmentInput input) =>
      _post(HrAppointmentsEndpoints.reschedule(id), {
        'scheduledAt': ?_iso(input.scheduledAt),
        'location': ?input.location,
        'purpose': ?input.purpose,
        'notes': ?input.notes,
      });

  @override
  Future<Result<void>> update(String id, HrAppointmentInput input) async => _done(
        await _api.patch(
          HrAppointmentsEndpoints.byId(id),
          data: {
            'scheduledAt': ?_iso(input.scheduledAt),
            'location': input.location,
            'purpose': input.purpose,
            'notes': input.notes,
          },
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> approve(String id) =>
      _post(HrAppointmentsEndpoints.approve(id), const {});

  @override
  Future<Result<void>> reject(String id, {String? reason}) =>
      _post(HrAppointmentsEndpoints.reject(id), {'reason': ?reason});

  @override
  Future<Result<void>> cancel(String id, {String? reason}) =>
      _post(HrAppointmentsEndpoints.cancel(id), {'reason': ?reason});

  @override
  Future<Result<void>> delete(String id) async => _done(
        await _api.delete(
          HrAppointmentsEndpoints.byId(id),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<List<HrAppointmentOption>>> residences() async {
    final result = await _api.get(
      HrAppointmentsEndpoints.residences,
      query: const {'page': 1, 'limit': HrAppointmentsEndpoints.maxPageLimit},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(HrAppointmentsMapper.residencesFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<HrAppointmentClient>>> clients() async {
    final result = await _api.get(
      HrAppointmentsEndpoints.clients,
      query: const {'page': 1, 'limit': HrAppointmentsEndpoints.maxPageLimit},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(HrAppointmentsMapper.clientsFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<HrAppointmentLogNote>>> dayLog({
    required String clientId,
    required String residenceId,
    required String logDate,
  }) async {
    final result = await _api.get(
      HrAppointmentsEndpoints.dailyLogs,
      query: {'clientId': clientId, 'residenceId': residenceId, 'logDate': logDate},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(HrAppointmentsMapper.dayLogFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<int>>> exportCsv() async {
    final server = await _serverExport();
    if (server.isSuccess && (server.value?.isNotEmpty ?? false)) return server;
    return _localExport();
  }

  /// The web flow: create the export, poll it, then download. Manager roles
  /// without `reports:read` get 403 on the poll and fall back to [_localExport].
  Future<Result<List<int>>> _serverExport() async {
    final create = await _api.post(
      HrAppointmentsEndpoints.reportExports,
      data: const {'reportKey': 'appointment_log', 'format': 'csv'},
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
      return Result.failure(const ApiError(message: 'The export has no id.'));
    }
    var status = JsonCodec.stringOr(created['status'], 'queued').toLowerCase();
    for (var attempt = 0; attempt < 25 && status != 'ready'; attempt++) {
      if (status == 'failed') {
        return Result.failure(
          const ApiError(message: 'The export failed on the server.'),
        );
      }
      await Future<void>.delayed(_pollInterval);
      final poll = await _api.get(
        HrAppointmentsEndpoints.reportExport(exportId),
        silent: true,
      );
      if (poll.isFailure) {
        return Result.failure(
          poll.error ?? const ApiError(message: 'Could not check the export.'),
        );
      }
      status = JsonCodec.stringOr(
        JsonCodec.unwrapMap(poll.value)['status'],
        status,
      ).toLowerCase();
    }
    if (status != 'ready') {
      return Result.failure(
        const ApiError(
          message:
              'Export is still running — it will appear on the Reports page when it finishes.',
        ),
      );
    }
    return _download(HrAppointmentsEndpoints.reportExportDownload(exportId));
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
            if (subdomain != null && subdomain.isNotEmpty)
              'X-Tenant-Subdomain': subdomain,
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

  /// Every page of `GET /appointments`, written with the table's columns.
  Future<Result<List<int>>> _localExport() async {
    final rows = <HrAppointment>[];
    var page = 1;
    var totalPages = 1;
    do {
      final result = await list(
        HrAppointmentQuery(page: page, limit: HrAppointmentsEndpoints.maxPageLimit),
      );
      if (result.isFailure) {
        return Result.failure(
          result.error ??
              const ApiError(message: 'Could not load appointments for export.'),
        );
      }
      final data = result.value!;
      rows.addAll(data.items);
      totalPages = data.totalPages;
      page++;
    } while (page <= totalPages && page <= 50);
    return Result.success(utf8.encode(HrAppointmentsMapper.csvFrom(rows)));
  }
}
