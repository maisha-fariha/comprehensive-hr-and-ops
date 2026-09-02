import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/hr_linked_item.dart';
import '../../domain/entities/hr_preference_item.dart';
import '../../domain/entities/hr_profile.dart';
import '../../domain/entities/hr_profile_settings_overview.dart';

abstract final class HrProfileMapper {
  static HrProfileSettingsOverview compose({
    required UserSession session,
    required dynamic residencesBody,
  }) {
    final residences = JsonCodec.unwrapList(residencesBody)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final name = JsonCodec.stringOr(json['name'], session.residenceName ?? 'Residence');
          final count = JsonCodec.integer(json['clientCount'] ?? json['occupancy']);
          return HrLinkedItem(
            initials: IsoDateRange.initials(name),
            name: name,
            subtitle: count == null ? 'Residence' : '$count active residents',
            statusLabel: JsonCodec.stringOr(json['status'], 'Active'),
          );
        })
        .toList();
    if (residences.isEmpty && (session.residenceName ?? '').isNotEmpty) {
      residences.add(
        HrLinkedItem(
          initials: IsoDateRange.initials(session.residenceName),
          name: session.residenceName!,
          subtitle: session.organizationName ?? 'Residence',
          statusLabel: 'Active',
        ),
      );
    }

    return HrProfileSettingsOverview(
      profile: HrProfile(
        initials: session.avatarInitials,
        name: session.displayName,
        role: session.role.label,
        email: session.email,
      ),
      linkedItems: residences,
      preferenceItems: const [
        HrPreferenceItem(
          type: HrPreferenceType.notifications,
          label: 'Notification Preferences',
        ),
        HrPreferenceItem(
          type: HrPreferenceType.changePassword,
          label: 'Change Password',
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
    );
  }

  const HrProfileMapper._();
}
