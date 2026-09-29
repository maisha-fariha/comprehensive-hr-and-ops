import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/network/tenant_store.dart';
import '../../../../../core/network/token_store.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/incident_category_option.dart';
import '../../domain/entities/incident_cir_template_option.dart';
import '../../domain/entities/incident_client_option.dart';
import '../../domain/entities/incident_evidence_file.dart';
import '../../domain/entities/incident_investigation_summary.dart';
import '../../domain/entities/incident_residence_option.dart';
import '../../domain/entities/incident_staff_option.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/repositories/incidents_repository.dart';
import '../mappers/incidents_mapper.dart';

class IncidentsRepositoryImpl implements IncidentsRepository {
  final AppApiClient _api;
  final UserSession _session;
  final TokenStore _tokens;
  final TenantStore _tenant;

  IncidentsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
    required TokenStore tokens,
    required TenantStore tenant,
  })  : _api = api,
        _session = session,
        _tokens = tokens,
        _tenant = tenant;

  @override
  Future<Result<IncidentsBoard>> getBoard() async {
    final residenceId = _session.residenceId;
    final base = <String, dynamic>{
      'page': 1,
      'limit': 100,
      'residenceId': ?residenceId,
    };

    final incidents = await Future.wait([
      _api.get(
        ApiEndpoints.incidents,
        query: {...base, 'status': 'open'},
      ),
      _api.get(
        ApiEndpoints.incidents,
        query: {
          ...base,
          'status': 'under_review,in_review,investigating,assigned',
        },
      ),
      _api.get(
        ApiEndpoints.incidents,
        query: {...base, 'status': 'closed,resolved,archived'},
      ),
      _api.get(ApiEndpoints.incidentsSummary),
    ]);

    final open = incidents[0];
    final review = incidents[1];
    final closed = incidents[2];
    final summary = incidents[3];

    if (open.isFailure && review.isFailure && closed.isFailure) {
      return Result.failure(
        open.error ??
            const ApiError(message: 'Could not load incidents.'),
      );
    }

    if (summary.isFailure) {
      return Result.failure(
        summary.error ??
            const ApiError(message: 'Could not load incident summary.'),
      );
    }

    return Result.success(
      IncidentsMapper.composeSections(
        openBody: open.isSuccess ? open.value : null,
        reviewBody: review.isSuccess ? review.value : null,
        closedBody: closed.isSuccess ? closed.value : null,
        summaryBody: summary.value,
      ),
    );
  }

  @override
  Future<Result<IncidentInvestigationSummary>> getInvestigationSummary(
    String incidentId,
  ) async {
    final result = await _api.get(ApiEndpoints.incidentById(incidentId));
    return result.when(
      success: (body) async =>
          Result.success(IncidentsMapper.investigationSummaryFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getIncidentDetail(
    String incidentId,
  ) async {
    final result = await _api.get(ApiEndpoints.incidentById(incidentId));
    return result.when(
      success: (body) async => Result.success(JsonCodec.unwrapMap(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String>> getCirPdfLink(String incidentId) async {
    final result = await _api.get(ApiEndpoints.incidentCirPdfLink(incidentId));
    return result.when(
      success: (body) async {
        final map = JsonCodec.unwrapMap(body);
        final url = JsonCodec.string(
          map['signedUrl'] ?? map['url'] ?? map['fileUrl'],
        );
        if (url == null || url.isEmpty) {
          return Result.failure(
            const ApiError(message: 'No CIR PDF link was returned.'),
          );
        }
        return Result.success(_resolvePdfUrl(url));
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<int>>> downloadCirPdf(String incidentId) async {
    final linkResult = await _api.get(
      ApiEndpoints.incidentCirPdfLink(incidentId),
      silent: true,
    );

    String? signedUrl;
    String? plainUrl;
    if (linkResult.isSuccess) {
      final map = JsonCodec.unwrapMap(linkResult.value);
      signedUrl = JsonCodec.string(map['signedUrl']);
      plainUrl = JsonCodec.string(map['url'] ?? map['fileUrl']);
    }

    final preferred = (signedUrl != null && signedUrl.isNotEmpty)
        ? signedUrl
        : (plainUrl != null && plainUrl.isNotEmpty)
            ? plainUrl
            : ApiEndpoints.incidentCirPdf(incidentId);
    final usesSignedToken = signedUrl != null &&
        signedUrl.isNotEmpty &&
        preferred == signedUrl;

    try {
      final headers = <String, dynamic>{
        'Accept': 'application/pdf',
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
        _resolvePdfUrl(preferred),
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final status = response.statusCode ?? 0;
      final bytes = response.data ?? const <int>[];

      if (status == 400 || status == 404 || status == 422) {
        return Result.failure(
          ApiError(
            message: _pdfErrorMessage(bytes) ??
                'No CIR PDF is available for this incident.',
          ),
        );
      }

      if (status < 200 || status >= 300 || bytes.isEmpty) {
        return Result.failure(
          ApiError(
            message: _pdfErrorMessage(bytes) ??
                'Could not download the CIR PDF.',
          ),
        );
      }

      if (!_looksLikePdf(bytes)) {
        return Result.failure(
          ApiError(
            message: _pdfErrorMessage(bytes) ??
                'No CIR PDF is available for this incident.',
          ),
        );
      }

      return Result.success(bytes);
    } on DioException catch (error) {
      return Result.failure(
        ApiError(
          message: error.message ?? 'Could not download the CIR PDF.',
        ),
      );
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Could not download the CIR PDF.'),
      );
    }
  }

  static String _resolvePdfUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.startsWith('/api/v1/')) {
      final origin = base.replaceAll(RegExp(r'/api/v1/?$'), '');
      return '$origin$trimmed';
    }
    // API-relative paths must keep the /api/v1 prefix.
    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    return '$base/$trimmed';
  }

  static bool _looksLikePdf(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46; // %PDF
  }

  static String? _pdfErrorMessage(List<int> bytes) {
    try {
      final text = String.fromCharCodes(bytes);
      final decoded = jsonDecode(text);
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

  @override
  Future<Result<List<IncidentCategoryOption>>> getCategories() async {
    final result = await _api.get(
      ApiEndpoints.incidentCategories,
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(IncidentsMapper.categoriesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<IncidentCirTemplateOption>>> getCirTemplates() async {
    final result = await _api.get(
      ApiEndpoints.incidentCirTemplates,
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(IncidentsMapper.cirTemplatesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<IncidentResidenceOption>>> getResidences() async {
    final result = await _api.get(
      ApiEndpoints.residences,
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(IncidentsMapper.residencesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<IncidentStaffOption>>> getStaff() async {
    final result = await _api.get(
      ApiEndpoints.staff,
      query: {
        'page': 1,
        'limit': 100,
        'residenceId': ?_session.residenceId,
      },
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(IncidentsMapper.staffFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<IncidentClientOption>>> searchClients(String search) async {
    final trimmed = search.trim();
    if (trimmed.isEmpty) {
      return Result.success(<IncidentClientOption>[]);
    }

    final result = await _api.get(
      ApiEndpoints.clients,
      query: {
        'search': trimmed,
        'page': 1,
        'limit': 20,
        'residenceId': ?_session.residenceId,
      },
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(IncidentsMapper.clientsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String>> createIncident({
    required String residenceId,
    required String clientId,
    required String categoryId,
    required String title,
    required String severity,
    required Map<String, dynamic> payload,
    String? cirTemplateId,
    String status = 'open',
    String? reportedAt,
    bool residentChecked = false,
    bool supervisorNotified = false,
    bool familyNotified = false,
    bool carePlanReviewed = false,
  }) async {
    final data = <String, dynamic>{
      'residenceId': residenceId,
      'clientId': clientId,
      'categoryId': categoryId,
      'title': title,
      'severity': severity,
      'payload': payload,
      'status': status,
      'residentChecked': residentChecked,
      'supervisorNotified': supervisorNotified,
      'familyNotified': familyNotified,
      'carePlanReviewed': carePlanReviewed,
      if (cirTemplateId != null && cirTemplateId.isNotEmpty)
        'cirTemplateId': cirTemplateId,
      if (reportedAt != null && reportedAt.isNotEmpty) 'reportedAt': reportedAt,
    };

    final result = await _api.post(
      ApiEndpoints.incidents,
      data: data,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final id = _extractId(body);
        if (id == null || id.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Incident created but id was missing.'),
          );
        }
        return Result.success(id);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> updateIncident({
    required String incidentId,
    required String residenceId,
    required String clientId,
    required String categoryId,
    required String title,
    required String severity,
    required Map<String, dynamic> payload,
    String? cirTemplateId,
    String? status,
    String? reportedAt,
    bool residentChecked = false,
    bool supervisorNotified = false,
    bool familyNotified = false,
    bool carePlanReviewed = false,
  }) async {
    final data = <String, dynamic>{
      'residenceId': residenceId,
      'clientId': clientId,
      'categoryId': categoryId,
      'title': title,
      'severity': severity,
      'payload': payload,
      'residentChecked': residentChecked,
      'supervisorNotified': supervisorNotified,
      'familyNotified': familyNotified,
      'carePlanReviewed': carePlanReviewed,
      if (status != null && status.isNotEmpty) 'status': status,
      if (cirTemplateId != null && cirTemplateId.isNotEmpty)
        'cirTemplateId': cirTemplateId,
      if (reportedAt != null && reportedAt.isNotEmpty) 'reportedAt': reportedAt,
    };

    final result = await _api.patch(
      ApiEndpoints.incidentById(incidentId),
      data: data,
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<IncidentEvidenceFile>> uploadEvidenceFile(
    IncidentEvidenceFile file,
  ) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.localPath,
          filename: file.fileName,
        ),
      });

      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: const {'category': 'documents'},
        allowQueue: false,
      );

      return result.when(
        success: (body) async {
          final map = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(
            map['fileUrl'] ?? map['url'] ?? map['publicUrl'],
          );
          if (url == null || url.isEmpty) {
            return Result.failure(
              const ApiError(message: 'Upload succeeded but file URL was missing.'),
            );
          }
          return Result.success(
            file.copyWith(
              fileUrl: url,
              isUploading: false,
              clearError: true,
            ),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    } catch (error) {
      return Result.failure(
        ApiError(message: 'Could not upload ${file.fileName}: $error'),
      );
    }
  }

  @override
  Future<Result<void>> attachEvidence({
    required String incidentId,
    required String fileUrl,
    required String fileType,
  }) async {
    final result = await _api.post(
      ApiEndpoints.incidentEvidence(incidentId),
      data: {
        'fileUrl': fileUrl,
        'fileType': fileType,
      },
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> recordInvestigation({
    required String incidentId,
    required String findings,
    String? rootCause,
    String? correctiveActions,
    String status = 'open',
  }) async {
    final result = await _api.patch(
      ApiEndpoints.incidentInvestigation(incidentId),
      data: {
        'findings': findings,
        if (rootCause != null && rootCause.isNotEmpty) 'rootCause': rootCause,
        if (correctiveActions != null && correctiveActions.isNotEmpty)
          'correctiveActions': correctiveActions,
        'status': status,
      },
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<int>>> exportIncidentListCsv() async {
    final server = await _tryServerIncidentLogExport();
    if (server.isSuccess && (server.value?.isNotEmpty ?? false)) {
      return server;
    }
    return _buildIncidentListCsvFromApi();
  }

  /// Web path: `POST /reports/exports` with `reportKey: incident_log`, poll,
  /// then download. Many manager roles can create but lack `reports:read` for
  /// status/download — those callers fall back to [_buildIncidentListCsvFromApi].
  Future<Result<List<int>>> _tryServerIncidentLogExport() async {
    final create = await _api.post(
      ApiEndpoints.reportsExports,
      data: const {
        'reportKey': 'incident_log',
        'format': 'csv',
      },
      silent: true,
      allowQueue: false,
    );
    if (create.isFailure) {
      return Result.failure(
        create.error ??
            const ApiError(message: 'Could not create incident export.'),
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
          ApiError(message: 'The export failed on the server.'),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final poll = await _api.get(
        ApiEndpoints.reportsExportById(exportId),
        silent: true,
      );
      if (poll.isFailure) {
        // Typical for residence_manager: create OK, GET status FORBIDDEN.
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

  Future<Result<List<int>>> _buildIncidentListCsvFromApi() async {
    final residenceId = _session.residenceId;
    final result = await _api.get(
      ApiEndpoints.incidents,
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
            const ApiError(message: 'Could not load incidents for export.'),
      );
    }

    final rows = JsonCodec.unwrapList(result.value).whereType<Map>();
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Incident,Client,Residence,Severity,Reported,Status',
    );
    for (final raw in rows) {
      final json = JsonCodec.asMap(raw);
      final client = JsonCodec.mapAt(json, 'client') ?? const {};
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      final category = JsonCodec.mapAt(json, 'category') ?? const {};
      final id = JsonCodec.stringOr(json['id'], '');
      final shortId = id.length > 8 ? id.substring(0, 8) : id;
      final title = JsonCodec.stringOr(
        json['title'],
        JsonCodec.stringOr(category['name'], 'Incident'),
      );
      final clientName = JsonCodec.stringOr(
        client['name'] ??
            client['displayName'] ??
            '${JsonCodec.stringOr(client['firstName'], '')} ${JsonCodec.stringOr(client['lastName'], '')}'
                .trim(),
        '',
      );
      final residenceName = JsonCodec.stringOr(
        residence['name'] ?? residence['title'],
        '',
      );
      final severity = JsonCodec.stringOr(
        json['severity'] ?? category['severity'],
        '',
      );
      final reportedAt = JsonCodec.stringOr(
        json['reportedAt'] ?? json['createdAt'],
        '',
      );
      final status = JsonCodec.stringOr(json['status'], '');
      buffer.writeln(
        [
          _csvCell('#$shortId'),
          _csvCell(title),
          _csvCell(clientName),
          _csvCell(residenceName),
          _csvCell(severity),
          _csvCell(reportedAt),
          _csvCell(status),
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

  String? _extractId(dynamic body) {
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      if (data is Map) {
        return data['id']?.toString() ?? data['incidentId']?.toString();
      }
      return map['id']?.toString() ?? map['incidentId']?.toString();
    }
    return null;
  }
}
