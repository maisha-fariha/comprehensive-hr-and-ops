import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/board_overview.dart';
import '../../domain/entities/board_shift.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/calendar_schedule.dart';
import '../../domain/entities/calendar_shift.dart';
import '../../domain/entities/coverage_summary.dart';
import '../../domain/entities/open_position.dart';
import '../../domain/entities/requests_overview.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../../domain/entities/shift_qualification_option.dart';
import '../../domain/entities/shift_request.dart';
import '../../domain/entities/shift_residence_option.dart';
import '../../domain/entities/shift_staff_option.dart';
import '../../domain/entities/staff_avatar.dart';

abstract final class SchedulingMapper {
  /// Unique qualification options from `GET /staff` (`categoryId` + name).
  static List<ShiftQualificationOption> qualificationsFrom(dynamic body) {
    final source = JsonCodec.unwrapList(body);
    final seen = <String>{};
    final options = <ShiftQualificationOption>[];

    for (final item in source) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final category = JsonCodec.mapAt(json, 'category') ??
          JsonCodec.mapAt(json, 'staffCategory') ??
          JsonCodec.mapAt(json, 'qualificationCategory') ??
          const {};
      final label = JsonCodec.string(
            category['name'] ??
                category['label'] ??
                category['title'] ??
                json['categoryName'] ??
                json['qualification'] ??
                json['qualificationName'] ??
                json['role'] ??
                json['jobTitle'] ??
                json['title'],
          ) ??
          '';
      if (label.isEmpty) continue;

      final id = JsonCodec.stringOr(
        json['categoryId'] ??
            category['id'] ??
            json['qualificationId'] ??
            json['staffCategoryId'] ??
            label,
        label,
      );
      if (!seen.add(id.toLowerCase())) continue;

      options.add(ShiftQualificationOption(id: id, label: label));
    }

