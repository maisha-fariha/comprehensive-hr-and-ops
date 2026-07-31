import 'package:gems_core/gems_core.dart';

import '../entities/tasks_compliance_overview.dart';

/// Contract for fetching the "Tasks & Compliance" screen's content. The
/// presentation layer only ever depends on this interface, so swapping the
/// mocked [TasksComplianceRepositoryImpl] for a real API-backed
/// implementation later requires no changes above the data layer.
abstract class TasksComplianceRepository {
  Future<Result<TasksComplianceOverview>> getOverview();
}
