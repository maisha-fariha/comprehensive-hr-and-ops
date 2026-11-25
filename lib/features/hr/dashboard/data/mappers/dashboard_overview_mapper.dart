import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/network/notification_unread.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../common/inbox/data/mappers/portal_inbox_mapper.dart';
import '../../../../staff/dashboard/domain/entities/today_shift_summary.dart';
import '../../domain/entities/attention_alert.dart';
import '../../domain/entities/dashboard_enums.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/entities/overview_stat.dart';
import '../../domain/entities/quick_action.dart';

abstract final class DashboardOverviewMapper {
  static DashboardOverview compose({
    required UserSession session,
    required dynamic dashboardBody,
    required dynamic alertsBody,
    required dynamic shiftsBody,
    required dynamic notificationsBody,
    dynamic myAttendanceBody,
    dynamic myShiftsBody,
  }) {
    final dashboard = JsonCodec.unwrapMap(dashboardBody);
    final kpis = JsonCodec.mapAt(dashboard, 'kpis') ?? dashboard;
    final now = DateTime.now();
    final firstName = session.displayName.split(' ').first;
    final todayShift = todayShiftFrom(
      attendanceBody: myAttendanceBody,
      shiftsBody: myShiftsBody,
      now: now,
      fallbackResidenceId: session.residenceId,
    );

    return DashboardOverview(
      organizationName: session.organizationName ??
          JsonCodec.string(dashboard['organizationName']) ??
          JsonCodec.string(dashboard['tenantName']) ??
          JsonCodec.string(dashboard['residenceName']) ??
          'Organisation',
      dateLabel: IsoDateRange.formatDisplayDate(now),
      greetingLine: '${IsoDateRange.greetingPrefix(now)}, $firstName 👋',
      greetingSubtitle: todayShift.onShift
          ? "Here's what's happening on your shift."
          : "Here's what's happening today.",
      lastUpdatedLabel: 'Updated ${IsoDateRange.timeLabel(now)}',
      unreadNotificationCount: _unreadCount(notificationsBody),
      unresolvedAlertCount: JsonCodec.integerOr(
        kpis['criticalAlertCount'] ?? dashboard['criticalAlertCount'],
        _alerts(alertsBody).length,
      ),
      avatarInitials: session.avatarInitials.isEmpty
          ? 'ME'
          : session.avatarInitials,
      todayShift: todayShift,
      attentionAlerts: _alerts(alertsBody),
      overviewStats: _stats(kpis),
      scheduleShifts: const [],
      quickActions: _defaultQuickActions,
    );
  }

