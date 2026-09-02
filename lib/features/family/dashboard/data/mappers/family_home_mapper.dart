import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_attention_alert.dart';
import '../../domain/entities/family_dashboard_enums.dart';
import '../../domain/entities/family_dashboard_overview.dart';
import '../../domain/entities/family_glance_item.dart';
import '../../domain/entities/family_next_appointment.dart';
import '../../domain/entities/family_overview_stat.dart';
import '../../domain/entities/family_quick_action.dart';
import '../../domain/entities/family_recent_update.dart';

abstract final class FamilyHomeMapper {
  static FamilyDashboardOverview compose({
    required UserSession session,
    required dynamic homeBody,
    required dynamic updatesBody,
    int? unreadNotificationCount,
  }) {
    final json = JsonCodec.unwrapMap(homeBody);
    final visibilityJson = JsonCodec.mapAt(json, 'visibility') ?? {};
    final visibility = FamilyVisibility(
      dailyLogs: JsonCodec.boolean(visibilityJson['dailyLogs']) ?? true,
      activities: JsonCodec.boolean(visibilityJson['activities']) ?? true,
      incidents: JsonCodec.boolean(visibilityJson['incidents']) ?? true,
      medications: JsonCodec.boolean(visibilityJson['medications']) ?? false,
      documents: JsonCodec.boolean(visibilityJson['documents']) ?? false,
      appointments: JsonCodec.boolean(visibilityJson['appointments']) ?? true,
      messages: JsonCodec.boolean(visibilityJson['messages']) ?? true,
      shiftUpdates: JsonCodec.boolean(visibilityJson['shiftUpdates']) ?? false,
      medicalConditions:
          JsonCodec.boolean(visibilityJson['medicalConditions']) ?? false,
    );

    final clients = JsonCodec.listAt(json, 'linkedClients');
    Map<String, dynamic> client = {};
    if (clients.isNotEmpty && clients.first is Map) {
      client = JsonCodec.asMap(clients.first as Map);
    }
    final clientName = IsoDateRange.personName(
      client['preferredName'] ?? client['name'] ?? json['clientName'],
    );
    final room = JsonCodec.string(
      client['room'] ?? client['roomNumber'] ?? json['room'],
    );
    final residenceName = JsonCodec.stringOr(
      client['residenceName'] ??
          JsonCodec.mapAt(client, 'residence')?['name'] ??
          json['residenceName'],
      session.residenceName ?? 'Home',
    );

    session.applyFamilyHome(
      visibility: visibility,
      clientId: JsonCodec.string(client['id'] ?? json['clientId']),
      residenceName: residenceName,
    );

    final now = DateTime.now();
    final firstName = session.displayName.split(' ').first;
    final nextVisit = JsonCodec.mapAt(json, 'nextVisit') ??
        JsonCodec.mapAt(json, 'nextAppointment');
    final totals = JsonCodec.mapAt(json, 'totals') ?? {};
    final recent = _recentUpdate(updatesBody, visibility.dailyLogs);

    return FamilyDashboardOverview(
      residenceName: residenceName,
      dateLabel: IsoDateRange.formatDisplayDate(now),
      greetingLine: '${IsoDateRange.greetingPrefix(now)}, $firstName 👋',
      greetingSubtitle: [
        if (room != null) 'Room $room',
        if (clientName != 'Unknown') clientName,
        "Here's what's happening today.",
      ].where((part) => part.isNotEmpty).join(' | '),
      lastUpdatedLabel: 'Updated ${IsoDateRange.timeLabel(now)}',
      unreadNotificationCount:
          unreadNotificationCount ?? JsonCodec.integerOr(json['unreadCount'], 0),
      attentionAlerts: _alerts(json['alerts'], visibility),
      overviewStats: _totals(totals, visibility),
      nextAppointment: visibility.appointments ? _nextVisit(nextVisit) : null,
      recentUpdate: recent,
      glanceItems: _glance(recent, totals, visibility),
      quickActions: _actions(visibility),
    );
  }

  static List<FamilyAttentionAlert> _alerts(
    dynamic raw,
    FamilyVisibility visibility,
  ) {
    final items = raw is List ? raw : JsonCodec.unwrapList(raw);
    return [
      for (final item in items)
        if (item is Map)
          FamilyAttentionAlert(
            id: JsonCodec.stringOr(JsonCodec.asMap(item)['id'], 'alert'),
            title: JsonCodec.stringOr(
              JsonCodec.asMap(item)['title'] ?? JsonCodec.asMap(item)['message'],
              'Alert',
            ),
            subtitle: JsonCodec.stringOr(
              JsonCodec.asMap(item)['subtitle'] ??
                  JsonCodec.asMap(item)['detail'],
              '',
            ),
            severity: (JsonCodec.string(JsonCodec.asMap(item)['severity']) ?? '')
                    .toLowerCase()
                    .contains('high')
                ? AlertSeverity.critical
                : AlertSeverity.urgent,
          ),
    ];
  }

