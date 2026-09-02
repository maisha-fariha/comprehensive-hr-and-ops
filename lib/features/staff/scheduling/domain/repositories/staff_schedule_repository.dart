import 'package:gems_core/gems_core.dart';

import '../entities/staff_schedule_overview.dart';

/// Contract for fetching the "My Schedule" summary. The presentation layer
/// only ever depends on this interface, so swapping the mocked
/// [StaffScheduleRepositoryImpl] for a real API-backed implementation later
/// requires no changes above the data layer.
abstract class StaffScheduleRepository {
  Future<Result<StaffScheduleOverview>> getOverview();

  Future<Result<void>> bidOnShift(String shiftId);
}
