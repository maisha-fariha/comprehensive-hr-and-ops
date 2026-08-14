import 'package:gems_core/gems_core.dart';

import '../../domain/entities/staff_linked_item.dart';
import '../../domain/entities/staff_preference_item.dart';
import '../../domain/entities/staff_profile.dart';
import '../../domain/entities/staff_profile_settings_overview.dart';
import '../../domain/repositories/staff_profile_settings_repository.dart';

class StaffProfileSettingsRepositoryImpl implements StaffProfileSettingsRepository {
  @override
  Future<Result<StaffProfileSettingsOverview>> getOverview() async {
    return Result.success(
      const StaffProfileSettingsOverview(
        profile: StaffProfile(
          initials: 'AW',
          name: 'Alex Wright',
          role: 'Support Worker',
          email: 'alex.wright@sunrisehome.com',
        ),
        linkedItems: [
          StaffLinkedItem(
            initials: 'JD',
            name: 'John Doe',
            subtitle: 'Sunrise Home · Room 207',
            statusLabel: 'Active',
          )
        ],
        preferenceItems: [
          StaffPreferenceItem(
            type: StaffPreferenceType.notifications,
            label: 'Notification Preferences',
          ),
          StaffPreferenceItem(
            type: StaffPreferenceType.helpCenter,
            label: 'Help Center & FAQs',
          ),
          StaffPreferenceItem(
            type: StaffPreferenceType.contactSupport,
            label: 'Contact Support',
          ),
          StaffPreferenceItem(
            type: StaffPreferenceType.privacySecurity,
            label: 'Privacy & Security',
          ),
        ],
        pushNotificationsEnabled: true,
        darkModeEnabled: false,
      ),
    );
  }
}
