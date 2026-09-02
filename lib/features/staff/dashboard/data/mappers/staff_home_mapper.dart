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
          JsonCodec.string(json['residenceId']),
      residenceName: JsonCodec.string(shift['residenceName']) ??
          JsonCodec.string(json['residenceName']),
    );

    final onShift = JsonCodec.boolean(attendance['onShift']) ?? false;
    final onBreak = JsonCodec.boolean(attendance['onBreak']) ?? false;

    return StaffDashboardOverview(
      organizationName: session.organizationName ??
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
      ),
      overviewStats: _stats(
        onShift: onShift,
        onBreak: onBreak,
        tiles: tiles,
      ),
      alertCount: JsonCodec.integerOr(tiles['alerts'], 0),
      alertLabel: 'Alerts',
      quickActions: const [
        StaffQuickAction(
          id: 'log-task',
          asset: AppAssets.notePencil,
          label: 'Log Task',
        ),
        StaffQuickAction(
          id: 'message',
          asset: AppAssets.messageCircle,
          label: 'Message',
        ),
        StaffQuickAction(
          id: 'mark-done',
          asset: AppAssets.checkCircle,
          label: 'Mark Done',
        ),
      ],
    );
  }

  static String _shiftRange(Map<String, dynamic> shift) {
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
