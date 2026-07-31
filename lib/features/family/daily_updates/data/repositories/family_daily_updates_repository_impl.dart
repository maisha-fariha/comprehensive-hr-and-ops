import 'package:gems_core/gems_core.dart';

import '../../domain/entities/family_daily_update_enums.dart';
import '../../domain/entities/family_daily_update_entry.dart';
import '../../domain/entities/family_daily_updates_overview.dart';
import '../../domain/repositories/family_daily_updates_repository.dart';

/// Local implementation of [FamilyDailyUpdatesRepository].
///
/// There is no backend endpoint for the Daily Updates timeline yet, so this
/// returns the exact static content shown in the reference screenshot.
/// Replace the body of [getOverview] with a real `ApiService`/
/// `BaseRepository` call once an API contract exists - the domain layer and
/// every widget above it will keep working unchanged.
class FamilyDailyUpdatesRepositoryImpl implements FamilyDailyUpdatesRepository {
  @override
  Future<Result<FamilyDailyUpdatesOverview>> getOverview() async {
    return Result.success(
      const FamilyDailyUpdatesOverview(
        screenTitle: 'Daily Updates',
        screenSubtitle: 'Only approved updates are shown.',
        dateSectionLabel: 'Today · May 12, 2025',
        entries: [
          FamilyDailyUpdateEntry(
            id: 'mood-8am',
            category: DailyUpdateCategory.mood,
            timeLabel: '8:00 AM',
            title: 'Mood',
            description: 'John was in good spirits today.',
          ),
          FamilyDailyUpdateEntry(
            id: 'meals-1215pm',
            category: DailyUpdateCategory.meals,
            timeLabel: '12:15 PM',
            title: 'Meals',
            description: 'Ate 100% of breakfast and 75% of lunch.',
          ),
          FamilyDailyUpdateEntry(
            id: 'activities-215pm',
            category: DailyUpdateCategory.activities,
            timeLabel: '2:15 PM',
            title: 'Activities',
            description: 'Participated in chair yoga and music time.',
          ),
          FamilyDailyUpdateEntry(
            id: 'community-outing-430pm',
            category: DailyUpdateCategory.communityOuting,
            timeLabel: '4:30 PM',
            title: 'Community Outing',
            description: 'Enjoyed the garden walk and coffee social.',
          ),
          FamilyDailyUpdateEntry(
            id: 'sleep-745pm',
            category: DailyUpdateCategory.sleep,
            timeLabel: '7:45 PM',
            title: 'Sleep',
            description: 'Resting well this evening. Lights out at 7:30 PM.',
            showTimelineDivider: false,
          ),
        ],
        footerNote: 'All updates are reviewed and approved by the care team before sharing.',
      ),
    );
  }
}