  static List<FamilyOverviewStat> _totals(
    Map<String, dynamic> totals,
    FamilyVisibility visibility,
  ) {
    return [
      FamilyOverviewStat(
        id: 'linked-clients',
        tag: StatTag.active,
        value: '${JsonCodec.integerOr(totals['linkedClients'], 0)}',
        label: 'Linked Clients',
        helperText: 'Your family members in care',
        isHelperTextPositive: true,
      ),
      if (visibility.incidents)
        FamilyOverviewStat(
          id: 'open-incidents',
          tag: StatTag.urgent,
          value: '${JsonCodec.integerOr(totals['openIncidents'], 0)}',
          label: 'Open Incidents',
          helperText: 'About your family only',
        ),
      if (visibility.dailyLogs)
        FamilyOverviewStat(
          id: 'daily-logs',
          tag: StatTag.review,
          value: '${JsonCodec.integerOr(totals['dailyLogsPast7d'], 0)}',
          label: 'Updates (7 days)',
          helperText: 'Shared care notes',
        ),
    ];
  }

  static FamilyNextAppointment? _nextVisit(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    final at = JsonCodec.dateTime(json['scheduledAt'] ?? json['startsAt']);
    return FamilyNextAppointment(
      id: JsonCodec.stringOr(json['id'], 'next-visit'),
      dateTimeLabel: at == null
          ? JsonCodec.stringOr(json['dateLabel'], '')
          : IsoDateRange.dateTimeLabel(at),
      title: JsonCodec.stringOr(
        json['title'] ?? json['type'] ?? json['purpose'],
        'Visit',
      ),
      location: JsonCodec.stringOr(json['location'], ''),
      statusLabel: JsonCodec.stringOr(json['status'], 'Upcoming'),
    );
  }

  static FamilyRecentUpdate? _recentUpdate(dynamic body, bool allowed) {
    if (!allowed) return null;
    final items = JsonCodec.unwrapList(body);
    if (items.isEmpty || items.first is! Map) return null;
    final json = JsonCodec.asMap(items.first as Map);
    final author = JsonCodec.mapAt(json, 'author') ?? {};
    final name = IsoDateRange.personName(
      author.isEmpty ? json['authorName'] : author,
    );
    final at = JsonCodec.dateTime(
      json['occurredAt'] ?? json['createdAt'] ?? json['updatedAt'],
    );
    final observations = JsonCodec.mapAt(json, 'observations') ?? {};
    final bodyText = JsonCodec.string(
          json['body'] ?? json['summary'] ?? json['notes'],
        ) ??
        observations.values
            .where((value) => value != null && value.toString().trim().isNotEmpty)
            .map((value) => value.toString())
            .join(' ');
    return FamilyRecentUpdate(
      id: JsonCodec.stringOr(json['id'], 'update'),
      authorName: name,
      authorInitials: IsoDateRange.initials(name, fallback: 'RN'),
      dateTimeLabel: at == null ? '' : IsoDateRange.dateTimeLabel(at),
      statusLabel: JsonCodec.stringOr(json['status'], 'Shared'),
      body: bodyText.isEmpty ? 'A care update was shared.' : bodyText,
      hasImage: JsonCodec.listAt(json, 'attachments').isNotEmpty,
    );
  }

  static List<FamilyGlanceItem> _glance(
    FamilyRecentUpdate? recent,
    Map<String, dynamic> totals,
    FamilyVisibility visibility,
  ) {
    if (!visibility.dailyLogs) return const [];
    return [
      FamilyGlanceItem(
        id: 'updates',
        label: 'Care notes',
        value: '${JsonCodec.integerOr(totals['dailyLogsPast7d'], 0)}',
      ),
      if (visibility.appointments)
        const FamilyGlanceItem(id: 'visits', label: 'Next visit', value: 'See card'),
      if (recent != null)
        FamilyGlanceItem(
          id: 'latest',
          label: 'Latest update',
          value: recent.authorName,
        ),
    ];
  }

  static List<FamilyQuickAction> _actions(FamilyVisibility visibility) {
    return [
      if (visibility.appointments)
        const FamilyQuickAction(
          id: 'request-visit',
          label: 'Request\nVisit',
          asset: 'assets/icons/family_core/request.svg',
        ),
      if (visibility.messages)
        const FamilyQuickAction(
          id: 'send-message',
          label: 'Send\nMessage',
          asset: 'assets/icons/family_core/message.svg',
        ),
      if (visibility.documents)
        const FamilyQuickAction(
          id: 'view-documents',
          label: 'View\nDocuments',
          asset: 'assets/icons/family_core/document.svg',
        ),
    ];
  }

  const FamilyHomeMapper._();
}