  /// Personal "Today's Shift" for HR Home — same card staff sees, from
  /// `GET /attendance?mine=true` + `GET /shifts?staffId=…`.
  static TodayShiftSummary todayShiftFrom({
    required dynamic attendanceBody,
    required dynamic shiftsBody,
    required DateTime now,
    String? fallbackResidenceId,
  }) {
    Map<String, dynamic>? openPunch;
    DateTime? checkInAt;
    for (final item in JsonCodec.unwrapList(attendanceBody)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final inAt = JsonCodec.dateTime(json['checkInAt'] ?? json['clockInAt']);
      if (inAt == null) continue;
      if (JsonCodec.dateTime(json['checkOutAt'] ?? json['clockOutAt']) != null) {
        continue;
      }
      openPunch = json;
      checkInAt = inAt;
      break;
    }

    Map<String, dynamic>? shiftJson;
    DateTime? startsAt;
    DateTime? endsAt;
    String? shiftId;
    String? residenceId;

    if (openPunch != null) {
      final nested = JsonCodec.mapAt(openPunch, 'shift') ?? const {};
      shiftId = JsonCodec.string(
        openPunch['shiftId'] ?? nested['id'] ?? nested['shiftId'],
      );
      residenceId = JsonCodec.string(
            openPunch['residenceId'] ??
                JsonCodec.mapAt(openPunch, 'residence')?['id'],
          ) ??
          fallbackResidenceId;
      startsAt = JsonCodec.dateTime(
        nested['startsAt'] ?? nested['startAt'] ?? nested['startTime'],
      );
      endsAt = JsonCodec.dateTime(
        nested['endsAt'] ?? nested['endAt'] ?? nested['endTime'],
      );
      if (startsAt != null || endsAt != null) shiftJson = nested;
    }

    if (shiftJson == null || startsAt == null || endsAt == null) {
      for (final item in JsonCodec.unwrapList(shiftsBody)) {
        if (item is! Map) continue;
        final json = JsonCodec.asMap(item);
        if (JsonCodec.string(json['status']) == 'cancelled') continue;
        final id = JsonCodec.string(json['id']);
        final start = JsonCodec.dateTime(json['startsAt'] ?? json['startAt']);
        final end = JsonCodec.dateTime(json['endsAt'] ?? json['endAt']);
        if (id == null || start == null || end == null) continue;
        final openAt = start.subtract(const Duration(minutes: 15));
        final covers = !now.toUtc().isBefore(openAt.toUtc()) &&
            !now.toUtc().isAfter(end.toUtc());
        final isOpenPunchShift = shiftId != null && shiftId == id;
        if (!covers && !isOpenPunchShift && openPunch == null) {
          // Prefer current/next window when not punched in.
          if (start.toUtc().isBefore(now.toUtc())) continue;
        }
        if (covers || isOpenPunchShift || (openPunch != null && shiftId == null)) {
          shiftJson = json;
          shiftId ??= id;
          startsAt ??= start;
          endsAt ??= end;
          residenceId ??= JsonCodec.string(
                json['residenceId'] ??
                    JsonCodec.mapAt(json, 'residence')?['id'],
              ) ??
              fallbackResidenceId;
          if (covers || isOpenPunchShift) break;
        }
      }
    }

    // Fallback: first non-cancelled shift in the window if still empty.
    if (shiftJson == null) {
      for (final item in JsonCodec.unwrapList(shiftsBody)) {
        if (item is! Map) continue;
        final json = JsonCodec.asMap(item);
        if (JsonCodec.string(json['status']) == 'cancelled') continue;
        final id = JsonCodec.string(json['id']);
        final start = JsonCodec.dateTime(json['startsAt'] ?? json['startAt']);
        final end = JsonCodec.dateTime(json['endsAt'] ?? json['endAt']);
        if (id == null || start == null || end == null) continue;
        shiftJson = json;
        shiftId = id;
        startsAt = start;
        endsAt = end;
        residenceId ??= JsonCodec.string(
              json['residenceId'] ??
                  JsonCodec.mapAt(json, 'residence')?['id'],
            ) ??
            fallbackResidenceId;
        break;
      }
    }

    final punch = openPunch;
    final clockedIn = punch != null;
    final onBreak =
        clockedIn && JsonCodec.dateTime(punch['breakStartedAt']) != null;
    final rosterOpen = startsAt != null &&
        endsAt != null &&
        !now.toUtc().isBefore(
              startsAt.subtract(const Duration(minutes: 15)).toUtc(),
            ) &&
        !now.toUtc().isAfter(endsAt.toUtc());
    final inShift = clockedIn || rosterOpen;
    final range = IsoDateRange.rangeLabel(startsAt, endsAt);
    final timeRange = range.isNotEmpty
        ? range
        : (clockedIn
            ? (checkInAt != null
                ? 'In since ${IsoDateRange.timeLabel(checkInAt)}'
                : 'On shift')
            : 'No shift today');

    return TodayShiftSummary(
      statusLabel: onBreak
          ? 'On Break'
          : inShift
              ? 'On Shift'
              : 'Off Shift',
      dateLabel: IsoDateRange.formatMonthDay(now),
      timeRange: timeRange,
      onShift: inShift,
      clockedIn: clockedIn,
      onBreak: onBreak,
      shiftId: shiftId,
      residenceId: residenceId ?? fallbackResidenceId,
      clockOpen: rosterOpen || clockedIn,
      startsAt: startsAt,
      endsAt: endsAt,
    );
  }

  static const List<QuickAction> _defaultQuickActions = [
    QuickAction(type: QuickActionType.createShift, label: 'Create Shift'),
    QuickAction(type: QuickActionType.approve, label: 'Approve'),
    QuickAction(type: QuickActionType.logNote, label: 'Log Note'),
    QuickAction(type: QuickActionType.message, label: 'Message'),
  ];

  static List<AttentionAlert> _alerts(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .where(_isActionableSeverity)
        .map((json) {
          final severity = _alertSeverity(json);
          final meta = JsonCodec.mapAt(json, 'meta') ?? const <String, dynamic>{};
          return AttentionAlert(
            id: JsonCodec.stringOr(
              json['id'] ??
                  meta['incidentId'] ??
                  meta['documentId'] ??
                  json.hashCode.toString(),
              json.hashCode.toString(),
            ),
            title: JsonCodec.stringOr(
              json['title'] ?? json['message'] ?? json['name'],
              'Needs attention',
            ),
            subtitle: JsonCodec.stringOr(
              json['subtitle'] ?? json['description'] ?? json['detail'],
              _alertFallbackSubtitle(json, severity),
            ),
            severity: severity,
            type: JsonCodec.string(json['type'] ?? json['kind']),
            meta: meta,
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
    final pageUnread = JsonCodec.unwrapList(body).where((item) {
      if (item is! Map) return false;
      return !PortalInboxMapper.isNotificationRead(JsonCodec.asMap(item));
    }).length;
    return NotificationUnread.fromBody(body, pageUnread: pageUnread);
  }

  const DashboardOverviewMapper._();
}
