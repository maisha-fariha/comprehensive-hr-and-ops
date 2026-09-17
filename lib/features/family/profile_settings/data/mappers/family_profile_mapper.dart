import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_linked_client.dart';
import '../../domain/entities/family_notification_preference.dart';
import '../../domain/entities/family_preference_item.dart';
import '../../domain/entities/family_profile.dart';
import '../../domain/entities/family_profile_settings_overview.dart';
import '../../domain/entities/family_support_ticket.dart';
import '../../domain/entities/family_support_ticket_message.dart';
import '../../domain/entities/family_support_ticket_thread.dart';

abstract final class FamilyProfileMapper {
  static FamilyProfileSettingsOverview compose({
    required UserSession session,
    required dynamic clientsBody,
  }) {
    final clients = JsonCodec.unwrapList(clientsBody)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          // Family /clients returns firstName+lastName (not a flat `name`).
          final name = IsoDateRange.personName(
            json['preferredName'] ?? json['name'] ?? json,
          );
          final room = JsonCodec.string(json['room'] ?? json['roomNumber']);
          final residence = JsonCodec.string(
            json['residenceName'] ??
                JsonCodec.mapAt(json, 'residence')?['name'],
          );
          final rawStatus = JsonCodec.stringOr(json['status'], 'Active');
          final statusLabel = rawStatus.isEmpty
              ? 'Active'
              : '${rawStatus[0].toUpperCase()}${rawStatus.substring(1)}';
          return FamilyLinkedClient(
            id: JsonCodec.stringOr(json['id'], name),
            initials: IsoDateRange.initials(name),
            name: name,
            subtitle: [
              residence ?? session.residenceName ?? '',
              if (room != null) 'Room $room',
            ].where((part) => part.isNotEmpty).join(' · '),
            statusLabel: statusLabel,
          );
        })
        .where((client) => client.id.isNotEmpty)
        .toList();

    // Ensure a selected client exists when the list loads.
    if (clients.isNotEmpty) {
      final selected = session.selectedClientId;
      final stillLinked =
          selected != null && clients.any((client) => client.id == selected);
      if (!stillLinked) {
        session.selectClient(clients.first.id);
      }
    }

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

  static List<FamilyNotificationPreference> notificationPreferencesFrom(
    dynamic body,
  ) {
    final prefs = <FamilyNotificationPreference>[];
    final data = JsonCodec.unwrap(body);

    void addFromMap(Map<String, dynamic> json) {
      final eventKey = JsonCodec.string(json['eventKey'] ?? json['key']);
      if (eventKey == null || eventKey.isEmpty) return;
      prefs.add(
        FamilyNotificationPreference(
          channel: JsonCodec.stringOr(json['channel'], 'push'),
          eventKey: eventKey,
          enabled: JsonCodec.boolean(json['enabled']) ?? true,
          displayLabel: JsonCodec.string(json['label']),
          configurable: JsonCodec.boolean(json['configurable']) ?? true,
        ),
      );
    }

    if (data is List) {
      for (final item in data) {
        if (item is Map) addFromMap(JsonCodec.asMap(item));
      }
      return prefs;
    }

    final map = JsonCodec.asMap(data);
    final nested = map['preferences'] ?? map['items'];
    if (nested is List) {
      for (final item in nested) {
        if (item is Map) addFromMap(JsonCodec.asMap(item));
      }
      return prefs;
    }

    map.forEach((key, value) {
      final enabled = JsonCodec.boolean(value);
      if (enabled == null) return;
      prefs.add(
        FamilyNotificationPreference(
          channel: 'push',
          eventKey: key,
          enabled: enabled,
        ),
      );
    });
    return prefs;
  }

  /// Builds editable rows from GET /notification-preferences/events, overlaying
  /// saved values from GET /notification-preferences.
  static List<FamilyNotificationPreference> mergePreferencesWithEvents({
    required List<FamilyNotificationPreference> saved,
    required dynamic eventsBody,
  }) {
    final savedByKey = <String, bool>{
      for (final pref in saved) '${pref.eventKey}|${pref.channel}': pref.enabled,
    };

    final merged = <FamilyNotificationPreference>[];
    for (final item in JsonCodec.unwrapList(eventsBody)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final eventKey = JsonCodec.string(json['key'] ?? json['eventKey']);
      if (eventKey == null || eventKey.isEmpty) continue;

      final configurable = JsonCodec.boolean(json['configurable']) ?? true;
      if (!configurable) continue;

      final label = JsonCodec.string(json['label']);
      final channels = json['channels'];
      final channelList = channels is List && channels.isNotEmpty
          ? channels
              .map((c) => JsonCodec.string(c))
              .whereType<String>()
              .where((c) => c.isNotEmpty)
              .toList()
          : <String>['push'];

      for (final channel in channelList) {
        final key = '$eventKey|$channel';
        merged.add(
          FamilyNotificationPreference(
            channel: channel,
            eventKey: eventKey,
            enabled: savedByKey[key] ?? true,
            displayLabel: label,
            configurable: true,
          ),
        );
      }
    }

    if (merged.isNotEmpty) return merged;
    // Events missing or empty — fall back to whatever the user already saved.
    return saved;
  }

  static FamilySupportTicket ticketFrom(Map<String, dynamic> json) {
    final at = JsonCodec.dateTime(json['createdAt'] ?? json['updatedAt']);
    return FamilySupportTicket(
      id: JsonCodec.stringOr(json['id'], ''),
      subject: JsonCodec.stringOr(json['subject'], 'Support request'),
      status: JsonCodec.stringOr(json['status'], 'open'),
      priority: JsonCodec.stringOr(json['priority'], 'low'),
      createdAtLabel: at == null
          ? ''
          : IsoDateRange.dateTimeLabel(at.toLocal()),
    );
  }

  static List<FamilySupportTicket> ticketsFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => ticketFrom(JsonCodec.asMap(item)))
        .where((ticket) => ticket.id.isNotEmpty)
        .toList();
  }

  static FamilySupportTicketMessage messageFrom(Map<String, dynamic> json) {
    final at = JsonCodec.dateTime(json['createdAt'] ?? json['sentAt']);
    final realm = (JsonCodec.string(json['senderRealm']) ?? '').toLowerCase();
    final fromFamily = realm.isEmpty
        ? JsonCodec.string(json['senderTenantUserId']) != null
        : realm == 'tenant' || realm == 'family';
    return FamilySupportTicketMessage(
      id: JsonCodec.stringOr(json['id'], ''),
      body: JsonCodec.stringOr(json['body'], ''),
      fromFamily: fromFamily,
      sentAtLabel: at == null ? '' : IsoDateRange.dateTimeLabel(at.toLocal()),
    );
  }

  static List<FamilySupportTicketMessage> messagesFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => messageFrom(JsonCodec.asMap(item)))
        .toList();
  }

  static FamilySupportTicketThread threadFrom({
    required dynamic ticketBody,
    required dynamic messagesBody,
  }) {
    final ticketJson = JsonCodec.unwrapMap(ticketBody);
    final embedded = ticketJson['messages'];
    final messages = embedded != null
        ? messagesFrom(embedded)
        : messagesFrom(messagesBody);
    return FamilySupportTicketThread(
      ticket: ticketFrom(ticketJson),
      messages: messages,
    );
  }

  const FamilyProfileMapper._();
}
