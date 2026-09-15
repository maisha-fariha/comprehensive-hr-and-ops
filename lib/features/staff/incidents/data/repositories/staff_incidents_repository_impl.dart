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
import '../../domain/entities/incident_detail.dart';
import '../../domain/entities/staff_incident.dart';
import '../../domain/entities/staff_incident_options.dart';
import '../../domain/entities/staff_incidents_summary.dart';
import '../../domain/repositories/staff_incidents_repository.dart';
import '../mappers/staff_incidents_mapper.dart';

class StaffIncidentsRepositoryImpl implements StaffIncidentsRepository {
  final AppApiClient _api;
  final UserSession _session;
  final TokenStore _tokens;
  final TenantStore _tenant;

  StaffIncidentsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
    required TokenStore tokens,
    required TenantStore tenant,
  })  : _api = api,
        _session = session,
        _tokens = tokens,
        _tenant = tenant;

  @override
  Future<Result<List<StaffIncident>>> getIncidents({
    bool mine = false,
    String? search,
    String? severity,
    String? status,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _api.get(
      ApiEndpoints.incidents,
      query: {
        'page': page,
        'limit': limit,
        'residenceId': ?_session.residenceId,
        if (mine) 'reporter': 'me',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (severity != null && severity.isNotEmpty) 'severity': severity,
        if (status != null && status.isNotEmpty) 'status': status,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffIncidentsMapper.listFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffIncidentsSummary>> getSummary() async {
    final result = await _api.get(
      ApiEndpoints.incidentsSummary,
      query: {
        'residenceId': ?_session.residenceId,
      },
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffIncidentsMapper.summaryFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<IncidentDetail>> getIncidentDetail(String incidentId) async {
    final results = await Future.wait([
      _api.get(ApiEndpoints.incidentById(incidentId)),
      _api.get(ApiEndpoints.incidentActivity(incidentId)),
    ]);
    if (results[0].isFailure) {
      return Result.failure(
        results[0].error ??
            const ApiError(message: 'Could not load this incident.'),
      );
    }
    final detail = StaffIncidentsMapper.detailFrom(results[0].value);
    if (results[1].isFailure) return Result.success(detail);
    final activity = StaffIncidentsMapper.activityFrom(results[1].value);
    return Result.success(
      detail.copyWith(activity: activity.isEmpty ? detail.activity : activity),
    );
  }

  @override
  Future<Result<void>> acknowledge(String incidentId) async {
    final result = await _api.post(
      ApiEndpoints.incidentAcknowledge(incidentId),
      data: {},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> addInvestigationNote({
    required String incidentId,
    required String notes,
  }) async {
    final result = await _api.patch(
      ApiEndpoints.incidentInvestigation(incidentId),
      data: {'notes': notes, 'comment': notes},
    );
    return result.when(
      success: (_) async => Result.success(null),
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
        return Result.success(_resolveFileUrl(url));
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

    return _downloadBytes(
      preferred,
      authUnlessSigned: !usesSignedToken,
      emptyMessage: 'No CIR PDF is available for this incident.',
      failureMessage: 'Could not download the CIR PDF.',
      requirePdf: true,
    );
  }

  @override
  Future<Result<List<int>>> downloadFileBytes(String fileUrl) async {
    final trimmed = fileUrl.trim();
    if (trimmed.isEmpty) {
      return Result.failure(const ApiError(message: 'File URL was missing.'));
    }
    final isAbsolute =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final looksSigned =
        isAbsolute && (trimmed.contains('X-Amz-') || trimmed.contains('Signature='));
    return _downloadBytes(
      trimmed,
      authUnlessSigned: !looksSigned,
      emptyMessage: 'Could not download this file.',
      failureMessage: 'Could not download this file.',
      requirePdf: false,
    );
  }

  Future<Result<List<int>>> _downloadBytes(
    String urlOrPath, {
    required bool authUnlessSigned,
    required String emptyMessage,
    required String failureMessage,
    required bool requirePdf,
  }) async {
    try {
      final headers = <String, dynamic>{
        'Accept': requirePdf ? 'application/pdf' : '*/*',
      };
      if (authUnlessSigned) {
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
        _resolveFileUrl(urlOrPath),
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
          ApiError(message: _bytesErrorMessage(bytes) ?? emptyMessage),
        );
      }

      if (status < 200 || status >= 300 || bytes.isEmpty) {
        return Result.failure(
          ApiError(message: _bytesErrorMessage(bytes) ?? failureMessage),
        );
      }

      if (requirePdf && !_looksLikePdf(bytes)) {
        return Result.failure(
          ApiError(message: _bytesErrorMessage(bytes) ?? emptyMessage),
        );
      }

      return Result.success(bytes);
    } on DioException catch (error) {
      return Result.failure(
        ApiError(message: error.message ?? failureMessage),
      );
    } catch (_) {
      return Result.failure(ApiError(message: failureMessage));
    }
  }

  static String _resolveFileUrl(String url) {
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
      return '${Uri.parse(base).origin}$trimmed';
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

  static String? _bytesErrorMessage(List<int> bytes) {
    try {
      final text = String.fromCharCodes(bytes);
      final decoded = jsonDecode(text);
      final map = JsonCodec.asMap(decoded);
      final nested = map['error'];
      return JsonCodec.string(
        map['message'] ?? (nested is Map ? nested['message'] : null),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<List<StaffIncidentCategoryOption>>> getCategories() async {
    final result = await _api.get(ApiEndpoints.incidentCategories);
    return result.when(
      success: (body) async =>
          Result.success(StaffIncidentsMapper.categoriesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffCirTemplateOption>>> getCirTemplates() async {
    final result = await _api.get(ApiEndpoints.incidentCirTemplates);
    return result.when(
      success: (body) async =>
          Result.success(StaffIncidentsMapper.cirTemplatesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffIncidentClientOption>>> getClients({
    String? search,
    bool assignedToMe = true,
  }) async {
    final trimmed = search?.trim();
    final result = await _api.get(
      ApiEndpoints.clients,
      query: {
        'page': 1,
        'limit': 20,
        if (trimmed != null && trimmed.isNotEmpty)
          'search': trimmed
        else if (assignedToMe)
          'assignedToMe': true,
      },
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffIncidentsMapper.clientsFrom(body)),
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
    String? occurredAt,
    String? description,
    String? location,
    bool? residentChecked,
    bool? supervisorNotified,
    bool? familyNotified,
    bool? carePlanReviewed,
  }) async {
    final data = <String, dynamic>{
      'residenceId': residenceId,
      'clientId': clientId,
      'categoryId': categoryId,
      'title': title,
      'severity': severity,
      'payload': payload,
      // Backend has no draft — create as open.
      'status': 'open',
      if (cirTemplateId != null && cirTemplateId.isNotEmpty)
        'cirTemplateId': cirTemplateId,
      if (occurredAt != null && occurredAt.isNotEmpty) 'occurredAt': occurredAt,
      if (occurredAt != null && occurredAt.isNotEmpty) 'reportedAt': occurredAt,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      'residentChecked': residentChecked,
      'supervisorNotified': supervisorNotified,
      'familyNotified': familyNotified,
      'carePlanReviewed': carePlanReviewed,
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
    String? occurredAt,
    String? description,
    String? location,
    bool? residentChecked,
    bool? supervisorNotified,
    bool? familyNotified,
    bool? carePlanReviewed,
  }) async {
    final data = <String, dynamic>{
      'residenceId': residenceId,
      'clientId': clientId,
      'categoryId': categoryId,
      'title': title,
      'severity': severity,
      'payload': payload,
      if (cirTemplateId != null && cirTemplateId.isNotEmpty)
        'cirTemplateId': cirTemplateId,
      if (occurredAt != null && occurredAt.isNotEmpty) 'occurredAt': occurredAt,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      if (residentChecked != null) 'residentChecked': residentChecked,
      if (supervisorNotified != null) 'supervisorNotified': supervisorNotified,
      if (familyNotified != null) 'familyNotified': familyNotified,
      if (carePlanReviewed != null) 'carePlanReviewed': carePlanReviewed,
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
  Future<Result<StaffIncidentEvidenceFile>> uploadEvidenceFile(
    StaffIncidentEvidenceFile file,
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
        query: const {'category': 'incidents'},
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
              const ApiError(
                message: 'Upload succeeded but file URL was missing.',
              ),
            );
          }
          return Result.success(
            file.copyWith(fileUrl: url, isUploading: false, clearError: true),
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

  String? _extractId(dynamic body) {
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      if (data is Map) {
        return data['id']?.toString() ?? data['incidentId']?.toString();
      }
      return map['id']?.toString() ?? map['incidentId']?.toString();
    }
    final unwrapped = JsonCodec.unwrapMap(body);
    return JsonCodec.string(unwrapped['id'] ?? unwrapped['incidentId']);
  }
}
