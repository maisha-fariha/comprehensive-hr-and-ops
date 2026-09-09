import 'package:gems_core/gems_core.dart';

import '../entities/daily_logs_overview.dart';

/// Contract for fetching the Daily Logs screen's data (Review / Missing /
/// Handover tabs) from `/daily-logs`, `/care-flags`, and `/shift-handovers`.
abstract class DailyLogsRepository {
  Future<Result<DailyLogsOverview>> getOverview();

  /// Manager acknowledges a handover via `POST /shift-handovers/:id/acknowledge`.
  Future<Result<void>> acknowledgeHandover(String handoverId);
}
