import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import '../../domain/repositories/tasks_compliance_repository.dart';
import '../mappers/tasks_compliance_mapper.dart';

class TasksComplianceRepositoryImpl implements TasksComplianceRepository {
  final AppApiClient _api;
  final UserSession _session;

  TasksComplianceRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<TasksComplianceOverview>> getOverview() async {
    final residenceId = _session.residenceId;
    final query = <String, dynamic>{'residenceId': ?residenceId};
    final tasks = await _api.get(ApiEndpoints.tasks, query: query);
    if (tasks.isFailure) {
      return Result.failure(
        tasks.error ?? const ApiError(message: 'Could not load tasks.'),
      );
    }
    final extras = await Future.wait([
      _api.get(ApiEndpoints.tasksStats, query: query),
      _api.get(ApiEndpoints.complianceScore, query: query),
      _api.get(ApiEndpoints.complianceOverview, query: query),
      _api.get(ApiEndpoints.complianceChecks, query: query),
      _api.get(ApiEndpoints.complianceCorrectiveActions, query: query),
    ]);
    return Result.success(
      TasksComplianceMapper.compose(
        statsBody: extras[0].value,
        tasksBody: tasks.value,
        scoreBody: extras[1].value,
        overviewBody: extras[2].value,
        checksBody: extras[3].value,
        actionsBody: extras[4].value,
        residenceName: _session.residenceName,
      ),
    );
  }
}
