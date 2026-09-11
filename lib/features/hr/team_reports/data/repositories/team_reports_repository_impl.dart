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
import '../../domain/entities/report_export_item.dart';
import '../../domain/entities/team_reports_page_data.dart';
import '../../domain/entities/team_staff_profile.dart';
import '../../domain/repositories/team_reports_repository.dart';
import '../mappers/team_reports_mapper.dart';

class TeamReportsRepositoryImpl implements TeamReportsRepository {
  final AppApiClient _api;
  final UserSession _session;
  final TokenStore _tokens;
  final TenantStore _tenant;

  static const _seriesMetrics = ['attendance', 'incidents', 'mar', 'payroll'];

  TeamReportsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
    required TokenStore tokens,
    required TenantStore tenant,
  })  : _api = api,
        _session = session,
        _tokens = tokens,
        _tenant = tenant;

  Map<String, dynamic> get _residenceQuery {
    final residenceId = _session.residenceId;
    return {
      if (residenceId != null && residenceId.isNotEmpty) 'residenceId': residenceId,
    };
  }

  Map<String, dynamic> get _rangeQuery => {
        'from': IsoDateRange.daysAgoStartIso(30),
        'to': IsoDateRange.nowIso,
        ..._residenceQuery,
      };

  @override
  Future<Result<TeamReportsPageData>> getPageData() async {
    final residenceQuery = _residenceQuery;

    // Team tab — Total Staff
    var staffResult = await _api.get(
      ApiEndpoints.staff,
      query: {'page': 1, 'limit': 20, ...residenceQuery},
      silent: true,
    );
    if (staffResult.isFailure) {
      staffResult = await _api.get(
        ApiEndpoints.staffDirectory,
        query: residenceQuery,
        silent: true,
      );
    }
    if (staffResult.isFailure) {
      return Result.failure(
        staffResult.error ??
            const ApiError(message: 'Could not load the team directory.'),
      );
    }

    final range = _rangeQuery;
    final extras = await Future.wait([
      // Team — On Duty Now
      _api.get(
        ApiEndpoints.attendance,
        query: {
          'status': 'present',
          'from': IsoDateRange.todayStartIso,
          'to': IsoDateRange.nowIso,
          ...residenceQuery,
        },
        silent: true,
      ),
      // Team — Open Shifts / Vacancies
      _api.get(
        ApiEndpoints.shifts,
        query: {'status': 'open', ...residenceQuery},
        silent: true,
      ),
      // Reports — Available Reports list + Team Top Reports
      _api.get(ApiEndpoints.reportsSummary, query: range, silent: true),
      // Reports — KPI counters
      _api.get(ApiEndpoints.reportsKpis, query: range, silent: true),
      // Team / Messages — conversations
      _api.get(
        ApiEndpoints.conversations,
        query: const {'page': 1, 'limit': 50},
        silent: true,
      ),
      // Reports — Analytics view
      _api.get(ApiEndpoints.reportsAnalytics, query: range, silent: true),
      // Reports — Export list
      _api.get(ApiEndpoints.reportsExports, silent: true),
      // Documents tab
      _api.get(
        ApiEndpoints.documents,
        query: const {'page': 1, 'limit': 20},
        silent: true,
      ),
      _api.get(ApiEndpoints.documentsSummary, silent: true),
      _api.get(ApiEndpoints.documentTypes, silent: true),
      // Messages — Important Announcements
      _api.get(
        ApiEndpoints.notifications,
        query: const {'page': 1, 'limit': 20},
        silent: true,
      ),
      // Report Insights — one series call per allowed metric
      for (final metric in _seriesMetrics)
        _api.get(
          ApiEndpoints.reportsSeries,
          query: {
            'metric': metric,
            'from': range['from'],
            'to': range['to'],
            ...residenceQuery,
          },
          silent: true,
        ),
    ]);

    if (extras[2].isFailure && extras[3].isFailure) {
      return Result.failure(
        extras[2].error ??
            extras[3].error ??
            const ApiError(message: 'Could not load team reports.'),
      );
    }

    final seriesBodies = <String, dynamic>{};
    for (var i = 0; i < _seriesMetrics.length; i++) {
      final result = extras[11 + i];
      if (result.isSuccess) {
        seriesBodies[_seriesMetrics[i]] = result.value;
      }
    }

    return Result.success(
      TeamReportsMapper.compose(
        staffBody: staffResult.value,
        onDutyBody: extras[0].isSuccess ? extras[0].value : null,
        openShiftsBody: extras[1].isSuccess ? extras[1].value : null,
        summaryBody: extras[2].isSuccess ? extras[2].value : null,
        kpisBody: extras[3].isSuccess ? extras[3].value : null,
        conversationsBody: extras[4].isSuccess ? extras[4].value : null,
        analyticsBody: extras[5].isSuccess ? extras[5].value : null,
        exportsBody: extras[6].isSuccess ? extras[6].value : null,
        documentsBody: extras[7].isSuccess ? extras[7].value : null,
        documentsSummaryBody: extras[8].isSuccess ? extras[8].value : null,
        documentTypesBody: extras[9].isSuccess ? extras[9].value : null,
        notificationsBody: extras[10].isSuccess ? extras[10].value : null,
        seriesBodies: seriesBodies,
      ),
    );
  }

  @override
  Future<Result<TeamStaffProfile>> getStaffProfile(String staffId) async {
    final id = staffId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing staff id.'),
      );
    }

    final detail = await _api.get(ApiEndpoints.staffById(id), silent: true);
    if (detail.isFailure) {
      return Result.failure(
        detail.error ??
            const ApiError(message: 'Could not load staff profile.'),
      );
    }

    final docs = await _api.get(ApiEndpoints.staffDocuments(id), silent: true);
    return Result.success(
      TeamReportsMapper.staffProfileFrom(
        detailBody: detail.value,
        documentsBody: docs.isSuccess ? docs.value : null,
      ),
    );
  }

  @override
  Future<Result<List<TeamStaffDocument>>> getStaffDocuments(String staffId) async {
    final id = staffId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing staff id.'),
      );
    }
    final result = await _api.get(ApiEndpoints.staffDocuments(id), silent: true);
    return result.when(
      success: (body) async =>
          Result.success(TeamReportsMapper.staffDocumentsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<ReportExportItem>> createExport({
    required String reportKey,
    String format = 'csv',
  }) async {
    final key = reportKey.trim();
    if (key.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing report key.'),
      );
    }

    final result = await _api.post(
      ApiEndpoints.reportsExports,
      data: {
        'reportKey': key,
        'format': format,
        'filters': _rangeQuery,
      },
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(TeamReportsMapper.exportFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<ReportExportItem>> getExportStatus(String exportId) async {
    final id = exportId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing export id.'),
      );
    }
    final result = await _api.get(
      ApiEndpoints.reportsExportById(id),
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(TeamReportsMapper.exportFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<int>>> downloadExportFile(String exportId) async {
    final status = await getExportStatus(exportId);
    if (status.isFailure) {
      return Result.failure(status.error!);
    }
    final item = status.value!;
    if (!item.isReady) {
      return Result.failure(
        const ApiError(
          message: 'Export is still processing. Try again in a moment.',
        ),
      );
    }

    final preferred = (item.downloadUrl?.trim().isNotEmpty == true)
        ? item.downloadUrl!.trim()
        : ApiEndpoints.reportsExportDownload(item.id);

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

      if (code == 400) {
        return Result.failure(
          ApiError(
            message: _exportErrorMessage(bytes) ??
                'Export is processing, not ready yet.',
          ),
        );
      }
      if (code == 403) {
        return Result.failure(
          ApiError(
            message: _exportErrorMessage(bytes) ??
                'Missing permission to download this export.',
          ),
        );
      }
      if (code == 404) {
        return Result.failure(
          ApiError(
            message: _exportErrorMessage(bytes) ??
                'Export file was not found.',
          ),
        );
      }
      if (code < 200 || code >= 300 || bytes.isEmpty) {
        return Result.failure(
          ApiError(
            message: _exportErrorMessage(bytes) ??
                'Could not download the export file.',
          ),
        );
      }

      // Reject JSON error envelopes that slipped through with 200.
      if (_looksLikeJsonError(bytes)) {
        return Result.failure(
          ApiError(
            message: _exportErrorMessage(bytes) ??
                'Could not download the export file.',
          ),
        );
      }

      return Result.success(bytes);
    } on DioException catch (error) {
      return Result.failure(
        ApiError(
          message: error.message ?? 'Could not download the export file.',
        ),
      );
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Could not download the export file.'),
      );
    }
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
      // API-relative routes need the /api/v1 base; storage paths use origin.
      if (trimmed.startsWith('/reports/')) {
        return '$base$trimmed';
      }
      return '${Uri.parse(base).origin}$trimmed';
    }
    return '$base/$trimmed';
  }

  static bool _looksLikeJsonError(List<int> bytes) {
    if (bytes.isEmpty) return false;
    final first = bytes[0];
    if (first != 0x7B && first != 0x5B) return false; // { or [
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) return false;
      final map = JsonCodec.asMap(decoded);
      return map['success'] == false || map['error'] != null;
    } catch (_) {
      return false;
    }
  }

  static String? _exportErrorMessage(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      final map = JsonCodec.asMap(decoded);
      final nested = map['error'];
      return JsonCodec.string(
        map['message'] ??
            (nested is Map ? nested['message'] : null),
      );
    } catch (_) {
      return null;
    }
  }
}
