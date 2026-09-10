import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../attendance_assets.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_overview.dart';
import '../../domain/entities/attendance_stat.dart';
import '../../domain/entities/late_arrival_entry.dart';
import '../../domain/entities/manual_entry_options.dart';
import '../../domain/entities/missed_clock_in_entry.dart';
import '../../domain/entities/overtime_entry.dart';
import '../../domain/entities/staff_status_entry.dart';

abstract final class AttendanceMapper {
  static AttendanceOverview compose({
    required dynamic attendanceBody,
    required dynamic overtimeBody,
    required dynamic residenceBody,
    required String? fallbackResidenceName,
    dynamic summaryBody,
    bool multiDay = false,
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

    final summaryData = summaryBody == null
        ? null
        : JsonCodec.unwrapMap(summaryBody);
    final byStatus = summaryData == null
        ? null
        : (JsonCodec.mapAt(summaryData, 'byStatus') ?? summaryData);

    final presentCount = byStatus == null
        ? onTime.length
        : JsonCodec.integerOr(
            byStatus['present'] ?? byStatus['onTime'] ?? byStatus['on_time'],
            onTime.length,
          );
    final lateCount = byStatus == null
        ? late.length
        : JsonCodec.integerOr(byStatus['late'], late.length);
    final missedCount = byStatus == null
        ? missed.length
        : JsonCodec.integerOr(byStatus['missed'], missed.length);
    final onDuty = presentCount + lateCount;

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

    final latenessStaff = summaryData == null
        ? late.length
        : JsonCodec.integerOr(
            JsonCodec.mapAt(summaryData, 'lateness')?['staff'],
            late.length,
          );

    final lateLabel = multiDay ? 'Late' : 'Late Today';
    final missedLabel = multiDay ? 'Missed' : 'Missed Today';
    final onDutyLabel = multiDay ? '$onDuty present' : '$onDuty on duty';

    return AttendanceOverview(
      lateCount: lateCount,
      missedCount: missedCount,
      otCount: otRows.length,
      todayStats: [
        AttendanceStat(
          id: 'on-time',
          value: '$presentCount',
          label: multiDay ? 'Present' : 'On Time',
          tone: AttendanceStatTone.positive,
          iconAsset: AttendanceAssets.onTime,
        ),
        AttendanceStat(
          id: 'late',
          value: '$lateCount',
          label: 'Late',
          tone: AttendanceStatTone.warning,
          iconAsset: AttendanceAssets.late,
        ),
        AttendanceStat(
          id: 'missed',
          value: '$missedCount',
          label: 'Missed',
          tone: AttendanceStatTone.critical,
          iconAsset: AttendanceAssets.missed,
        ),
        AttendanceStat(
          id: 'on-duty',
          value: '$onDuty',
          label: multiDay ? 'Present + late' : 'On Duty',
          tone: AttendanceStatTone.info,
          iconAsset: AttendanceAssets.onDuty,
        ),
      ],
      staffOnDutyLabel: onDutyLabel,
      staffStatus: [
        for (var i = 0; i < rows.length; i++)
          if (_status(rows[i]) != null) _statusEntry(rows[i], i),
      ],
      lateStats: [
        AttendanceStat(
          id: 'late-today',
          value: '$lateCount',
          label: lateLabel,
          tone: AttendanceStatTone.warning,
          iconAsset: AttendanceAssets.late,
        ),
        AttendanceStat(
          id: 'late-affected',
          value: '$latenessStaff',
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
          value: '$missedCount',
          label: missedLabel,
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
    final status = _status(json) ?? StaffAttendanceStatus.onTime;
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

  static StaffAttendanceStatus? _status(Map<String, dynamic> json) {
    switch ((JsonCodec.string(json['status'] ?? json['state']) ?? '')
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_')) {
      case 'late':
        return StaffAttendanceStatus.late;
      case 'missed':
      case 'absent':
      case 'no_show':
      case 'noshow':
        return StaffAttendanceStatus.missed;
      case 'present':
      case 'on_time':
      case 'ontime':
      case 'checked_in':
      case 'clocked_in':
      case 'on_duty':
      case 'on_site':
        return StaffAttendanceStatus.onTime;
      default:
        // Unknown statuses must not inflate "On Time" / "On Duty".
        return null;
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

  static List<ManualEntryResidenceOption> residencesFrom(dynamic body) {
    final options = <ManualEntryResidenceOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final name = JsonCodec.string(
            json['name'] ??
                json['label'] ??
                json['title'] ??
                json['residenceName'] ??
                json['displayName'],
          ) ??
          '';
      if (name.isEmpty) continue;
      options.add(
        ManualEntryResidenceOption(
          id: JsonCodec.stringOr(
            json['id'] ?? json['residenceId'] ?? name,
            name,
          ),
          name: name,
        ),
      );
    }
    return options;
  }

  static List<ManualEntryStaffOption> staffFrom(dynamic body) {
    final options = <ManualEntryStaffOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final user = JsonCodec.mapAt(json, 'user') ??
          JsonCodec.mapAt(json, 'profile') ??
          json;
      final category = JsonCodec.mapAt(json, 'category') ??
          JsonCodec.mapAt(json, 'staffCategory') ??
          JsonCodec.mapAt(user, 'category') ??
          const {};
      final name = JsonCodec.string(
            user['preferredName'] ??
                user['fullName'] ??
                user['displayName'] ??
                user['name'] ??
                [
                  user['firstName'] ?? json['firstName'],
                  user['lastName'] ?? json['lastName'],
                ]
                    .where((p) => p != null && p.toString().trim().isNotEmpty)
                    .join(' '),
          ) ??
          '';
      if (name.isEmpty) continue;

      final role = JsonCodec.string(
        category['name'] ??
            json['categoryName'] ??
            json['role'] ??
            json['jobTitle'] ??
            user['role'],
      );
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      final location = JsonCodec.string(
        json['residenceName'] ?? residence['name'] ?? json['location'],
      );
      final detail = [
        if (role != null && role.isNotEmpty) role,
        if (location != null && location.isNotEmpty) location,
      ].join(' · ');

      options.add(
        ManualEntryStaffOption(
          id: JsonCodec.stringOr(
            json['id'] ?? json['staffId'] ?? user['id'] ?? name,
            name,
          ),
          name: name,
          detail: detail.isEmpty ? 'Staff' : detail,
          initials: IsoDateRange.initials(name),
        ),
      );
    }
    return options;
  }

  /// Shifts from `GET /shifts`, optionally filtered to those assigned to [staffId].
  static List<ManualEntryShiftOption> shiftsForStaff(
    dynamic body, {
    String? staffId,
  }) {
    final options = <ManualEntryShiftOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final id = JsonCodec.string(json['id'] ?? json['shiftId']);
      if (id == null || id.isEmpty) continue;

      if (staffId != null && staffId.isNotEmpty) {
        final assigned = json['staff'];
        var matched = false;
        if (assigned is List) {
          for (final person in assigned) {
            if (person is! Map) continue;
            final personMap = JsonCodec.asMap(person);
            final personId = JsonCodec.string(
              personMap['id'] ?? personMap['staffId'],
            );
            if (personId == staffId) {
              matched = true;
              break;
            }
          }
        }
        if (!matched) continue;
      }

      final startsAt = JsonCodec.dateTime(
            json['startsAt'] ?? json['startAt'] ?? json['start'],
          ) ??
          DateTime.now();
      final endsAt = JsonCodec.dateTime(
            json['endsAt'] ?? json['endAt'] ?? json['end'],
          ) ??
          startsAt.add(const Duration(hours: 8));
      final title = JsonCodec.string(
            json['title'] ?? json['name'] ?? json['shiftType'],
          ) ??
          'Shift';
      final startLabel = _formatShiftClock(startsAt);
      final endLabel = _formatShiftClock(endsAt);
      options.add(
        ManualEntryShiftOption(
          id: id,
          label: '$title · $startLabel – $endLabel',
          startsAt: startsAt,
          endsAt: endsAt,
        ),
      );
    }
    options.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return options;
  }

  static String _formatShiftClock(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  const AttendanceMapper._();
}
