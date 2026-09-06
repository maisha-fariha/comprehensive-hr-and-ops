import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
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
  Future<Result<String>> createIncident(Map<String, dynamic> payload) async {
    final result = await _api.post(
      ApiEndpoints.incidents,
      data: payload,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final id = _extractId(body);
        return Result.success(id ?? '');
      },
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
