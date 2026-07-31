import 'package:gems_core/gems_core.dart';

import '../../domain/entities/family_linked_client.dart';
import '../../domain/entities/family_preference_item.dart';
import '../../domain/entities/family_profile.dart';
import '../../domain/entities/family_profile_settings_overview.dart';
import '../../domain/repositories/family_profile_settings_repository.dart';

/// Local implementation of [FamilyProfileSettingsRepository].
///
/// There is no backend endpoint for the family profile/settings yet, so
/// this returns the exact static content shown in the reference
/// screenshot (plus a minimal, plausible completion of the cropped "App
/// Settings" section — see `FamilyProfileSettingsOverview`). Replace the
/// body of [getOverview] with a real `ApiService`/`BaseRepository` call
/// once an API contract exists — the domain layer and every widget above
/// it will keep working unchanged.
class FamilyProfileSettingsRepositoryImpl implements FamilyProfileSettingsRepository {
  @override
  Future<Result<FamilyProfileSettingsOverview>> getOverview() async {
    return Result.success(
      const FamilyProfileSettingsOverview(
        profile: FamilyProfile(
          initials: 'EJ',
          name: 'Emily Johnson',
          relationship: 'Daughter',
          email: 'emily.johnson@email.com',
        ),
        linkedClients: [
          FamilyLinkedClient(
            initials: 'JD',
            name: 'John Doe',
            subtitle: 'Sunrise Home · Room 207',
            statusLabel: 'Active',
          ),
        ],
        preferenceItems: [
          FamilyPreferenceItem(
            type: FamilyPreferenceType.notifications,
            label: 'Notification Preferences',
          ),
          FamilyPreferenceItem(
            type: FamilyPreferenceType.helpCenter,
            label: 'Help Center & FAQs',
          ),
          FamilyPreferenceItem(
            type: FamilyPreferenceType.contactSupport,
            label: 'Contact Support',
          ),
          FamilyPreferenceItem(
            type: FamilyPreferenceType.privacySecurity,
            label: 'Privacy & Security',
          ),
        ],
        pushNotificationsEnabled: true,
        darkModeEnabled: false,
      ),
    );
  }
}
