import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_dashboard_enums.dart';
import '../../domain/entities/staff_dashboard_overview.dart';
import '../../domain/entities/staff_overview_stat.dart';
import '../../domain/entities/staff_quick_action.dart';
import '../../domain/entities/today_shift_summary.dart';

abstract final class StaffHomeMapper {
  /// `/mobile/home` can keep a missed row (`checkInAt: null`) while the
  /// attendance list already has an open punch. The web clock button follows
  /// that punch, so Home must too.
  static void applyOpenPunch(Map<String, dynamic> home, Map<String, dynamic>? open) {
    if (open == null) return;
    final checkIn = JsonCodec.dateTime(open['checkInAt'] ?? open['clockInAt']);
    if (checkIn == null) return;
    final checkOut = JsonCodec.dateTime(open['checkOutAt'] ?? open['clockOutAt']);
    if (checkOut != null) return;
    final attendance = Map<String, dynamic>.from(
      JsonCodec.mapAt(home, 'attendance') ?? const {},
    );
    attendance['checkInAt'] = open['checkInAt'] ?? open['clockInAt'];
    attendance['checkOutAt'] = null;
    attendance['onShift'] = true;
    attendance['onBreak'] = open['onBreak'] ?? false;
    final residenceId = JsonCodec.string(open['residenceId']);
    if (residenceId != null) attendance['residenceId'] = residenceId;
    final residence = open['residence'];
    if (residence != null) attendance['residence'] = residence;
    home['attendance'] = attendance;
  }

  static StaffDashboardOverview compose({
    required UserSession session,
    required dynamic body,
    int? unreadNotificationCount,
    DateTime? now,
  }) {
    final json = JsonCodec.unwrapMap(body);
    final tiles = JsonCodec.mapAt(json, 'tiles') ?? {};
    final attendance = JsonCodec.mapAt(json, 'attendance') ?? {};
    final shift = JsonCodec.mapAt(json, 'shift') ?? {};
    final clock = now ?? DateTime.now();
    final firstName = session.displayName.split(' ').first;

    session.applyPermissions(
      JsonCodec.listAt(json, 'permissions').map((item) => item.toString()),
    );
    session.applyStaffContext(
      staffId: JsonCodec.string(json['staffId']),
      residenceId: JsonCodec.string(shift['residenceId']) ??
          JsonCodec.string(attendance['residenceId']) ??
          JsonCodec.string(JsonCodec.mapAt(attendance, 'residence')?['id']) ??
          JsonCodec.string(json['residenceId']),
      residenceName: JsonCodec.string(shift['residenceName']) ??
          JsonCodec.string(JsonCodec.mapAt(attendance, 'residence')?['name']) ??
          JsonCodec.string(json['residenceName']),
      replace: true,
    );

    // `/mobile/home` also reports `onShift: true` for a missed record that was
    // never clocked into; check-out then 404s. Clock out only for a real
    // open punch. A shift whose hours cover now is still "On Shift" so the
    // person can clock in.
    final checkIn = JsonCodec.dateTime(attendance['checkInAt']);
    final neverClockedIn =
        attendance.containsKey('checkInAt') && checkIn == null;
    final clockedOut = JsonCodec.dateTime(attendance['checkOutAt']) != null;
    final reportedOnShift = JsonCodec.boolean(attendance['onShift']) ?? false;
    final clockedIn = (checkIn != null && !clockedOut) ||
        (reportedOnShift && !neverClockedIn && !clockedOut);
    final clockOpen =
        JsonCodec.boolean(shift['clockOpen']) ?? _coversNow(shift, clock);
    final inShift = clockedIn || clockOpen;
    final onBreak =
        clockedIn && (JsonCodec.boolean(attendance['onBreak']) ?? false);
    final clients = _tileInt(tiles, 'clients');
    final tasksDue = _tileInt(tiles, 'tasksDue');
    final medsDue = _tileInt(tiles, 'medicationsDue');
    final alerts = _tileInt(tiles, 'alerts') ?? 0;

    return StaffDashboardOverview(
      organizationName: session.organizationName ??
          session.residenceName ??
          JsonCodec.string(shift['residenceName']) ??
          'Residence',
      dateLabel: IsoDateRange.formatDisplayDate(clock),
      greetingLine: '${IsoDateRange.greetingPrefix(clock)}, $firstName 👋',
      greetingSubtitle: "Here's what's happening on your shift.",
      unreadNotificationCount: unreadNotificationCount ??
          JsonCodec.integerOr(json['unreadCount'], 0),
      todayShift: TodayShiftSummary(
        statusLabel: onBreak
            ? 'On Break'
            : inShift
                ? 'On Shift'
                : 'Off Shift',
        dateLabel: IsoDateRange.formatMonthDay(clock),
        timeRange: _shiftRange(shift),
        onShift: inShift,
        clockedIn: clockedIn,
        onBreak: onBreak,
        shiftId: JsonCodec.string(shift['id'] ?? shift['shiftId']),
        residenceId: session.residenceId,
        clockOpen: clockOpen || clockedIn,
        startsAt: JsonCodec.dateTime(
          shift['startAt'] ?? shift['startsAt'] ?? shift['startTime'] ?? shift['from'],
        ),
        endsAt: JsonCodec.dateTime(
          shift['endAt'] ?? shift['endsAt'] ?? shift['endTime'] ?? shift['to'],
        ),
      ),
      overviewStats: _stats(
        onShift: inShift,
        onBreak: onBreak,
        tiles: tiles,
      ),
      alertCount: alerts,
      alertLabel: 'Alerts',
      quickActions: _quickActions(
        onShift: inShift,
        clients: clients,
        tasksDue: tasksDue,
        medsDue: medsDue,
        canClock: session.can('attendance:write'),
        canDailyLogs: session.can('daily-logs'),
        canAccessMar: session.canAccessMar,
        canTasks: session.can('tasks'),
      ),
    );
  }

