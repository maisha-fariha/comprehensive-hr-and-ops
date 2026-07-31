import 'package:gems_core/gems_core.dart';

import '../entities/daily_logs_overview.dart';

/// Contract for fetching the Daily Logs screen's data (all three tabs). The
/// presentation layer only ever depends on this interface, so swapping the
/// mocked [DailyLogsRepositoryImpl] for a real API-backed implementation
/// later requires no changes above the data layer.
abstract class DailyLogsRepository {
  Future<Result<DailyLogsOverview>> getOverview();
}
