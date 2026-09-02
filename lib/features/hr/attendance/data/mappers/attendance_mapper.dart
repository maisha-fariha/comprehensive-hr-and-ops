import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../attendance_assets.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_overview.dart';
import '../../domain/entities/attendance_stat.dart';
import '../../domain/entities/late_arrival_entry.dart';
import '../../domain/entities/missed_clock_in_entry.dart';
import '../../domain/entities/overtime_entry.dart';
import '../../domain/entities/staff_status_entry.dart';

abstract final class AttendanceMapper {
  static AttendanceOverview compose({
    required dynamic attendanceBody,
    required dynamic overtimeBody,
    required dynamic residenceBody,
    required String? fallbackResidenceName,
  }) {
    final rows = JsonCodec.unwrapList(attendanceBody)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();
    final late = rows.where((row) => _status(row) == StaffAttendanceStatus.late).toList();
    final missed =
        rows.where((row) => _status(row) == StaffAttendanceStatus.missed).toList();
    final onTime =
        rows.where((row) => _status(row) == StaffAttendanceStatus.onTime).toList();
    final onDuty = onTime.length + late.length;
    final otRows = JsonCodec.unwrapList(overtimeBody)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();
    final otMeta = JsonCodec.metaOf(overtimeBody) ?? {};
    final summary = JsonCodec.mapAt(otMeta, 'summary') ?? otMeta;
    final policy = JsonCodec.mapAt(otMeta, 'policy') ?? {};
    final weeklyLimit = JsonCodec.number(policy['weeklyLimitHours']) ?? 48;
    final approaching = otRows.where((row) => _otStatus(row) == OvertimeStatus.approaching);
    final exceeded = otRows.where((row) => _otStatus(row) == OvertimeStatus.exceeded);

    final residence = JsonCodec.unwrapMap(residenceBody);
    final geofence = JsonCodec.mapAt(residence, 'geofence') ?? residence;
    final radius = JsonCodec.integer(
      geofence['radiusFeet'] ?? geofence['radius'] ?? geofence['radiusFt'],
    );
    final residenceName = JsonCodec.string(residence['name']) ??
        fallbackResidenceName;

    return AttendanceOverview(
      lateCount: late.length,
      missedCount: missed.length,
      otCount: otRows.length,
      todayStats: [
        AttendanceStat(
          id: 'on-time',
          value: '${onTime.length}',
          label: 'On Time',
          tone: AttendanceStatTone.positive,
          iconAsset: AttendanceAssets.onTime,
        ),
        AttendanceStat(
          id: 'late',
          value: '${late.length}',
          label: 'Late',
          tone: AttendanceStatTone.warning,
          iconAsset: AttendanceAssets.late,
        ),
        AttendanceStat(
          id: 'missed',
          value: '${missed.length}',
          label: 'Missed',
          tone: AttendanceStatTone.critical,
          iconAsset: AttendanceAssets.missed,
        ),
        AttendanceStat(
          id: 'on-duty',
          value: '$onDuty',
          label: 'On Duty',
          tone: AttendanceStatTone.info,
          iconAsset: AttendanceAssets.onDuty,
        ),
      ],
      staffOnDutyLabel: '$onDuty on duty',
      staffStatus: [
        for (var i = 0; i < rows.length; i++) _statusEntry(rows[i], i),
      ],
      lateStats: [
        AttendanceStat(
          id: 'late-today',
          value: '${late.length}',
          label: 'Late Today',
          tone: AttendanceStatTone.warning,
          iconAsset: AttendanceAssets.late,
        ),
        AttendanceStat(
          id: 'late-affected',
          value: '${late.length}',
          label: 'Affected',
          tone: AttendanceStatTone.info,
          iconAsset: AttendanceAssets.onDuty,
        ),
      ],
      lateArrivals: [
        for (var i = 0; i < late.length; i++) _lateEntry(late[i], i),
      ],
      missedStats: [
        AttendanceStat(
          id: 'missed-today',
          value: '${missed.length}',
          label: 'Missed Today',
          tone: AttendanceStatTone.critical,
          iconAsset: AttendanceAssets.missedToday,
        ),
      ],
      missedClockIns: [
        for (var i = 0; i < missed.length; i++) _missedEntry(missed[i], i),
      ],
      otStats: [
        AttendanceStat(
          id: 'ot-total',
          value: JsonCodec.stringOr(
            summary['totalHours'] ?? summary['periodHours'],
            '${otRows.length}',
          ),
          label: 'OT Records',
          tone: AttendanceStatTone.info,
          iconAsset: AttendanceAssets.calendar,
        ),
        AttendanceStat(
          id: 'ot-approaching',
          value: '${approaching.length}',
          label: 'Approaching',
          tone: AttendanceStatTone.warning,
          iconAsset: AttendanceAssets.approachingLimit,
        ),
        AttendanceStat(
          id: 'ot-exceeded',
          value: '${exceeded.length}',
          label: 'Exceeded',
          tone: AttendanceStatTone.critical,
          iconAsset: AttendanceAssets.critical,
        ),
      ],
      overtimeEntries: [
        for (var i = 0; i < otRows.length; i++)
          _otEntry(otRows[i], i, weeklyLimit.toDouble()),
      ],
      geofenceResidenceName: residenceName,
      geofenceRadiusLabel: radius == null ? null : 'Verification radius · $radius ft',
    );
  }

