import 'package:gems_core/gems_core.dart';

import '../entities/family_dashboard_overview.dart';

/// Contract for fetching the Family dashboard summary. The presentation
/// layer only ever depends on this interface, so swapping the mocked
/// [FamilyDashboardRepositoryImpl] for a real API-backed implementation
/// later requires no changes above the data layer.
abstract class FamilyDashboardRepository {
  Future<Result<FamilyDashboardOverview>> getOverview();
}
