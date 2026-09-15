import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_role.dart';
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

    final name = session.displayName.trim().isEmpty
        ? (session.email.contains('@')
            ? session.email.split('@').first
            : 'Staff')
        : session.displayName.trim();

    return StaffProfileSettingsOverview(
      profile: StaffProfile(
        initials: session.avatarInitials.trim().isEmpty
            ? IsoDateRange.initials(name)
            : session.avatarInitials,
        name: name,
        role: _roleLabel(session),
        email: session.email,
        residenceName: session.residenceName ?? session.organizationName,
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

  /// Prefer care-role (Nurse / Caregiver / …) over portal label "Staff".
  static String _roleLabel(UserSession session) {
    final kind = session.staffKind;
    if (kind != null && kind != StaffKind.other) return kind.label;

    final raw = (session.roleRaw ?? '').trim();
    if (raw.isNotEmpty) {
      final parsed = StaffKind.tryParse(raw);
      if (parsed != null && parsed != StaffKind.other) return parsed.label;
      return _titleCase(raw);
    }
    return session.role.label;
  }

  static String _titleCase(String raw) {
    return raw
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  const StaffProfileMapper._();
}
