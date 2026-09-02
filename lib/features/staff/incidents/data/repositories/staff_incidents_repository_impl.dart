import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/incident_detail.dart';
import '../../domain/entities/staff_incident.dart';
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
  }) async {
    final result = await _api.get(
      ApiEndpoints.incidents,
      query: {
        'page': 1,
        'limit': 20,
        'residenceId': ?_session.residenceId,
        if (mine) 'reporter': 'me',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffIncidentsMapper.listFrom(body)),
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
}
