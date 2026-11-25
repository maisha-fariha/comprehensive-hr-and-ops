import 'package:gems_core/gems_core.dart';

import '../entities/family_care_journal_models.dart';
import '../entities/family_daily_updates_overview.dart';

/// Family Care Journal (`/family/updates`) + legacy daily-updates helpers.
abstract class FamilyDailyUpdatesRepository {
  /// Legacy flattened timeline (still used by older callers).
  Future<Result<FamilyDailyUpdatesOverview>> getOverview();

  /// Full Care Journal payload for a linked resident.
  Future<Result<FamilyCareJournalOverview>> getCareJournal({
    String? clientId,
  });
}
