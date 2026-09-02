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
import '../../domain/entities/shift_request.dart';
import '../../domain/entities/staff_avatar.dart';

abstract final class SchedulingMapper {
  static SchedulingOverview compose({
    required dynamic weekBody,
    required dynamic openBody,
    required dynamic pendingSwapsBody,
    required dynamic approvedSwapsBody,
  }) {
    final weekStart = IsoDateRange.startOfWeek();
    final today = DateTime.now();
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekShifts = _shifts(weekBody);
    final openShifts = _shifts(openBody);
    final days = List<CalendarDay>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final hasShift = weekShifts.any((shift) {
        final start = _startOf(shift);
        return start != null &&
            start.year == day.year &&
            start.month == day.month &&
            start.day == day.day;
      });
      return CalendarDay(
        dayLabel: labels[index],
        dayNumber: '${day.day}',
        isSelected: day.year == today.year &&
            day.month == today.month &&
            day.day == today.day,
        hasShiftIndicator: hasShift,
      );
    });

    final todayShifts = weekShifts.where((shift) {
      final start = _startOf(shift);
      return start != null &&
          start.year == today.year &&
          start.month == today.month &&
          start.day == today.day;
    }).toList();
    final source = todayShifts.isNotEmpty ? todayShifts : weekShifts;

    return SchedulingOverview(
      calendar: CalendarSchedule(
        monthLabel: IsoDateRange.formatMonthYear(today),
        days: days,
        selectedDateLabel: IsoDateRange.formatWeekdayDate(today),
        shiftsSummaryLabel: '${source.length} shifts scheduled',
        openShiftsLabel: '${openShifts.length} open',
        shifts: [
          for (var i = 0; i < source.length; i++)
            _calendarShift(source[i], showDivider: i != source.length - 1),
        ],
      ),
      board: BoardOverview(
        coverageSummaries: source.map(_coverage).toList(),
        shifts: source.map(_boardShift).toList(),
        openPositions: openShifts.map(_openPosition).toList(),
      ),
      requests: RequestsOverview(
        pendingRequests: _requests(pendingSwapsBody, RequestStatus.pending),
        approvedRequests: _requests(approvedSwapsBody, RequestStatus.approved),
      ),
    );
  }

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
      urgency: OpenPositionUrgency.open,
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
    final assignments = JsonCodec.listAt(json, 'assignments');
    if (assignments.isNotEmpty) {
      return assignments.map((item) {
        final person = item is Map
            ? (JsonCodec.asMap(item)['staff'] ??
                JsonCodec.asMap(item)['user'] ??
                item)
            : item;
        return StaffAvatar(IsoDateRange.initials(IsoDateRange.personName(person)));
      }).toList();
    }
    return JsonCodec.listAt(json, 'staff')
        .map((item) => StaffAvatar(IsoDateRange.initials(IsoDateRange.personName(item))))
        .toList();
  }

  static String _namesSummary(Map<String, dynamic> json, List<StaffAvatar> avatars) {
    final names = JsonCodec.listAt(json, 'assignments').map((item) {
      final person = item is Map
          ? (JsonCodec.asMap(item)['staff'] ??
              JsonCodec.asMap(item)['user'] ??
              item)
          : item;
      return IsoDateRange.personName(person);
    }).where((name) => name != 'Unknown').toList();
    if (names.isEmpty) {
      return avatars.isEmpty ? 'Unassigned' : '${avatars.length} assigned';
    }
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2}';
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
