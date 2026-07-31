import 'package:gems_core/gems_core.dart';

import '../entities/family_daily_updates_overview.dart';

/// Contract for fetching the Family "Daily Updates" timeline. The
/// presentation layer only ever depends on this interface, so swapping the
/// mocked [FamilyDailyUpdatesRepositoryImpl] for a real API-backed
/// implementation later requires no changes above the data layer.
abstract class FamilyDailyUpdatesRepository {
  Future<Result<FamilyDailyUpdatesOverview>> getOverview();
}
