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
import '../../domain/entities/family_shared_activity.dart';

abstract final class FamilyHomeMapper {
  static FamilyDashboardOverview compose({
    required UserSession session,
    required dynamic homeBody,
    required dynamic updatesBody,
    dynamic activitiesBody,
    String? selectedClientId,
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
    final linkedClients = <
        ({
          String id,
          String name,
          String residenceName,
          String? room,
          String status
        })>[
      for (final raw in clients.whereType<Map>())
        () {
          final m = JsonCodec.asMap(raw);
          final name = IsoDateRange.personName(
            m['preferredName'] ?? m['name'] ?? m,
          );
          return (
            id: JsonCodec.stringOr(m['id'], ''),
            name: name == 'Unknown' ? 'Resident' : name,
            residenceName: JsonCodec.stringOr(
              m['residenceName'] ?? JsonCodec.mapAt(m, 'residence')?['name'],
              '',
            ),
            room: JsonCodec.string(m['room'] ?? m['roomNumber']),
            status: JsonCodec.stringOr(m['status'], 'active'),
          );
        }(),
    ].where((c) => c.id.isNotEmpty).toList();

    final want = (selectedClientId ?? session.selectedClientId ?? '').trim();
    final selected = () {
      if (want.isNotEmpty) {
        for (final c in linkedClients) {
          if (c.id == want) return c;
        }
      }
      return linkedClients.isEmpty ? null : linkedClients.first;
    }();

    final residenceName = selected?.residenceName.isNotEmpty == true
        ? selected!.residenceName
        : (session.residenceName ?? 'Home');
    final careFacilityName =
        session.organizationName?.trim().isNotEmpty == true
            ? session.organizationName!
            : residenceName;

    session.applyFamilyHome(
      visibility: visibility,
      clientId: selected?.id,
      residenceName: residenceName,
    );

    final now = DateTime.now();
    final firstName = session.displayName.split(' ').first;
    final nextVisit = JsonCodec.mapAt(json, 'nextVisit') ??
        JsonCodec.mapAt(json, 'nextAppointment');
    final totals = JsonCodec.mapAt(json, 'totals') ?? {};
    final recent = _recentUpdate(updatesBody, visibility.dailyLogs);
    final journalMeta = _journalMeta(updatesBody);
    final shared = visibility.activities
        ? _sharedActivities(activitiesBody)
        : const <FamilySharedActivity>[];

    return FamilyDashboardOverview(
      residenceName: residenceName,
      careFacilityName: careFacilityName,
      dateLabel: IsoDateRange.formatDisplayDate(now),
      greetingLine: '${IsoDateRange.greetingPrefix(now)}, $firstName',
      greetingSubtitle: [
        if (selected?.room != null) 'Room ${selected!.room}',
        if (selected != null) selected.name,
        "Here's what's happening today.",
      ].where((part) => part.isNotEmpty).join(' · '),
      lastUpdatedLabel: 'Updated ${IsoDateRange.timeLabel(now)}',
      unreadNotificationCount:
          unreadNotificationCount ?? JsonCodec.integerOr(json['unreadCount'], 0),
      attentionAlerts: _alerts(json['alerts'], visibility),
      overviewStats: _totals(totals, visibility),
      nextAppointment: visibility.appointments ? _nextVisit(nextVisit) : null,
      recentUpdate: recent,
      glanceItems: _glance(recent, totals, visibility),
      quickActions: _actions(visibility),
      linkedClients: linkedClients,
      selectedClientId: selected?.id ?? '',
      careJournalActiveToday: journalMeta.activeToday,
      careJournalLastNoted: journalMeta.lastNoted,
      sharedActivities: shared,
    );
  }

  static ({bool activeToday, String? lastNoted}) _journalMeta(dynamic body) {
    final days = JsonCodec.unwrapList(body);
    String? lastNoted;
    var activeToday = false;
    final today = DateTime.now();
    for (final dayRaw in days.whereType<Map>()) {
      final day = JsonCodec.asMap(dayRaw);
      final logDate = JsonCodec.dateTime(day['logDate'] ?? day['date']);
      final entries = JsonCodec.listAt(day, 'entries');
      final activities = JsonCodec.listAt(day, 'activities');
      final hasContent = entries.isNotEmpty || activities.isNotEmpty;
      if (!hasContent) continue;
      lastNoted ??= logDate?.toIso8601String() ?? JsonCodec.string(day['logDate']);
      if (logDate != null &&
          logDate.year == today.year &&
          logDate.month == today.month &&
          logDate.day == today.day) {
        activeToday = true;
      }
    }
    return (activeToday: activeToday, lastNoted: lastNoted);
  }

  static List<FamilySharedActivity> _sharedActivities(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    return [
      for (final row in rows.whereType<Map>())
        () {
          final m = JsonCodec.asMap(row);
          final type = JsonCodec.stringOr(m['activityType'], 'activity');
          final at = JsonCodec.dateTime(
            m['activityDate'] ?? m['occurredAt'] ?? m['takenOn'],
          );
          final title = type.toLowerCase().contains('memory')
              ? 'Family memory'
              : type.replaceAll('_', ' ');
          return FamilySharedActivity(
            id: JsonCodec.stringOr(m['id'], ''),
            title: title,
            description: JsonCodec.stringOr(m['description'], ''),
            dateLabel: at == null
                ? JsonCodec.stringOr(m['activityDate'], '')
                : IsoDateRange.formatDisplayDate(at),
            activityType: type,
            mediaUrls: [
              for (final u in JsonCodec.listAt(m, 'mediaUrls'))
                if (u != null && '$u'.trim().isNotEmpty) '$u'.trim(),
            ],
          );
        }(),
    ].where((a) => a.id.isNotEmpty).toList();
  }

  static List<FamilyAttentionAlert> _alerts(
    dynamic raw,
    FamilyVisibility visibility,
  ) {
    final items = raw is List ? raw : JsonCodec.unwrapList(raw);
    return [
      for (final item in items)
        if (item is Map && _alertAllowed(JsonCodec.asMap(item), visibility))
          FamilyAttentionAlert(
            id: JsonCodec.stringOr(
              JsonCodec.asMap(item)['id'] ?? JsonCodec.asMap(item)['type'],
              'alert',
            ),
            title: JsonCodec.stringOr(
              JsonCodec.asMap(item)['title'] ??
                  JsonCodec.asMap(item)['message'],
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

  static bool _alertAllowed(
    Map<String, dynamic> json,
    FamilyVisibility visibility,
  ) {
    final type = (JsonCodec.string(
              json['type'] ?? json['category'] ?? json['kind'],
            ) ??
            '')
        .toLowerCase();
    final haystack = [
      type,
      JsonCodec.stringOr(json['title'], ''),
      JsonCodec.stringOr(json['message'], ''),
      JsonCodec.stringOr(json['subtitle'], ''),
      JsonCodec.stringOr(json['detail'], ''),
    ].join(' ').toLowerCase();

    if (_matchesAny(haystack, const ['incident', 'emergency', 'safeguard'])) {
      return visibility.incidents;
    }
    if (_matchesAny(haystack, const [
      'daily_log',
      'daily-log',
      'dailylog',
      'care note',
      'care_note',
    ])) {
      return visibility.dailyLogs;
    }
    if (_matchesAny(haystack, const ['med', 'mar', 'prescription'])) {
      return visibility.medications;
    }
    if (_matchesAny(haystack, const ['shift', 'staffing', 'roster'])) {
      return visibility.shiftUpdates;
    }
    if (_matchesAny(haystack, const ['activit'])) {
      return visibility.activities;
    }
    if (_matchesAny(haystack, const ['appointment', 'visit', 'next_visit'])) {
      return visibility.appointments;
    }
    if (_matchesAny(haystack, const ['document', 'file'])) {
      return visibility.documents;
    }
    if (_matchesAny(haystack, const ['message', 'conversation'])) {
      return visibility.messages;
    }
    if (_matchesAny(haystack, const [
      'medical_condition',
      'condition',
      'diagnosis',
    ])) {
      return visibility.medicalConditions;
    }
    return true;
  }

  static bool _matchesAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) return true;
    }
    return false;
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
          label: 'Care notes (7 days)',
          helperText: 'Shared care notes',
        ),
    ];
  }

