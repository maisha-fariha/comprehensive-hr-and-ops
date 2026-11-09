import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../domain/entities/ai_report.dart';
import '../../domain/repositories/ai_alerts_repository.dart';
import '../mappers/ai_alerts_mapper.dart';

class AiAlertsRepositoryImpl implements AiAlertsRepository {
  final AppApiClient _api;

  AiAlertsRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<AiFeatureGate>> getFeatureGate() async {
    final result = await _api.get(ApiEndpoints.aiStatus, silent: true);
    return result.when(
      success: (body) async => Result.success(AiAlertsMapper.gateFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiReportsPage>> getReports({
    int page = 1,
    int limit = 30,
    String? q,
    String? kind,
    String? severity,
    String? residenceId,
    String? from,
    String? to,
    bool unreadOnly = false,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (kind != null && kind.isNotEmpty) 'kind': kind,
      if (severity != null && severity.isNotEmpty) 'severity': severity,
      if (residenceId != null && residenceId.isNotEmpty) 'residenceId': residenceId,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
      if (unreadOnly) 'unread': true,
    };
    final result = await _api.get(ApiEndpoints.aiReports, query: query);
    return result.when(
      success: (body) async => Result.success(AiAlertsMapper.reportsPageFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiReportDetail>> getReportDetail(String id) async {
    final result = await _api.get(ApiEndpoints.aiReportById(id));
    return result.when(
      success: (body) async =>
          Result.success(AiAlertsMapper.detailFrom(body, id: id)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiReportAutomationsPage>> getAutomations() async {
    final result = await _api.get(ApiEndpoints.aiReportAutomations);
    return result.when(
      success: (body) async =>
          Result.success(AiAlertsMapper.automationsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }
}
