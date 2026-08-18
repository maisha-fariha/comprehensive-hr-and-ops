import 'package:gems_core/gems_core.dart';

import '../../domain/entities/hr_linked_item.dart';
import '../../domain/entities/hr_preference_item.dart';
import '../../domain/entities/hr_profile.dart';
import '../../domain/entities/hr_profile_settings_overview.dart';
import '../../domain/repositories/hr_profile_settings_repository.dart';

class HrProfileSettingsRepositoryImpl implements HrProfileSettingsRepository {
  @override
  Future<Result<HrProfileSettingsOverview>> getOverview() async {
    return Result.success(
      const HrProfileSettingsOverview(
        profile: HrProfile(
          initials: 'SM',
          name: 'Sarah Mitchell',
          role: 'Care Manager',
          email: 'sarah.mitchell@sunrisehome.com',
        ),
        linkedItems: [
          HrLinkedItem(
            initials: 'SH',
            name: 'Sunrise Home',
            subtitle: '12 active residents',
            statusLabel: 'Active',
          )
        ],
        preferenceItems: [
          HrPreferenceItem(
            type: HrPreferenceType.notifications,
            label: 'Notification Preferences',
          ),
          HrPreferenceItem(
            type: HrPreferenceType.helpCenter,
            label: 'Help Center & FAQs',
          ),
          HrPreferenceItem(
            type: HrPreferenceType.contactSupport,
            label: 'Contact Support',
          ),
          HrPreferenceItem(
            type: HrPreferenceType.privacySecurity,
            label: 'Privacy & Security',
          ),
        ],
        pushNotificationsEnabled: true,
        darkModeEnabled: false,
      ),
    );
  }
}
