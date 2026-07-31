import 'package:gems_core/gems_core.dart';

import '../entities/dashboard_overview.dart';

/// Contract for fetching the HR/Manager dashboard summary. The presentation
/// layer only ever depends on this interface, so swapping the mocked
/// [DashboardRepositoryImpl] for a real API-backed implementation later
/// requires no changes above the data layer.
abstract class DashboardRepository {
  Future<Result<DashboardOverview>> getOverview();
}
