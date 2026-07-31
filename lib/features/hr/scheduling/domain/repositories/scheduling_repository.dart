import 'package:gems_core/gems_core.dart';

import '../entities/scheduling_overview.dart';

/// Contract for fetching the HR/Manager Scheduling screen's data (its
/// Calendar, Board and Requests tabs). The presentation layer only ever
/// depends on this interface, so swapping the mocked
/// [SchedulingRepositoryImpl] for a real API-backed implementation later
/// requires no changes above the data layer.
abstract class SchedulingRepository {
  Future<Result<SchedulingOverview>> getOverview();
}