    options.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return options;
  }

  /// Parse `GET /staff` into Create Shift assign-staff options.
  static List<ShiftStaffOption> staffFrom(dynamic body) {
    final source = JsonCodec.unwrapList(body);
    final options = <ShiftStaffOption>[];

    for (final item in source) {
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
                ].where((p) => p != null && p.toString().trim().isNotEmpty).join(' '),
          ) ??
          '';
      if (name.isEmpty) continue;

      final role = JsonCodec.string(
        category['name'] ??
            json['categoryName'] ??
            json['role'] ??
            json['jobTitle'] ??
            json['title'] ??
            json['qualification'] ??
            user['role'] ??
            user['jobTitle'],
      );
      final categoryId = JsonCodec.string(
        json['categoryId'] ??
            category['id'] ??
            json['qualificationId'] ??
            json['staffCategoryId'],
      );
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      final location = JsonCodec.string(
        json['residenceName'] ??
            residence['name'] ??
            json['location'] ??
            json['city'] ??
            json['site'],
      );
      final detail = [
        if (role != null && role.isNotEmpty) role,
        if (location != null && location.isNotEmpty) location,
      ].join(' · ');

      options.add(
        ShiftStaffOption(
          id: JsonCodec.stringOr(
            json['id'] ?? json['staffId'] ?? user['id'] ?? name,
            name,
          ),
          name: name,
          detail: detail.isEmpty ? 'Staff' : detail,
          initials: IsoDateRange.initials(name),
          role: role,
          categoryId: categoryId,
        ),
      );
    }
    return options;
  }

  /// Parse `GET /residences` into Create Shift dropdown options.
  static List<ShiftResidenceOption> residencesFrom(dynamic body) {
    final source = JsonCodec.unwrapList(body);
    final options = <ShiftResidenceOption>[];

    for (final item in source) {
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
        ShiftResidenceOption(
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

  static SchedulingOverview compose({
    required dynamic weekBody,
    required dynamic openBody,
    required dynamic pendingSwapsBody,
    required dynamic approvedSwapsBody,
    required dynamic declinedSwapsBody,
    DateTime? weekOf,
    DateTime? selectedDay,
  }) {
    final weekStart = IsoDateRange.startOfWeek(weekOf);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekShiftsRaw = _shifts(weekBody);
    final openShifts = _shifts(openBody);

    final preferredSelected = selectedDay == null
        ? null
        : DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final selected = _resolveSelectedDay(
      weekStart: weekStart,
      today: todayDate,
      preferred: preferredSelected,
    );

    final days = List<CalendarDay>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final dayDate = DateTime(day.year, day.month, day.day);
      final hasShift = weekShiftsRaw.any((shift) {
        final start = _startOf(shift);
        return start != null && _isSameDay(start, dayDate);
      });
      return CalendarDay(
        date: dayDate,
        dayLabel: labels[index],
        dayNumber: '${dayDate.day}',
        isSelected: _isSameDay(dayDate, selected),
        hasShiftIndicator: hasShift,
      );
    });

    final weekShifts = [
      for (final raw in weekShiftsRaw) _calendarShift(raw, showDivider: true),
    ];

    final dayShifts = weekShifts
        .where((shift) {
          final occurs = shift.occursOn;
          return occurs != null && _isSameDay(occurs, selected);
        })
        .toList();
    final timeline = [
      for (var i = 0; i < dayShifts.length; i++)
        CalendarShift(
          id: dayShifts[i].id,
          occursOn: dayShifts[i].occursOn,
          startTime: dayShifts[i].startTime,
          startPeriod: dayShifts[i].startPeriod,
          name: dayShifts[i].name,
          timeRange: dayShifts[i].timeRange,
          filled: dayShifts[i].filled,
          total: dayShifts[i].total,
          status: dayShifts[i].status,
          avatars: dayShifts[i].avatars,
          namesSummary: dayShifts[i].namesSummary,
          openPositionsLabel: dayShifts[i].openPositionsLabel,
          showTimelineDivider: i != dayShifts.length - 1,
        ),
    ];

    return SchedulingOverview(
      calendar: CalendarSchedule(
        monthLabel: IsoDateRange.formatMonthYear(selected),
        days: days,
        selectedDateLabel: IsoDateRange.formatWeekdayDate(selected),
        shiftsSummaryLabel: '${timeline.length} shifts scheduled',
        openShiftsLabel: '${openShifts.length} open',
        shifts: timeline,
        weekShifts: weekShifts,
      ),
      // Board keeps the full week so calendar day taps do not alter Board tab.
      board: BoardOverview(
        coverageSummaries: weekShiftsRaw.map(_coverage).toList(),
        shifts: weekShiftsRaw.map(_boardShift).toList(),
        openPositions: openShifts.map(_openPosition).toList(),
      ),
      requests: RequestsOverview(
        pendingRequests: _requests(pendingSwapsBody, RequestStatus.pending),
        approvedRequests: _requests(approvedSwapsBody, RequestStatus.approved),
        declinedRequests: _requests(declinedSwapsBody, RequestStatus.declined),
        openShiftRequests: openShifts.map(_openPosition).toList(),
      ),
    );
  }

  /// Rebuilds only the calendar strip/timeline for a newly selected day using
  /// shifts already loaded for the week (no API call).
  static CalendarSchedule calendarForSelectedDay({
    required CalendarSchedule current,
    required DateTime selectedDay,
  }) {
    final selected = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    final pool =
        current.weekShifts.isNotEmpty ? current.weekShifts : current.shifts;
    final dayShifts = pool
        .where((shift) {
          final occurs = shift.occursOn;
          return occurs != null && _isSameDay(occurs, selected);
        })
        .toList();
    final timeline = [
      for (var i = 0; i < dayShifts.length; i++)
        CalendarShift(
          id: dayShifts[i].id,
          occursOn: dayShifts[i].occursOn,
          startTime: dayShifts[i].startTime,
          startPeriod: dayShifts[i].startPeriod,
          name: dayShifts[i].name,
          timeRange: dayShifts[i].timeRange,
          filled: dayShifts[i].filled,
          total: dayShifts[i].total,
          status: dayShifts[i].status,
          avatars: dayShifts[i].avatars,
          namesSummary: dayShifts[i].namesSummary,
          openPositionsLabel: dayShifts[i].openPositionsLabel,
          showTimelineDivider: i != dayShifts.length - 1,
        ),
    ];

    return current.copyWith(
      monthLabel: IsoDateRange.formatMonthYear(selected),
      days: [
        for (final day in current.days)
          day.copyWith(isSelected: _isSameDay(day.date, selected)),
      ],
      selectedDateLabel: IsoDateRange.formatWeekdayDate(selected),
      shiftsSummaryLabel: '${timeline.length} shifts scheduled',
      shifts: timeline,
    );
  }

  static DateTime _resolveSelectedDay({
    required DateTime weekStart,
    required DateTime today,
    required DateTime? preferred,
  }) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (preferred != null &&
        !preferred.isBefore(weekStart) &&
        !preferred.isAfter(weekEnd)) {
      return preferred;
    }
    if (!today.isBefore(weekStart) && !today.isAfter(weekEnd)) {
      return today;
    }
    return weekStart;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<Map<String, dynamic>> _shifts(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();
  }

  static DateTime? _startOf(Map<String, dynamic> json) {
    return JsonCodec.dateTime(
      json['startAt'] ?? json['startsAt'] ?? json['startTime'] ?? json['from'],
    )?.toLocal();
  }

  static DateTime? _endOf(Map<String, dynamic> json) {
    return JsonCodec.dateTime(
      json['endAt'] ?? json['endsAt'] ?? json['endTime'] ?? json['to'],
    )?.toLocal();
  }

  static CalendarShift _calendarShift(
    Map<String, dynamic> json, {
    required bool showDivider,
  }) {
    final start = _startOf(json);
    final end = _endOf(json);
    final filled = _filled(json);
    final total = _total(json, filled);
    final open = (total - filled).clamp(0, total);
    final hour = start?.hour ?? 0;
    final minute = (start?.minute ?? 0).toString().padLeft(2, '0');
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    final avatars = _avatars(json);
    return CalendarShift(
      id: JsonCodec.stringOr(json['id'], 'shift'),
      occursOn: start == null
          ? null
          : DateTime(start.year, start.month, start.day),
      startTime: start == null ? '--' : '$hour12:$minute',
      startPeriod: period,
      name: JsonCodec.stringOr(
        json['name'] ?? json['title'] ?? json['role'] ?? json['period'],
        _periodName(start),
      ),
      timeRange: IsoDateRange.rangeLabel(start, end),
      filled: filled,
      total: total,
      status: _coverageStatus(filled, total),
      avatars: avatars.take(3).toList(),
      namesSummary: _namesSummary(json, avatars),
      openPositionsLabel: open == 0
          ? null
          : '$open open${_roleSuffix(json)}',
      showTimelineDivider: showDivider,
    );
  }

  static BoardShift _boardShift(Map<String, dynamic> json) {
    final start = _startOf(json);
    final end = _endOf(json);
    final filled = _filled(json);
    final total = _total(json, filled);
    final open = (total - filled).clamp(0, total);
    final status = _coverageStatus(filled, total);
    final avatars = _avatars(json);
    return BoardShift(
      id: JsonCodec.stringOr(json['id'], 'shift'),
      periodLabel: JsonCodec.stringOr(
        json['name'] ?? json['title'] ?? json['period'],
        _periodName(start),
      ),
      timeRange: IsoDateRange.rangeLabel(start, end),
      filled: filled,
      total: total,
      status: status,
      statusLabel:
          status == CoverageStatus.almostFull ? 'Almost Full' : 'Needs Attention',
      avatars: avatars.take(3).toList(),
      extraStaffCount: (avatars.length - 3).clamp(0, 99),
      roleChips: _roles(json),
      neededLabel: open == 0 ? 'Covered' : '$open needed',
    );
  }

  static CoverageSummary _coverage(Map<String, dynamic> json) {
    final filled = _filled(json);
    final total = _total(json, filled);
    final status = _coverageStatus(filled, total);
    return CoverageSummary(
      periodLabel: JsonCodec.stringOr(
        json['name'] ?? json['period'],
        _periodName(_startOf(json)),
      ),
      ratioLabel: '$filled/$total',
      status: status,
      statusLabel:
          status == CoverageStatus.almostFull ? 'Almost Full' : 'Needs Attention',
    );
  }

  static OpenPosition _openPosition(Map<String, dynamic> json) {
    final start = _startOf(json);
    final residence = JsonCodec.string(
          json['residenceName'] ??
              JsonCodec.mapAt(json, 'residence')?['name'],
        ) ??
        '';
    return OpenPosition(
      id: JsonCodec.stringOr(json['id'], 'open'),
      roleTitle: JsonCodec.stringOr(
        json['role'] ?? json['title'] ?? json['name'],
        'Open shift',
      ),
      urgency: JsonCodec.boolean(json['urgent'] ?? json['isUrgent']) == true
          ? OpenPositionUrgency.urgent
          : OpenPositionUrgency.open,
      subtitle: [
        _periodName(start),
        if (residence.isNotEmpty) residence,
      ].join(' · '),
    );
  }

  static List<ShiftRequest> _requests(dynamic body, RequestStatus status) {
    return JsonCodec.unwrapList(body).whereType<Map>().map((item) {
      final json = JsonCodec.asMap(item);
      final requester = json['requester'] ??
          json['fromStaff'] ??
          json['staff'] ??
          json['requestedBy'];
      final name = IsoDateRange.personName(requester);
      final created = JsonCodec.dateTime(json['createdAt'] ?? json['requestedAt']);
      final giving = json['fromShift'] ?? json['givingShift'] ?? json['currentShift'];
      final receiving =
          json['toShift'] ?? json['receivingShift'] ?? json['requestedShift'];
      final apiStatus = JsonCodec.string(json['status'])?.toLowerCase() ?? '';
      return ShiftRequest(
        id: JsonCodec.stringOr(json['id'], name),
        staffName: name,
        staffInitials: IsoDateRange.initials(name),
        status: status,
        timingLabel: created == null
            ? JsonCodec.stringOr(json['status'], '')
            : IsoDateRange.timeAgo(created),
        givingLabel: _swapShiftLabel(giving),
        receivingLabel: _swapShiftLabel(receiving),
        canManagerDecide:
            status == RequestStatus.pending && apiStatus == 'awaiting_manager',
      );
    }).toList();
  }

  static String _swapShiftLabel(dynamic value) {
    if (value is Map) {
      final json = JsonCodec.asMap(value);
      final start = _startOf(json);
      final name = JsonCodec.string(json['name'] ?? json['title'] ?? json['period']);
      if (start != null) {
        return '${IsoDateRange.formatShortDate(start)} · ${name ?? _periodName(start)}';
      }
      return name ?? 'Shift';
    }
    return IsoDateRange.stringOr(value, 'Shift');
  }

  static int _filled(Map<String, dynamic> json) {
    return JsonCodec.integer(
          json['assignedCount'] ?? json['filled'] ?? json['staffCount'],
        ) ??
        JsonCodec.listAt(json, 'assignments').length;
  }

  static int _total(Map<String, dynamic> json, int filled) {
    return JsonCodec.integerOr(
      json['requiredCount'] ?? json['total'] ?? json['capacity'],
      filled == 0 ? 1 : filled,
    );
  }

  static CoverageStatus _coverageStatus(int filled, int total) {
    if (total <= 0) return CoverageStatus.almostFull;
    return filled / total >= 0.8
        ? CoverageStatus.almostFull
        : CoverageStatus.needsAttention;
  }

  static List<StaffAvatar> _avatars(Map<String, dynamic> json) {
    return _assignedPeople(json)
        .map(
          (person) =>
              StaffAvatar(IsoDateRange.initials(IsoDateRange.personName(person))),
        )
        .toList();
  }

  /// "Sarah, Mike +6" — first names of assignees, matching the Calendar card.
  static String _namesSummary(
    Map<String, dynamic> json,
    List<StaffAvatar> avatars,
  ) {
    final names = _assignedPeople(json)
        .map(_firstName)
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return avatars.isEmpty ? 'Unassigned' : '${avatars.length} assigned';
    }
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2}';
  }

  static List<dynamic> _assignedPeople(Map<String, dynamic> json) {
    final assignments = JsonCodec.listAt(json, 'assignments');
    if (assignments.isNotEmpty) {
      return assignments.map((item) {
        if (item is! Map) return item;
        final map = JsonCodec.asMap(item);
        return map['staff'] ??
            map['user'] ??
            map['employee'] ??
            map['assignee'] ??
            item;
      }).toList();
    }
    final staff = JsonCodec.listAt(json, 'staff');
    if (staff.isNotEmpty) return staff;
    return JsonCodec.listAt(json, 'assignees');
  }

  static String _firstName(dynamic person) {
    if (person is Map) {
      final map = JsonCodec.asMap(person);
      final explicit = JsonCodec.string(
        map['firstName'] ?? map['givenName'] ?? map['preferredName'],
      );
      if (explicit != null && explicit.isNotEmpty) return explicit;

      final full = IsoDateRange.personName(person);
      if (full == 'Unknown') return '';
      return full.split(RegExp(r'\s+')).first;
    }
    final raw = IsoDateRange.stringOr(person, '');
    if (raw.isEmpty || raw == 'Unknown') return '';
    return raw.split(RegExp(r'\s+')).first;
  }

  static List<String> _roles(Map<String, dynamic> json) {
    final roles = JsonCodec.listAt(json, 'roles');
    if (roles.isNotEmpty) {
      return roles.map((item) => item.toString()).toList();
    }
    final role = JsonCodec.string(json['role'] ?? json['requiredRole']);
    return role == null ? const [] : [role];
  }

  static String _roleSuffix(Map<String, dynamic> json) {
    final role = JsonCodec.string(json['role'] ?? json['requiredRole']);
    return role == null ? '' : ' · $role';
  }

  static String _periodName(DateTime? start) {
    if (start == null) return 'Shift';
    final hour = start.hour;
    if (hour < 12) return 'Morning Shift';
    if (hour < 18) return 'Afternoon Shift';
    return 'Night Shift';
  }

  const SchedulingMapper._();
}