  static FamilyNextAppointment? _nextVisit(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    final at = JsonCodec.dateTime(json['scheduledAt'] ?? json['startsAt']);
    final residence = JsonCodec.mapAt(json, 'residence') ?? {};
    return FamilyNextAppointment(
      id: JsonCodec.stringOr(json['id'], 'next-visit'),
      dateTimeLabel: at == null
          ? JsonCodec.stringOr(json['dateLabel'], '')
          : IsoDateRange.dateTimeLabel(at),
      title: JsonCodec.stringOr(
        json['title'] ?? json['type'] ?? json['purpose'],
        'Visit',
      ),
      location: JsonCodec.stringOr(
        json['location'] ?? residence['name'],
        '',
      ),
      statusLabel: JsonCodec.stringOr(json['status'], 'Upcoming'),
    );
  }

  static FamilyRecentUpdate? _recentUpdate(dynamic body, bool allowed) {
    if (!allowed) return null;
    final days = JsonCodec.unwrapList(body);
    for (final dayRaw in days.whereType<Map>()) {
      final day = JsonCodec.asMap(dayRaw);
      final entries = JsonCodec.listAt(day, 'entries');
      for (final entryRaw in entries.whereType<Map>()) {
        final json = JsonCodec.asMap(entryRaw);
        final author = JsonCodec.mapAt(json, 'author') ?? {};
        final name = IsoDateRange.personName(
          author.isEmpty ? json['authorName'] : author,
        );
        final at = JsonCodec.dateTime(
          json['occurredAt'] ?? json['createdAt'] ?? json['updatedAt'],
        );
        final bodyText = JsonCodec.stringOr(
          json['body'] ?? json['summary'] ?? json['notes'],
          '',
        ).trim();
        if (bodyText.isEmpty) continue;
        return FamilyRecentUpdate(
          id: JsonCodec.stringOr(json['id'], 'update'),
          authorName: name == 'Unknown' ? 'Care team' : name,
          authorInitials: IsoDateRange.initials(
            name == 'Unknown' ? 'CT' : name,
            fallback: 'CT',
          ),
          dateTimeLabel: at == null ? '' : IsoDateRange.dateTimeLabel(at),
          statusLabel: 'Care Note',
          body: bodyText,
          hasImage: false,
        );
      }
    }
    return null;
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
        const FamilyGlanceItem(
          id: 'visits',
          label: 'Next visit',
          value: 'See card',
        ),
      if (recent != null)
        FamilyGlanceItem(
          id: 'latest',
          label: 'Latest note',
          value: recent.authorName,
        ),
    ];
  }

  static List<FamilyQuickAction> _actions(FamilyVisibility visibility) {
    return [
      if (visibility.appointments)
        const FamilyQuickAction(
          id: 'request-visit',
          label: 'Book\nVisit',
          asset: 'assets/icons/family_core/request.svg',
        ),
      if (visibility.messages)
        const FamilyQuickAction(
          id: 'send-message',
          label: 'Message\nStaff',
          asset: 'assets/icons/family_core/message.svg',
        ),
      const FamilyQuickAction(
        id: 'care-journal',
        label: 'Care\nJournal',
        asset: 'assets/icons/family_core/activities.svg',
      ),
      const FamilyQuickAction(
        id: 'plan-outing',
        label: 'Plan\nOuting',
        asset: 'assets/icons/family_core/image.svg',
      ),
      if (visibility.documents)
        const FamilyQuickAction(
          id: 'view-documents',
          label: 'Documents',
          asset: 'assets/icons/family_core/document.svg',
        ),
    ];
  }

  const FamilyHomeMapper._();
}
