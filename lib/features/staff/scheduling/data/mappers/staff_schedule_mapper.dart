import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../staff_core_constants.dart';
import '../../domain/entities/shift_avatar.dart';
import '../../domain/entities/staff_appointment.dart';
import '../../domain/entities/staff_schedule_overview.dart';
import '../../domain/entities/staff_shift.dart';
import '../../domain/entities/staff_shift_swap.dart';
import '../../domain/entities/week_day.dart';

abstract final class StaffScheduleMapper {
  static StaffScheduleOverview compose({
    required dynamic mineBody,
    required dynamic openBody,
    required dynamic swapsBody,
    required dynamic appointmentsBody,
    required DateTime weekStart,
    DateTime? selectedDate,
    String? currentStaffId,
    List<String> loadWarnings = const [],
  }) {
    final today = DateTime.now();
    final selected = selectedDate == null
        ? null
        : DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final weekDays = List<WeekDay>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final isSelected = selected != null
          ? day.year == selected.year &&
              day.month == selected.month &&
              day.day == selected.day
          : day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
      return WeekDay(
        date: day,
        dayLabel: labels[index],
        dayNumber: '${day.day}',
        isSelected: isSelected,
      );
    });

    final resolvedDays = weekDays.any((d) => d.isSelected)
        ? weekDays
        : [
            for (var i = 0; i < weekDays.length; i++)
              weekDays[i].copyWith(isSelected: i == 0),
          ];

    final shifts = _shifts(mineBody);
    final openShifts = _shifts(openBody);
    final swaps = swapsFrom(swapsBody, currentStaffId: currentStaffId);
    final appointments = appointmentsFrom(appointmentsBody);

    return StaffScheduleOverview(
      weekRangeLabel: IsoDateRange.formatWeekRange(
        weekStart,
        weekStart.add(const Duration(days: 6)),
      ),
      weekDays: resolvedDays,
      shiftsThisWeekLabel: '${shifts.length} this week',
      shifts: shifts,
      openShiftRequests: openShifts,
      swapRequests: swaps,
      appointments: appointments,
      loadWarnings: loadWarnings,
    );
  }

  static List<StaffShift> _shifts(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => shiftFromJson(JsonCodec.asMap(item)))
        .toList();
  }

  static StaffShift shiftFromJson(Map<String, dynamic> json) {
    final start = JsonCodec.dateTime(
      json['startAt'] ?? json['startsAt'] ?? json['startTime'] ?? json['from'],
    );
    final end = JsonCodec.dateTime(
      json['endAt'] ?? json['endsAt'] ?? json['endTime'] ?? json['to'],
    );
    final now = DateTime.now();
    final localStart = start?.toLocal();
    final isToday = localStart != null &&
        localStart.year == now.year &&
        localStart.month == now.month &&
        localStart.day == now.day;

    final people = _assignedPeople(json);
    final assignedPeople = people.where((person) {
      if (person is! Map) return true;
      final status =
          (JsonCodec.string(JsonCodec.asMap(person)['status']) ?? '')
              .toLowerCase();
      return status.isEmpty ||
          status == 'assigned' ||
          status == 'confirmed' ||
          status == 'accepted';
    }).toList();
    final avatarSource =
        assignedPeople.isNotEmpty ? assignedPeople : people;

    final avatars = avatarSource.take(3).map((person) {
      return ShiftAvatar(IsoDateRange.initials(IsoDateRange.personName(person)));
    }).toList();

    final filled = JsonCodec.integer(
          json['assignedCount'] ?? json['filled'] ?? json['staffCount'],
        ) ??
        assignedPeople.length;
    final openCount = JsonCodec.integer(json['openCount']);
    final required = JsonCodec.integer(
      json['requiredStaffCount'] ??
          json['requiredCount'] ??
          json['total'] ??
          json['capacity'],
    );

    // Prefer explicit capacity, then assigned + openCount, else assigned.
    final int total;
    if (required != null && required > 0) {
      total = required;
    } else if (openCount != null) {
      total = (filled + openCount).clamp(1, 999);
    } else if (filled > 0) {
      total = filled;
    } else {
      total = 1;
    }

    final openSlots = openCount ?? (total - filled).clamp(0, 999);
    final ratio = total == 0 ? 1.0 : filled / total;

    final hours = (start != null && end != null)
        ? end.difference(start).inMinutes.abs() / 60
        : 8;
    final hoursLabel = hours == hours.roundToDouble()
        ? '${hours.toInt()}h'
        : '${hours.toStringAsFixed(1)}h';

    final datePart = localStart == null
        ? JsonCodec.stringOr(json['dateLabel'], '')
        : IsoDateRange.formatShortDate(localStart);
    final timePart = IsoDateRange.rangeLabel(start, end);
    final dateTimeLabel = [
      if (datePart.isNotEmpty) datePart,
      if (timePart.isNotEmpty) '$timePart ($hoursLabel)',
    ].join(' · ');

    final statusRaw =
        (JsonCodec.string(json['status']) ?? 'Confirmed').toLowerCase();
    final statusLabel = switch (statusRaw) {
      'published' || 'confirmed' || 'assigned' => 'Confirmed',
      'open' => 'Open',
      'cancelled' || 'canceled' => 'Cancelled',
      _ => statusRaw.isEmpty
          ? 'Confirmed'
          : '${statusRaw[0].toUpperCase()}${statusRaw.substring(1)}',
    };

    final shiftType = JsonCodec.string(json['shiftType']);
    final title = JsonCodec.string(
          json['name'] ?? json['title'] ?? json['period'],
        ) ??
        _shiftTypeTitle(shiftType) ??
        JsonCodec.string(json['requiredCategoryName']) ??
        'Shift';

    return StaffShift(
      id: JsonCodec.stringOr(json['id'], dateTimeLabel),
      title: title,
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
      openSlots: openSlots,
      roleTag: JsonCodec.stringOr(
        json['requiredCategoryName'] ??
            json['role'] ??
            json['roleTag'] ??
            json['requiredRole'] ??
            shiftType,
        'Staff',
      ),
      statusLabel: statusLabel,
      staffingLevel: ratio >= 0.9
          ? StaffingLevel.high
          : ratio >= 0.7
              ? StaffingLevel.medium
              : StaffingLevel.low,
      startAt: localStart,
    );
  }

  static String? _shiftTypeTitle(String? shiftType) {
    if (shiftType == null || shiftType.trim().isEmpty) return null;
    final raw = shiftType.trim().toLowerCase();
    return switch (raw) {
      'day' => 'Day shift',
      'night' => 'Night shift',
      'morning' => 'Morning shift',
      'afternoon' => 'Afternoon shift',
      'evening' => 'Evening shift',
      _ => '${raw[0].toUpperCase()}${raw.substring(1)} shift',
    };
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

  static List<StaffShiftSwap> swapsFrom(
    dynamic body, {
    String? currentStaffId,
  }) {
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final fromShift = json['fromShift'] ?? json['givingShift'];
          final fromStart = _shiftStart(fromShift);
          // Drop swaps whose giving shift is fully in the past.
          if (fromStart != null) {
            final local = fromStart.toLocal();
            final shiftDay = DateTime(local.year, local.month, local.day);
            if (shiftDay.isBefore(todayStart)) return null;
          }

          final status =
              (JsonCodec.string(json['status']) ?? '').toLowerCase();
          // Only actionable / in-flight swaps on the schedule page.
          if (status != 'awaiting_peer' && status != 'awaiting_manager') {
            return null;
          }

          final requesterId = JsonCodec.string(
            json['requesterStaffId'] ??
                JsonCodec.mapAt(json, 'requester')?['id'],
          );
          final targetId = JsonCodec.string(
            json['targetStaffId'] ?? JsonCodec.mapAt(json, 'target')?['id'],
          );
          final identityKnown =
              currentStaffId != null && currentStaffId.isNotEmpty;
          final isIncoming = identityKnown &&
              targetId == currentStaffId &&
              requesterId != currentStaffId;
          final isOutgoing =
              identityKnown && requesterId == currentStaffId;
          final kind = (JsonCodec.string(json['kind']) ?? '').toLowerCase();
          final requester = IsoDateRange.personName(
            json['requester'] ?? json['fromStaff'],
          );
          final target =
              IsoDateRange.personName(json['target'] ?? json['toStaff']);
          final counterpart = isIncoming ? requester : target;
          final fromLabel = _swapShiftLabel(fromShift);
          final toLabel =
              _swapShiftLabel(json['toShift'] ?? json['receivingShift']);

          final awaitingPeer = status == 'awaiting_peer';
          final awaitingManager = status == 'awaiting_manager';

          return StaffShiftSwap(
            id: JsonCodec.stringOr(json['id'], fromLabel),
            kindLabel: switch (kind) {
              'trade' => 'Trade',
              'handover' => 'Handover',
              'cover' => 'Cover',
              _ => 'Swap',
            },
            statusLabel: switch (status) {
              'awaiting_peer' =>
                isIncoming ? 'Awaiting you' : 'Awaiting peer',
              'awaiting_manager' => 'Awaiting manager',
              _ => 'Pending',
            },
            fromShiftLabel: fromLabel,
            toShiftLabel: toLabel == 'Shift' ? null : toLabel,
            counterpartName:
                counterpart == 'Unknown' ? 'Colleague' : counterpart,
            note: JsonCodec.string(json['note']),
            isIncoming: isIncoming,
            canRespond: awaitingPeer && (!identityKnown || isIncoming),
            canCancel: (awaitingPeer || awaitingManager) &&
                (!identityKnown || isOutgoing),
          );
        })
        .whereType<StaffShiftSwap>()
        .toList()
      ..sort((a, b) => a.fromShiftLabel.compareTo(b.fromShiftLabel));
  }

  static DateTime? _shiftStart(dynamic value) {
    if (value is! Map) return null;
    final json = JsonCodec.asMap(value);
    return JsonCodec.dateTime(
      json['startAt'] ?? json['startsAt'] ?? json['startTime'],
    );
  }

  static String _swapShiftLabel(dynamic value) {
    if (value is Map) {
      final json = JsonCodec.asMap(value);
      final start = _shiftStart(json);
      final name = JsonCodec.string(
            json['name'] ?? json['title'],
          ) ??
          _shiftTypeTitle(JsonCodec.string(json['shiftType'])) ??
          JsonCodec.string(json['period']);
      final residence = JsonCodec.string(
        json['residenceName'] ?? JsonCodec.mapAt(json, 'residence')?['name'],
      );
      if (start != null) {
        return [
          IsoDateRange.formatShortDate(start.toLocal()),
          if (name != null && name.isNotEmpty) name,
          if (residence != null && residence.isNotEmpty) residence,
        ].join(' · ');
      }
      return name ?? residence ?? 'Shift';
    }
    return IsoDateRange.stringOr(value, 'Shift');
  }

  static List<StaffAppointment> appointmentsFrom(dynamic body) {
    if (body == null) return const [];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final items = <({StaffAppointment appointment, DateTime? at})>[];
    for (final item in JsonCodec.unwrapList(body).whereType<Map>()) {
      final json = JsonCodec.asMap(item);
      final at = JsonCodec.dateTime(
        json['scheduledAt'] ??
            json['startsAt'] ??
            json['startAt'] ??
            json['date'],
      );
      final status = (JsonCodec.string(json['status']) ?? '').toLowerCase();
      if (status == 'completed' ||
          status == 'done' ||
          status == 'cancelled' ||
          status == 'canceled' ||
          status == 'rejected' ||
          status == 'declined') {
        continue;
      }
      // Upcoming section: drop past calendar days.
      if (at != null) {
        final local = at.toLocal();
        final day = DateTime(local.year, local.month, local.day);
        if (day.isBefore(todayStart)) continue;
      }

      items.add((
        appointment: StaffAppointment(
          id: JsonCodec.stringOr(json['id'], json['title'] ?? 'appointment'),
          title: _appointmentTitle(json),
          dateTimeLabel: at == null
              ? JsonCodec.stringOr(json['dateLabel'], '')
              : IsoDateRange.dateTimeLabel(at.toLocal()),
          location: JsonCodec.stringOr(
            json['location'] ??
                json['mode'] ??
                json['clientName'] ??
                JsonCodec.mapAt(json, 'client')?['name'],
            '',
          ),
          statusLabel: switch (status) {
            'approved' || 'upcoming' || 'scheduled' => 'Upcoming',
            'pending' => 'Pending',
            _ => status.isEmpty
                ? (at != null && at.isAfter(now) ? 'Upcoming' : 'Scheduled')
                : '${status[0].toUpperCase()}${status.substring(1)}',
          },
        ),
        at: at,
      ));
    }

    items.sort((a, b) {
      final aAt = a.at;
      final bAt = b.at;
      if (aAt == null && bAt == null) return 0;
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      return aAt.compareTo(bAt);
    });
    return [for (final item in items) item.appointment];
  }

  static String _appointmentTitle(Map<String, dynamic> json) {
    final explicit = JsonCodec.string(json['title'] ?? json['purpose']);
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final type = (JsonCodec.string(json['type']) ?? '').toLowerCase().trim();
    return switch (type) {
      'family_visit' || 'visit' || 'family' => 'Family Visit',
      'therapy' => 'Therapy',
      'activity' => 'Activity',
      'medical' || 'appointment' => 'Medical Appointment',
      '' => 'Appointment',
      _ => type
          .split(RegExp(r'[_\s]+'))
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' '),
    };
  }

  const StaffScheduleMapper._();
}
