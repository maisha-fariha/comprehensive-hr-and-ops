import 'package:gems_core/gems_core.dart';

import '../entities/staff_dashboard_overview.dart';

/// Contract for fetching the Staff Dashboard summary. The presentation
/// layer only ever depends on this interface, so swapping the mocked
/// [StaffDashboardRepositoryImpl] for a real API-backed implementation
/// later requires no changes above the data layer.
abstract class StaffDashboardRepository {
  Future<Result<StaffDashboardOverview>> getOverview();
}
