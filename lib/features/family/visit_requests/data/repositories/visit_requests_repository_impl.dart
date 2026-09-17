import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../domain/entities/family_visit_requests_overview.dart';
import '../../domain/entities/visit_request_detail.dart';
import '../../domain/repositories/visit_requests_repository.dart';
import '../mappers/family_visit_requests_mapper.dart';

class VisitRequestsRepositoryImpl implements VisitRequestsRepository {
  final AppApiClient _api;

  VisitRequestsRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<FamilyVisitRequestsOverview>> getOverview() async {
    final result = await _api.get(
      ApiEndpoints.familyAppointments,
      query: const {'page': 1, 'limit': 20},
    );
    return result.when(
      success: (body) async =>
          Result.success(FamilyVisitRequestsMapper.overviewFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<VisitRequestDetail>> getRequestDetail(String requestId) async {
    final result = await _api.get(ApiEndpoints.familyAppointmentById(requestId));
    return result.when(
      success: (body) async =>
          Result.success(FamilyVisitRequestsMapper.detailFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> reschedule({
    required String requestId,
    required DateTime scheduledAt,
  }) async {
    final result = await _api.post(
      ApiEndpoints.familyAppointmentReschedule(requestId),
      data: {'scheduledAt': scheduledAt.toUtc().toIso8601String()},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> cancel(String requestId) async {
    final result = await _api.post(
      ApiEndpoints.familyAppointmentCancel(requestId),
      data: {},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
