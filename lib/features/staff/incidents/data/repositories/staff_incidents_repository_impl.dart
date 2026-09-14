import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
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

  StaffIncidentsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

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
