import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../staff_core_constants.dart';
import '../../domain/entities/shift_avatar.dart';
import '../../domain/entities/staff_schedule_overview.dart';
import '../../domain/entities/staff_shift.dart';
import '../../domain/entities/week_day.dart';

abstract final class StaffScheduleMapper {
  static StaffScheduleOverview compose({
    required dynamic mineBody,
    required dynamic openBody,
  }) {
    final weekStart = IsoDateRange.startOfWeek();
    final today = DateTime.now();
    final weekDays = List<WeekDay>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return WeekDay(
        dayLabel: labels[index],
        dayNumber: '${day.day}',
        isSelected: day.year == today.year &&
            day.month == today.month &&
            day.day == today.day,
      );
    });

    final shifts = JsonCodec.unwrapList(mineBody)
        .whereType<Map>()
        .map((item) => shiftFromJson(JsonCodec.asMap(item)))
        .toList();
    final openShifts = JsonCodec.unwrapList(openBody)
        .whereType<Map>()
        .map((item) => shiftFromJson(JsonCodec.asMap(item)))
        .toList();

    return StaffScheduleOverview(
      weekRangeLabel: IsoDateRange.formatWeekRange(
        weekStart,
        weekStart.add(const Duration(days: 6)),
      ),
      weekDays: weekDays,
      shiftsThisWeekLabel: '${shifts.length} this week',
      shifts: shifts,
      openShiftRequests: openShifts,
    );
  }

  static StaffShift shiftFromJson(Map<String, dynamic> json) {
    final start = JsonCodec.dateTime(
      json['startAt'] ?? json['startsAt'] ?? json['startTime'] ?? json['from'],
    );
    final end = JsonCodec.dateTime(
      json['endAt'] ?? json['endsAt'] ?? json['endTime'] ?? json['to'],
    );
    final now = DateTime.now();
    final isToday = start != null &&
        start.toLocal().year == now.year &&
        start.toLocal().month == now.month &&
        start.toLocal().day == now.day;

    final assignments = JsonCodec.listAt(json, 'assignments');
    final avatars = assignments.take(3).map((item) {
      final person = item is Map
          ? (JsonCodec.asMap(item)['staff'] ??
              JsonCodec.asMap(item)['user'] ??
              item)
          : item;
      return ShiftAvatar(IsoDateRange.initials(IsoDateRange.personName(person)));
    }).toList();

    final filled = JsonCodec.integer(
          json['assignedCount'] ?? json['filled'] ?? json['staffCount'],
        ) ??
        assignments.length;
    final total = JsonCodec.integerOr(
      json['requiredCount'] ?? json['total'] ?? json['capacity'],
      filled == 0 ? 1 : filled,
    );
    final ratio = total == 0 ? 1.0 : filled / total;

    final hours = (start != null && end != null)
        ? end.difference(start).inMinutes.abs() / 60
        : 8;
    final hoursLabel = hours == hours.roundToDouble()
        ? '${hours.toInt()}h'
        : '${hours.toStringAsFixed(1)}h';

    final datePart = start == null
        ? JsonCodec.stringOr(json['dateLabel'], '')
        : IsoDateRange.formatShortDate(start.toLocal());
    final timePart = IsoDateRange.rangeLabel(start, end);
    final dateTimeLabel = [
      if (datePart.isNotEmpty) datePart,
      if (timePart.isNotEmpty) '$timePart ($hoursLabel)',
    ].join(' · ');

    return StaffShift(
      id: JsonCodec.stringOr(json['id'], dateTimeLabel),
      title: JsonCodec.stringOr(
        json['name'] ?? json['title'] ?? json['period'] ?? json['shiftType'],
        'Shift',
      ),
      isToday: isToday,
      dateTimeLabel: dateTimeLabel.isEmpty ? 'Scheduled' : dateTimeLabel,
      location: JsonCodec.stringOr(
        json['residenceName'] ??
            JsonCodec.mapAt(json, 'residence')?['name'] ??
            json['location'],
        'Residence',
      ),
      avatars: avatars,
      extraStaffCount: (filled - avatars.length).clamp(0, 99),
      filled: filled,
      total: total,
      roleTag: JsonCodec.stringOr(
        json['role'] ?? json['roleTag'] ?? json['requiredRole'],
        'Staff',
      ),
      statusLabel: JsonCodec.stringOr(json['status'], 'Confirmed'),
      staffingLevel: ratio >= 0.9
          ? StaffingLevel.high
          : ratio >= 0.7
              ? StaffingLevel.medium
              : StaffingLevel.low,
    );
  }

  const StaffScheduleMapper._();
}
