import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_linked_client.dart';
import '../../domain/entities/family_preference_item.dart';
import '../../domain/entities/family_profile.dart';
import '../../domain/entities/family_profile_settings_overview.dart';

abstract final class FamilyProfileMapper {
  static FamilyProfileSettingsOverview compose({
    required UserSession session,
    required dynamic clientsBody,
  }) {
    final clients = JsonCodec.unwrapList(clientsBody)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final name = IsoDateRange.personName(
            json['preferredName'] ?? json['name'],
          );
          final room = JsonCodec.string(json['room'] ?? json['roomNumber']);
          final residence = JsonCodec.string(
            json['residenceName'] ??
                JsonCodec.mapAt(json, 'residence')?['name'],
          );
          return FamilyLinkedClient(
            id: JsonCodec.stringOr(json['id'], name),
            initials: IsoDateRange.initials(name),
            name: name,
            subtitle: [
              residence ?? session.residenceName ?? '',
              if (room != null) 'Room $room',
            ].where((part) => part.isNotEmpty).join(' · '),
            statusLabel: JsonCodec.stringOr(json['status'], 'Active'),
          );
        })
        .toList();

    return FamilyProfileSettingsOverview(
      profile: FamilyProfile(
        initials: session.avatarInitials,
        name: session.displayName,
        relationship: session.relationship ?? 'Family',
        email: session.email,
      ),
      linkedClients: clients,
      preferenceItems: const [
        FamilyPreferenceItem(
          type: FamilyPreferenceType.notifications,
          label: 'Notification Preferences',
        ),
        FamilyPreferenceItem(
          type: FamilyPreferenceType.changePassword,
          label: 'Change Password',
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
    );
  }

  const FamilyProfileMapper._();
}
