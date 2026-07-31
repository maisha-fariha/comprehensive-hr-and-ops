import 'package:gems_core/gems_core.dart';

import '../entities/daily_note_overview.dart';
import '../entities/staff_daily_logs_overview.dart';

/// Contract for fetching the Staff Daily Logs screen's data (all three
/// tabs) and the "Daily Note" form's fields. The presentation layer only
/// ever depends on this interface, so swapping the mocked
/// [StaffDailyLogsRepositoryImpl] for a real API-backed implementation
/// later requires no changes above the data layer.
abstract class StaffDailyLogsRepository {
  Future<Result<StaffDailyLogsOverview>> getOverview();

  Future<Result<DailyNoteOverview>> getDailyNoteOverview();
}
