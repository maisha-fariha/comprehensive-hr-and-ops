import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../common/inbox/data/mappers/portal_inbox_mapper.dart';
import '../../domain/entities/attention_alert.dart';
import '../../domain/entities/dashboard_enums.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/entities/overview_stat.dart';

abstract final class DashboardOverviewMapper {
  static DashboardOverview compose({
    required UserSession session,
    required dynamic dashboardBody,
    required dynamic alertsBody,
    required dynamic shiftsBody,
    required dynamic notificationsBody,
  }) {
    final dashboard = JsonCodec.unwrapMap(dashboardBody);
    final kpis = JsonCodec.mapAt(dashboard, 'kpis') ?? dashboard;
    final now = DateTime.now();
    final firstName = session.displayName.split(' ').first;

    return DashboardOverview(
      organizationName: session.organizationName ??
          JsonCodec.string(dashboard['residenceName']) ??
          JsonCodec.string(dashboard['organizationName']) ??
          'Residence',
      dateLabel: IsoDateRange.formatDisplayDate(now),
      greetingLine: '${IsoDateRange.greetingPrefix(now)}, $firstName 👋',
      greetingSubtitle: "Here's what's happening today.",
      lastUpdatedLabel: 'Updated ${IsoDateRange.timeLabel(now)}',
      unreadNotificationCount: _unreadCount(notificationsBody),
      unresolvedAlertCount: JsonCodec.integerOr(
        kpis['criticalAlertCount'] ?? dashboard['criticalAlertCount'],
        _alerts(alertsBody).length,
      ),
      avatarInitials: session.avatarInitials.isEmpty
          ? 'ME'
          : session.avatarInitials,
      attentionAlerts: _alerts(alertsBody),
      overviewStats: _stats(kpis),
      scheduleShifts: const [],
      quickActions: const [],
    );
  }

  static List<AttentionAlert> _alerts(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .where(_isActionableSeverity)
        .map((json) {
          final severity = _alertSeverity(json);
          return AttentionAlert(
            id: JsonCodec.stringOr(json['id'], json.hashCode.toString()),
            title: JsonCodec.stringOr(
              json['title'] ?? json['message'] ?? json['name'],
              'Needs attention',
            ),
            subtitle: JsonCodec.stringOr(
              json['subtitle'] ?? json['description'] ?? json['detail'],
              _alertFallbackSubtitle(json, severity),
            ),
            severity: severity,
          );
        })
        .toList();
  }

  static bool _isActionableSeverity(Map<String, dynamic> json) {
    final raw = (JsonCodec.string(json['severity']) ??
            JsonCodec.string(json['level']) ??
            '')
        .toLowerCase();
    if (raw.isEmpty) return false;
    return raw.contains('critical') || raw.contains('high');
  }

  static AlertSeverity _alertSeverity(Map<String, dynamic> json) {
    final raw = (JsonCodec.string(json['severity']) ??
            JsonCodec.string(json['level']) ??
            '')
        .toLowerCase();
    if (raw.contains('critical')) return AlertSeverity.critical;
    // high (and any other included severity) uses the urgent chrome.
    return AlertSeverity.urgent;
  }

  static String _alertFallbackSubtitle(
    Map<String, dynamic> json,
    AlertSeverity severity,
  ) {
    final label =
        severity == AlertSeverity.critical ? 'Critical' : 'High severity';
    final when = JsonCodec.string(json['createdAt']) ??
        JsonCodec.string(json['updatedAt']) ??
        JsonCodec.string(json['timeAgo']);
    if (when == null) return label;
    return '$label · $when';
  }

  static List<OverviewStat> _stats(Map<String, dynamic> kpis) {
    final pendingApprovals = JsonCodec.integer(kpis['pendingApprovals']) ??
        (JsonCodec.integerOr(kpis['pendingAttendanceClaims'], 0) +
            JsonCodec.integerOr(kpis['tasksAwaitingReview'], 0));

    return [
      OverviewStat(
        id: 'staff-on-duty',
        tag: StatTag.active,
        value: '${JsonCodec.integerOr(kpis['staffOnDuty'] ?? kpis['activeStaff'], 0)}',
        label: 'Staff On Duty',
        helperText: 'On shift now',
        isHelperTextPositive: true,
      ),
      OverviewStat(
        id: 'open-incidents',
        tag: StatTag.urgent,
        value: '${JsonCodec.integerOr(kpis['openIncidents'], 0)}',
        label: 'Open Incidents',
        helperText: 'High priority',
      ),
      OverviewStat(
        id: 'medications-due',
        tag: StatTag.due,
        value: _nullableCount(kpis['medicationsDue']),
        label: 'Medications Due',
        helperText: 'Due within 4 hours',
      ),
      OverviewStat(
        id: 'pending-approvals',
        tag: StatTag.review,
        value: '$pendingApprovals',
        label: 'Pending Approvals',
        helperText: 'Requires your action',
      ),
      OverviewStat(
        id: 'tasks-due',
        tag: StatTag.today,
        value: '${JsonCodec.integerOr(kpis['tasksDueToday'] ?? kpis['openTasks'], 0)}',
        label: 'Tasks Due',
        helperText: 'Due today',
      ),
      OverviewStat(
        id: 'attendance-alerts',
        tag: StatTag.flagged,
        value: '${JsonCodec.integerOr(kpis['attendanceAlerts'], 0)}',
        label: 'Attendance Alerts',
        helperText: 'Late + missed today',
      ),
    ];
  }

  static String _nullableCount(dynamic value) {
    final parsed = JsonCodec.integer(value);
    return parsed == null ? '—' : '$parsed';
  }

  static int _unreadCount(dynamic body) {
    final meta = JsonCodec.metaOf(body);
    final fromMeta = JsonCodec.integer(
      meta?['unreadCount'] ?? meta?['unread'],
    );
    if (fromMeta != null) return fromMeta;
    return JsonCodec.unwrapList(body).where((item) {
      if (item is! Map) return false;
      return !PortalInboxMapper.isNotificationRead(JsonCodec.asMap(item));
    }).length;
  }

  const DashboardOverviewMapper._();
}