  static List<StaffQuickAction> _quickActions({
    required bool onShift,
    required int? clients,
    required int? tasksDue,
    required int? medsDue,
    required bool canClock,
    required bool canDailyLogs,
    required bool canAccessMar,
    required bool canTasks,
  }) {
    return [
      if (canClock)
        StaffQuickAction(
          id: 'clock-in-out',
          asset: AppAssets.clock,
          label: 'Clock In / Out',
          subtitle: 'Tap to manage your shift',
          trailing: onShift ? 'On Shift' : 'Off Shift',
        ),
      if (canDailyLogs)
        StaffQuickAction(
          id: 'daily-logs',
          asset: 'assets/icons/team_reports/team_doc.svg',
          label: 'Start Daily Logs',
          subtitle: 'Record client daily notes',
          trailing: clients == null ? '' : '$clients Clients',
        ),
      if (canAccessMar)
        StaffQuickAction(
          id: 'medication-mar',
          asset: 'assets/icons/staff_core/medication_due.svg',
          label: 'Medication MAR',
          subtitle: 'Administer & record meds',
          trailing: medsDue == null ? '' : '$medsDue Due',
        ),
      if (canTasks)
        StaffQuickAction(
          id: 'my-tasks',
          asset: 'assets/icons/staff_core/tasks_due.svg',
          label: 'My Tasks',
          subtitle: 'View assigned tasks',
          trailing: tasksDue == null ? '' : '$tasksDue Due',
        ),
    ];
  }

  static int? _tileInt(Map<String, dynamic> tiles, String key) {
    if (!tiles.containsKey(key) || tiles[key] == null) return null;
    return JsonCodec.integerOr(tiles[key], 0);
  }

  /// True when [now] falls inside the scheduled shift, compared as instants.
  static bool _coversNow(Map<String, dynamic> shift, DateTime now) {
    final start = JsonCodec.dateTime(
      shift['startAt'] ?? shift['startsAt'] ?? shift['startTime'] ?? shift['from'],
    );
    final end = JsonCodec.dateTime(
      shift['endAt'] ?? shift['endsAt'] ?? shift['endTime'] ?? shift['to'],
    );
    if (start == null || end == null) return false;
    final instant = now.toUtc();
    return !instant.isBefore(start.toUtc()) && !instant.isAfter(end.toUtc());
  }

  static String _shiftRange(Map<String, dynamic> shift) {
    if (shift.isEmpty) return 'No shift today';
    final start = JsonCodec.dateTime(
      shift['startAt'] ?? shift['startsAt'] ?? shift['startTime'] ?? shift['from'],
    );
    final end = JsonCodec.dateTime(
      shift['endAt'] ?? shift['endsAt'] ?? shift['endTime'] ?? shift['to'],
    );
    final labeled = IsoDateRange.rangeLabel(start, end);
    if (labeled.isNotEmpty) return labeled;
    return JsonCodec.stringOr(shift['timeRange'] ?? shift['label'], 'No shift today');
  }

  static List<StaffOverviewStat> _stats({
    required bool onShift,
    required bool onBreak,
    required Map<String, dynamic> tiles,
  }) {
    final stats = <StaffOverviewStat>[
      StaffOverviewStat(
        id: 'on-shift',
        tag: StaffStatTag.onShift,
        value: onBreak
            ? 'On Break'
            : onShift
                ? 'On Shift'
                : 'Off Shift',
        label: 'My Shift',
      ),
    ];

    // B1 map tiles — null values are hidden (role-aware home payload).
    _addTile(stats, tiles, 'clients', StaffStatTag.clients, 'Clients Assigned');
    _addTile(stats, tiles, 'tasksDue', StaffStatTag.tasks, 'Tasks Due');
    _addTile(
      stats,
      tiles,
      'medicationsDue',
      StaffStatTag.medications,
      'Medications Due',
    );
    return stats;
  }

  static void _addTile(
    List<StaffOverviewStat> stats,
    Map<String, dynamic> tiles,
    String key,
    StaffStatTag tag,
    String label,
  ) {
    if (!tiles.containsKey(key) || tiles[key] == null) return;
    stats.add(
      StaffOverviewStat(
        id: key,
        tag: tag,
        value: '${JsonCodec.integerOr(tiles[key], 0)}',
        label: label,
      ),
    );
  }

  const StaffHomeMapper._();
}