  static StaffStatusEntry _statusEntry(Map<String, dynamic> json, int index) {
    final name = _staffName(json);
    final status = _status(json);
    final checkIn = JsonCodec.dateTime(
      json['checkInAt'] ?? json['clockInAt'] ?? json['arrivedAt'],
    );
    return StaffStatusEntry(
      id: JsonCodec.stringOr(json['id'] ?? json['staffId'], name),
      name: name,
      initials: IsoDateRange.initials(name),
      avatarPaletteIndex: index % 6,
      status: status,
      secondaryText: status == StaffAttendanceStatus.missed
          ? JsonCodec.stringOr(json['reason'] ?? json['status'], 'No clock in')
          : JsonCodec.stringOr(
              json['locationLabel'] ?? json['siteStatus'],
              'On Site',
            ),
      timeLabel: checkIn == null ? null : IsoDateRange.timeLabel(checkIn.toLocal()),
    );
  }

  static LateArrivalEntry _lateEntry(Map<String, dynamic> json, int index) {
    final name = _staffName(json);
    final checkIn = JsonCodec.dateTime(
      json['checkInAt'] ?? json['clockInAt'] ?? json['arrivedAt'],
    );
    final scheduled = JsonCodec.dateTime(
      json['scheduledStartAt'] ?? json['shiftStartAt'],
    );
    var lateLabel = JsonCodec.string(json['lateBy'] ?? json['lateLabel']);
    if (lateLabel == null && checkIn != null && scheduled != null) {
      lateLabel = '${checkIn.difference(scheduled).inMinutes} min late';
    }
    return LateArrivalEntry(
      id: JsonCodec.stringOr(json['id'] ?? json['staffId'], name),
      name: name,
      role: JsonCodec.stringOr(json['role'] ?? json['jobTitle'], 'Staff'),
      avatarPaletteIndex: index % 6,
      lateLabel: lateLabel ?? 'Late',
      scheduledRange: IsoDateRange.rangeLabel(
        JsonCodec.dateTime(json['shiftStartAt'] ?? json['scheduledStartAt']),
        JsonCodec.dateTime(json['shiftEndAt'] ?? json['scheduledEndAt']),
      ),
      clockedInTime:
          checkIn == null ? '--' : IsoDateRange.timeLabel(checkIn.toLocal()),
      distanceLabel: JsonCodec.stringOr(
        json['locationLabel'] ?? json['geofenceLabel'],
        'On Site',
      ),
    );
  }

  static MissedClockInEntry _missedEntry(Map<String, dynamic> json, int index) {
    final name = _staffName(json);
    final role = JsonCodec.stringOr(json['role'] ?? json['jobTitle'], 'Staff');
    final range = IsoDateRange.rangeLabel(
      JsonCodec.dateTime(json['shiftStartAt'] ?? json['scheduledStartAt']),
      JsonCodec.dateTime(json['shiftEndAt'] ?? json['scheduledEndAt']),
    );
    return MissedClockInEntry(
      id: JsonCodec.stringOr(json['id'] ?? json['staffId'], name),
      name: name,
      roleShiftLabel: range.isEmpty ? role : '$role · $range',
      avatarPaletteIndex: index % 6,
      reasonLabel: JsonCodec.stringOr(
        json['reason'] ?? json['status'],
        'Not recorded',
      ),
    );
  }

  static OvertimeEntry _otEntry(
    Map<String, dynamic> json,
    int index,
    double weeklyLimit,
  ) {
    final name = _staffName(json);
    final role = JsonCodec.stringOr(json['role'] ?? json['jobTitle'], 'Staff');
    final range = IsoDateRange.rangeLabel(
      JsonCodec.dateTime(json['shiftStartAt'] ?? json['scheduledStartAt']),
      JsonCodec.dateTime(json['shiftEndAt'] ?? json['scheduledEndAt']),
    );
    final todayMinutes = JsonCodec.integer(
          json['overtimeTodayMinutes'] ?? json['otTodayMinutes'],
        ) ??
        0;
    final periodHours = JsonCodec.number(json['periodHours'] ?? json['weeklyHours']) ??
        todayMinutes / 60;
    final status = _otStatus(json);
    final progress = weeklyLimit <= 0
        ? 0.0
        : (periodHours / weeklyLimit).clamp(0.0, 1.0);
    return OvertimeEntry(
      id: JsonCodec.stringOr(json['id'] ?? json['staffId'], name),
      name: name,
      roleShiftLabel: range.isEmpty ? role : '$role · $range',
      avatarPaletteIndex: index % 6,
      status: status,
      otTodayLabel: IsoDateRange.workedMinutesLabel(todayMinutes).isEmpty
          ? '${periodHours.toStringAsFixed(1)}h'
          : IsoDateRange.workedMinutesLabel(todayMinutes),
      weeklyTotalLabel: '${periodHours.toStringAsFixed(1)}h',
      progress: progress,
      limitCaption: status == OvertimeStatus.exceeded
          ? 'Limit ${weeklyLimit.toStringAsFixed(0)}h · exceeded'
          : 'Limit ${weeklyLimit.toStringAsFixed(0)}h',
    );
  }

  static String _staffName(Map<String, dynamic> json) {
    return IsoDateRange.personName(
      json['staff'] ?? json['user'] ?? json['employee'] ?? json['name'],
    );
  }

  static StaffAttendanceStatus _status(Map<String, dynamic> json) {
    switch ((JsonCodec.string(json['status'] ?? json['state']) ?? '')
        .toLowerCase()) {
      case 'late':
        return StaffAttendanceStatus.late;
      case 'missed':
      case 'absent':
      case 'no_show':
      case 'noshow':
        return StaffAttendanceStatus.missed;
      default:
        return StaffAttendanceStatus.onTime;
    }
  }

  static OvertimeStatus _otStatus(Map<String, dynamic> json) {
    switch ((JsonCodec.string(json['state'] ?? json['status']) ?? '')
        .toLowerCase()) {
      case 'exceeded':
      case 'over':
        return OvertimeStatus.exceeded;
      default:
        return OvertimeStatus.approaching;
    }
  }

  const AttendanceMapper._();
}
