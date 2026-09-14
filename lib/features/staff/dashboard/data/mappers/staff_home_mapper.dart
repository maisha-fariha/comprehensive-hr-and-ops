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
  static StaffDashboardOverview compose({
    required UserSession session,
    required dynamic body,
    int? unreadNotificationCount,
  }) {
    final json = JsonCodec.unwrapMap(body);
    final tiles = JsonCodec.mapAt(json, 'tiles') ?? {};
    final attendance = JsonCodec.mapAt(json, 'attendance') ?? {};
    final shift = JsonCodec.mapAt(json, 'shift') ?? {};
    final now = DateTime.now();
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

    final onShift = JsonCodec.boolean(attendance['onShift']) ?? false;
    final onBreak = JsonCodec.boolean(attendance['onBreak']) ?? false;
    final clients = _tileInt(tiles, 'clients');
    final tasksDue = _tileInt(tiles, 'tasksDue');
    final medsDue = _tileInt(tiles, 'medicationsDue');
    final alerts = _tileInt(tiles, 'alerts') ?? 0;

    return StaffDashboardOverview(
      organizationName: session.organizationName ??
          session.residenceName ??
          JsonCodec.string(shift['residenceName']) ??
          'Residence',
      dateLabel: IsoDateRange.formatDisplayDate(now),
      greetingLine: '${IsoDateRange.greetingPrefix(now)}, $firstName 👋',
      greetingSubtitle: "Here's what's happening on your shift.",
      unreadNotificationCount: unreadNotificationCount ??
          JsonCodec.integerOr(json['unreadCount'], 0),
      todayShift: TodayShiftSummary(
        statusLabel: onBreak
            ? 'On Break'
            : onShift
                ? 'On Shift'
                : 'Off Shift',
        dateLabel: IsoDateRange.formatMonthDay(now),
        timeRange: _shiftRange(shift),
        onShift: onShift,
        onBreak: onBreak,
        shiftId: JsonCodec.string(shift['id'] ?? shift['shiftId']),
        residenceId: session.residenceId,
      ),
      overviewStats: _stats(
        onShift: onShift,
        onBreak: onBreak,
        tiles: tiles,
      ),
      alertCount: alerts,
      alertLabel: 'Alerts',
      quickActions: _quickActions(
        onShift: onShift,
        clients: clients,
        tasksDue: tasksDue,
        medsDue: medsDue,
        canAccessClients: session.canAccessClients,
        canAccessMar: session.canAccessMar,
      ),
    );
  }

  static List<StaffQuickAction> _quickActions({
    required bool onShift,
    required int? clients,
    required int? tasksDue,
    required int? medsDue,
    required bool canAccessClients,
    required bool canAccessMar,
  }) {
    return [
      StaffQuickAction(
        id: 'clock-in-out',
        asset: AppAssets.clock,
        label: 'Clock In / Out',
        subtitle: 'Tap to manage your shift',
        trailing: onShift ? 'On Shift' : 'Off Shift',
      ),
      if (canAccessClients)
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
