import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/attention_alert.dart';
import '../../domain/entities/dashboard_enums.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/entities/overview_stat.dart';
import '../../domain/entities/quick_action.dart';
import '../../domain/entities/schedule_shift.dart';

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
      scheduleShifts: _shifts(shiftsBody),
      quickActions: const [
        QuickAction(type: QuickActionType.createShift, label: 'Create Shift'),
        QuickAction(type: QuickActionType.approve, label: 'Approve'),
        QuickAction(type: QuickActionType.logNote, label: 'Log Note'),
        QuickAction(type: QuickActionType.message, label: 'Message'),
      ],
    );
  }

  static List<AttentionAlert> _alerts(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .where(_isHighSeverity)
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

  static bool _isHighSeverity(Map<String, dynamic> json) {
    final raw = (JsonCodec.string(json['severity']) ??
            JsonCodec.string(json['level']) ??
            '')
        .toLowerCase();
    if (raw.isEmpty) return true;
    return raw.contains('critical') ||
        raw.contains('high') ||
        raw.contains('urgent');
  }

  static AlertSeverity _alertSeverity(Map<String, dynamic> json) {
    final raw = (JsonCodec.string(json['severity']) ??
            JsonCodec.string(json['level']) ??
            '')
        .toLowerCase();
    if (raw.contains('critical')) return AlertSeverity.critical;
    return AlertSeverity.urgent;
  }

  static String _alertFallbackSubtitle(
    Map<String, dynamic> json,
    AlertSeverity severity,
  ) {
    final label =
        severity == AlertSeverity.critical ? 'High severity' : 'Urgent';
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

  static List<ScheduleShift> _shifts(dynamic body) {
    final grouped = <ShiftPeriod, _ShiftBucket>{
      ShiftPeriod.morning: _ShiftBucket(
        name: 'Morning Shift',
        timeRange: '7:00 AM – 3:00 PM',
      ),
      ShiftPeriod.evening: _ShiftBucket(
        name: 'Evening Shift',
        timeRange: '3:00 PM – 11:00 PM',
      ),
      ShiftPeriod.night: _ShiftBucket(
        name: 'Night Shift',
        timeRange: '11:00 PM – 7:00 AM',
      ),
    };

    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final period = _periodOf(json);
      final bucket = grouped[period]!;
      bucket.ids.add(JsonCodec.stringOr(json['id'], period.name));
      bucket.staffCount += _staffCount(json);
    }

    final periods = ShiftPeriod.values;
    return [
      for (var i = 0; i < periods.length; i++)
        ScheduleShift(
          id: grouped[periods[i]]!.ids.isEmpty
              ? periods[i].name
              : grouped[periods[i]]!.ids.first,
          period: periods[i],
          name: grouped[periods[i]]!.name,
          timeRange: grouped[periods[i]]!.timeRange,
          staffCount: grouped[periods[i]]!.staffCount,
          showTimelineDivider: i < periods.length - 1,
        ),
    ];
  }

  static ShiftPeriod _periodOf(Map<String, dynamic> json) {
    final raw = (JsonCodec.string(json['period']) ??
            JsonCodec.string(json['shiftType']) ??
            JsonCodec.string(json['type']) ??
            JsonCodec.string(json['name']) ??
            '')
        .toLowerCase();
    if (raw.contains('night')) return ShiftPeriod.night;
    if (raw.contains('evening') || raw.contains('afternoon')) {
      return ShiftPeriod.evening;
    }
    if (raw.contains('morning')) return ShiftPeriod.morning;

    final start = JsonCodec.dateTime(
      json['startAt'] ??
          json['startsAt'] ??
          json['startTime'] ??
          json['from'] ??
          json['start'],
    );
    if (start != null) {
      final hour = start.toLocal().hour;
      if (hour >= 15 && hour < 23) return ShiftPeriod.evening;
      if (hour >= 23 || hour < 7) return ShiftPeriod.night;
    }
    return ShiftPeriod.morning;
  }

  static int _staffCount(Map<String, dynamic> json) {
    final direct = JsonCodec.integer(
      json['assignedCount'] ??
          json['staffCount'] ??
          json['staffed'] ??
          json['filled'],
    );
    if (direct != null) return direct;
    final assignments = json['assignments'];
    if (assignments is List) return assignments.length;
    return JsonCodec.integerOr(json['requiredCount'], 0) > 0 ? 0 : 1;
  }

  static int _unreadCount(dynamic body) {
    final meta = JsonCodec.metaOf(body);
    final fromMeta = JsonCodec.integer(
      meta?['unreadCount'] ?? meta?['unread'],
    );
    if (fromMeta != null) return fromMeta;
    return JsonCodec.unwrapList(body).where((item) {
      if (item is! Map) return false;
      final json = JsonCodec.asMap(item);
      final read = JsonCodec.boolean(json['read'] ?? json['isRead']);
      return read != true;
    }).length;
  }

  const DashboardOverviewMapper._();
}

class _ShiftBucket {
  final String name;
  final String timeRange;
  final List<String> ids = [];
  int staffCount = 0;

  _ShiftBucket({required this.name, required this.timeRange});
}
