import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_linked_item.dart';
import '../../domain/entities/staff_preference_item.dart';
import '../../domain/entities/staff_profile.dart';
import '../../domain/entities/staff_profile_settings_overview.dart';

abstract final class StaffProfileMapper {
  static StaffProfileSettingsOverview compose({
    required UserSession session,
    required dynamic clientsBody,
  }) {
    final clients = JsonCodec.unwrapList(clientsBody).whereType<Map>().map((item) {
      final json = JsonCodec.asMap(item);
      final name = IsoDateRange.personName(
        json['preferredName'] ?? json['name'],
      );
      final room = JsonCodec.string(json['room'] ?? json['roomNumber']);
      final residence = JsonCodec.string(
            json['residenceName'] ?? JsonCodec.mapAt(json, 'residence')?['name'],
          ) ??
          session.residenceName ??
          '';
      return StaffLinkedItem(
        initials: IsoDateRange.initials(name),
        name: name,
        subtitle: [
          residence,
          if (room != null) 'Room $room',
        ].where((part) => part.isNotEmpty).join(' · '),
        statusLabel: JsonCodec.stringOr(json['status'], 'Active'),
      );
    }).toList();

    return StaffProfileSettingsOverview(
      profile: StaffProfile(
        initials: session.avatarInitials,
        name: session.displayName,
        role: session.role.label,
        email: session.email,
      ),
      linkedItems: clients,
      preferenceItems: const [
        StaffPreferenceItem(
          type: StaffPreferenceType.notifications,
          label: 'Notification Preferences',
        ),
        StaffPreferenceItem(
          type: StaffPreferenceType.changePassword,
          label: 'Change Password',
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
    );
  }

  const StaffProfileMapper._();
}
