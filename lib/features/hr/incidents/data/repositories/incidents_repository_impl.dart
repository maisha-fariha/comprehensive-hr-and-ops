import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/incident_category_option.dart';
import '../../domain/entities/incident_cir_template_option.dart';
import '../../domain/entities/incident_client_option.dart';
import '../../domain/entities/incident_evidence_file.dart';
import '../../domain/entities/incident_residence_option.dart';
import '../../domain/entities/incident_staff_option.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/repositories/incidents_repository.dart';
import '../mappers/incidents_mapper.dart';

class IncidentsRepositoryImpl implements IncidentsRepository {
  final AppApiClient _api;
  final UserSession _session;

  IncidentsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

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
