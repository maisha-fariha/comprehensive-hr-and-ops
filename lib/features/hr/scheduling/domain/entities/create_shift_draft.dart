import 'dart:convert';

import '../../../../../core/time/tenant_clock.dart';
import 'shift_staff_option.dart';
import 'shift_type_option.dart';

/// Wizard steps of the web "Add New Shift" dialog, in order.
enum CreateShiftStep {
  shiftInformation,
  staffAssignment,
  openShift,
  recurring,
  notifications,
}

/// "Ends" rule for a recurring shift.
enum ShiftRecurrenceEnd {
  onDate('on_date', 'On a specific date'),
  afterCount('after_count', 'After a number of occurrences');

  final String value;
  final String label;

  const ShiftRecurrenceEnd(this.value, this.label);
}

/// A value/label pair for the fixed Create Shift dropdowns.
class ShiftFormChoice<T> {
  final T value;
  final String label;

  const ShiftFormChoice(this.value, this.label);
}

/// A weekday circle on the Recurring step. [value] uses Sunday = 0.
class ShiftWeekdayChoice {
  final int value;
  final String label;
  final String name;

  const ShiftWeekdayChoice(this.value, this.label, this.name);
}

/// Option lists shared with the web shift form.
abstract final class CreateShiftChoices {
  static const List<ShiftFormChoice<String>> priorities = [
    ShiftFormChoice('low', 'Low'),
    ShiftFormChoice('medium', 'Medium'),
    ShiftFormChoice('high', 'High'),
  ];

  static const List<ShiftFormChoice<String>> awardMethods = [
    ShiftFormChoice('manual', 'Manager selects winner'),
    ShiftFormChoice('first_come', 'First come, first served'),
    ShiftFormChoice('seniority', 'Seniority-based'),
  ];

  static const List<ShiftFormChoice<int>> frequencies = [
    ShiftFormChoice(1, 'Daily'),
    ShiftFormChoice(7, 'Weekly'),
    ShiftFormChoice(14, 'Bi-Weekly'),
    ShiftFormChoice(28, 'Monthly'),
  ];

  /// Web Notifications → Reminder options (`reminderMinutesBefore`).
  static const List<ShiftFormChoice<int?>> reminders = [
    ShiftFormChoice(null, 'No reminder'),
    ShiftFormChoice(15, '15 minutes before'),
    ShiftFormChoice(30, '30 minutes before'),
    ShiftFormChoice(60, '1 hour before'),
    ShiftFormChoice(120, '2 hours before'),
    ShiftFormChoice(240, '4 hours before'),
    ShiftFormChoice(1440, '24 hours before'),
    ShiftFormChoice(2880, '48 hours before'),
  ];

  static const List<ShiftWeekdayChoice> weekdays = [
    ShiftWeekdayChoice(0, 'S', 'Sunday'),
    ShiftWeekdayChoice(1, 'M', 'Monday'),
    ShiftWeekdayChoice(2, 'T', 'Tuesday'),
    ShiftWeekdayChoice(3, 'W', 'Wednesday'),
    ShiftWeekdayChoice(4, 'T', 'Thursday'),
    ShiftWeekdayChoice(5, 'F', 'Friday'),
    ShiftWeekdayChoice(6, 'S', 'Saturday'),
  ];

  static String labelOf<T>(List<ShiftFormChoice<T>> choices, T value) {
    for (final choice in choices) {
      if (choice.value == value) return choice.label;
    }
    return '';
  }
}

/// Field keys used for validation messages.
abstract final class CreateShiftField {
  static const residenceId = 'residenceId';
  static const shiftType = 'shiftType';
  static const shiftDate = 'shiftDate';
  static const startTime = 'startTime';
  static const endTime = 'endTime';
  static const assignedStaff = 'assignedStaff';
  static const biddingDeadline = 'biddingDeadlineDate';
  static const endDate = 'endDate';
  static const occurrenceCount = 'occurrenceCount';
  static const restOverrideReason = 'restOverrideReason';
}

class ShiftChecklistItem {
  final String id;
  final String label;
  bool done;

  ShiftChecklistItem({required this.id, required this.label, this.done = false});
}

/// A staff member on the shift with their (UI-only) task details.
class AssignedShiftStaff {
  final String staffId;
  final String staffName;
  final String roleLabel;
  final String residenceLabel;
  final String initials;
  String taskTitle = '';
  String taskDescription = '';
  String note = '';
  final List<ShiftChecklistItem> checklist = [];

  AssignedShiftStaff({
    required this.staffId,
    required this.staffName,
    this.roleLabel = '',
    this.residenceLabel = '',
  }) : initials = initialsOf(staffName);

  factory AssignedShiftStaff.fromOption(ShiftStaffOption option) {
    return AssignedShiftStaff(
      staffId: option.id,
      staffName: option.name,
      roleLabel: option.role ?? '',
      residenceLabel: option.residenceLabel ?? '',
    );
  }

  String get subtitle {
    final parts = [roleLabel, residenceLabel].where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'No category recorded' : parts.join(' · ');
  }

  static String initialsOf(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }
}

/// Mutable form state of the Add New Shift wizard. Rules mirror the web
/// `shiftFormSchema`, `plannedOccurrences` and `toCreateBody`.
class CreateShiftDraft {
  static const int maxOccurrences = 52;

  static const Map<CreateShiftStep, List<String>> stepFields = {
    CreateShiftStep.shiftInformation: [
      CreateShiftField.residenceId,
      CreateShiftField.shiftType,
      CreateShiftField.shiftDate,
      CreateShiftField.startTime,
      CreateShiftField.endTime,
    ],
    CreateShiftStep.staffAssignment: [
      CreateShiftField.assignedStaff,
      CreateShiftField.biddingDeadline,
    ],
    CreateShiftStep.openShift: [],
    CreateShiftStep.recurring: [],
    CreateShiftStep.notifications: [],
  };

  String residenceId;
  String shiftType;
  DateTime? shiftDate;

  /// Minutes since midnight; `null` when the time input is empty.
  int? startMinutes;
  int? endMinutes;
  int breakMinutes = 30;
  String title = '';
  String notes = '';

  /// `null` is "Not one-to-one". Sent as `oneToOneClientId`.
  String? oneToOneClientId;
  String? oneToOneClientName;

  final List<AssignedShiftStaff> assignedStaff = [];

  bool isOpenShift = false;
  String requiredStaffCount = '1';
  DateTime? biddingDeadlineDate;
  int? biddingDeadlineMinutes = 18 * 60;
  String maxBids = '10';
  String priority = 'medium';
  String awardMethod = 'manual';
  String noteToBidders = '';

  bool isRecurring = false;
  int recurrenceFrequency = 7;
  final Set<int> repeatOnDays = {};
  ShiftRecurrenceEnd ends = ShiftRecurrenceEnd.afterCount;
  DateTime? endDate;
  String occurrenceCount = '4';

  bool notifyAssignedStaff = true;

  /// New shifts remind 2 hours before (web `reminderTiming: "120"`).
  int? reminderMinutes = 120;
  String notificationMessage = '';

  /// Required when `POST /shifts/conflicts` returns `rest[]` (web audit field).
  String restOverrideReason = '';

  /// Loaded from `GET /shifts/{id}` — used to show Publish Shift for drafts.
  String? loadedStatus;

  /// Staff ids at load time — skip assignment PUT when unchanged (avoids
  /// duplicate notify on publish/save).
  List<String> loadedStaffIds = const [];

  CreateShiftDraft({String? residenceId, DateTime? shiftDate})
      : residenceId = residenceId ?? '',
        shiftType = ShiftTypeOption.predefined.first.id,
        shiftDate = shiftDate == null
            ? null
            : DateTime(shiftDate.year, shiftDate.month, shiftDate.day) {
    final first = ShiftTypeOption.predefined.first;
    startMinutes = first.startHour! * 60 + first.startMinute!;
    endMinutes = first.endHour! * 60 + first.endMinute!;
  }

  ShiftTypeOption? get shiftTypeOption {
    for (final option in ShiftTypeOption.predefined) {
      if (option.id == shiftType) return option;
    }
    return null;
  }

  /// Picking a non-custom type fills in its start and end times.
  void applyShiftType(ShiftTypeOption option) {
    shiftType = option.id;
    if (option.id != 'custom' && option.hasPresetTimes) {
      startMinutes = option.startHour! * 60 + option.startMinute!;
      endMinutes = option.endHour! * 60 + option.endMinute!;
    }
  }

  bool _hasValue(String field) => switch (field) {
        CreateShiftField.residenceId => residenceId.isNotEmpty,
        CreateShiftField.shiftType => shiftType.isNotEmpty,
        CreateShiftField.shiftDate => shiftDate != null,
        CreateShiftField.startTime => startMinutes != null,
        CreateShiftField.endTime => endMinutes != null,
        CreateShiftField.assignedStaff => assignedStaff.isNotEmpty,
        _ => false,
      };

  bool isStepComplete(CreateShiftStep step) {
    if (step == CreateShiftStep.openShift) {
      // Merged into staffAssignment (Assign Staff | Open Shift toggle).
      return true;
    }
    if (step == CreateShiftStep.staffAssignment) {
      return isOpenShift || assignedStaff.isNotEmpty;
    }
    final fields = stepFields[step]!;
    return fields.isNotEmpty && fields.every(_hasValue);
  }

  int get completedSteps =>
      CreateShiftStep.values.where(isStepComplete).length;

  int get completionPercent =>
      (completedSteps / CreateShiftStep.values.length * 100).round();

  /// All schema errors keyed by [CreateShiftField].
  Map<String, String> validate() {
    final errors = <String, String>{};
    if (residenceId.isEmpty) {
      errors[CreateShiftField.residenceId] = 'Select a residence';
    }
    if (shiftType.isEmpty) {
      errors[CreateShiftField.shiftType] = 'Select a shift type';
    }
    if (shiftDate == null) {
      errors[CreateShiftField.shiftDate] = 'Shift date is required';
    }
    if (startMinutes == null) {
      errors[CreateShiftField.startTime] = 'Start time is required';
    }
    if (endMinutes == null) {
      errors[CreateShiftField.endTime] = 'End time is required';
    } else if (startMinutes != null && startMinutes == endMinutes) {
      // Equal times are invalid; end before start is overnight (rolls +1 day).
      errors[CreateShiftField.endTime] =
          'A shift cannot end at the moment it starts';
    }
    if (isRecurring &&
        ends == ShiftRecurrenceEnd.onDate &&
        endDate == null) {
      errors[CreateShiftField.endDate] = 'Pick the date it stops';
    }
    if (isRecurring &&
        ends == ShiftRecurrenceEnd.afterCount &&
        _number(occurrenceCount) == 0) {
      errors[CreateShiftField.occurrenceCount] = 'Say how many shifts to create';
    }
    if (isOpenShift && biddingDeadlineDate != null) {
      final deadline = TenantClock.at(
        biddingDeadlineDate!,
        biddingDeadlineMinutes ?? (23 * 60 + 59),
      );
      if (deadline.isBefore(DateTime.now())) {
        errors[CreateShiftField.biddingDeadline] =
            'Bidding deadline cannot be in the past';
      } else if (shiftDate != null && startMinutes != null) {
        final start = TenantClock.at(shiftDate!, startMinutes!);
        if (deadline.isAfter(start)) {
          errors[CreateShiftField.biddingDeadline] =
              'Bidding deadline cannot be after the shift begins';
        }
      }
    }
    return errors;
  }

  /// Errors the "Next" button reports for [step].
  Map<String, String> validateStep(CreateShiftStep step) {
    if (step == CreateShiftStep.staffAssignment) {
      final bidding = validate()[CreateShiftField.biddingDeadline];
      if (isOpenShift) {
        if (bidding == null) return const {};
        return {CreateShiftField.biddingDeadline: bidding};
      }
      if (assignedStaff.isEmpty) {
        return {
          CreateShiftField.assignedStaff: 'Assign at least one staff member',
        };
      }
      return const {};
    }
    final fields = stepFields[step]!;
    if (fields.isEmpty) return const {};
    final all = validate();
    return {
      for (final entry in all.entries)
        if (fields.contains(entry.key)) entry.key: entry.value,
    };
  }

  static CreateShiftStep stepOf(String field) {
    for (final entry in stepFields.entries) {
      if (entry.value.contains(field)) return entry.key;
    }
    return CreateShiftStep.recurring;
  }

  /// How many shifts the create call will produce.
  int plannedOccurrences() {
    if (!isRecurring) return 1;
    if (ends == ShiftRecurrenceEnd.afterCount) {
      final count = _number(occurrenceCount).truncate();
      return (count < 1 ? 1 : count).clamp(1, maxOccurrences);
    }
    return _plannedUntilEndDate();
  }

  int _plannedUntilEndDate() {
    final interval = recurrenceFrequency == 0 ? 7 : recurrenceFrequency;
    final date = shiftDate;
    final until = endDate;
    if (date == null || until == null) return 0;
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(until.year, until.month, until.day, 23, 59);
    if (end.isBefore(start)) return 0;
    const dayMs = 86400000;
    final span =
        (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) ~/ dayMs +
            1;
    if (repeatOnDays.isEmpty) {
      return (span / interval).ceil().clamp(0, maxOccurrences);
    }
    final weekGap = (interval / 7).round() < 1 ? 1 : (interval / 7).round();
    var count = 0;
    for (var day = 0; day < span && count < maxOccurrences; day++) {
      if ((day ~/ 7) % weekGap != 0) continue;
      final current = DateTime.fromMillisecondsSinceEpoch(
        start.millisecondsSinceEpoch + dayMs * day,
      );
      if (repeatOnDays.contains(current.weekday % 7)) count++;
    }
    return count;
  }

  /// Local start/end of the draft shift window (web `shiftWindow`), or null
  /// when date/times are incomplete.
  (DateTime startsAt, DateTime endsAt)? get shiftWindow {
    final date = shiftDate;
    final start = startMinutes;
    final end = endMinutes;
    if (date == null || start == null || end == null) return null;
    final startsAt = _at(date, start);
    var endsAt = _at(date, end);
    if (!endsAt.isAfter(startsAt)) {
      endsAt = endsAt.add(const Duration(days: 1));
    }
    return (startsAt, endsAt);
  }

  /// `POST /shifts` body, field-for-field with the web `toCreateBody`.
  ///
  /// When [asDraft] is true, sends `status: draft` (web "Save as draft") so
  /// the shift is stored without going live / open for bids.
  Map<String, dynamic> toCreateBody({bool asDraft = false}) {
    final window = shiftWindow!;
    final startsAt = window.$1;
    final endsAt = window.$2;

    Map<String, dynamic>? biddingConfig;
    if (isOpenShift) {
      final deadline = biddingDeadlineDate;
      final bids = _number(maxBids);
      final note = noteToBidders.trim();
      biddingConfig = {
        if (deadline != null)
          'biddingClosesAt': _iso(
            _at(deadline, biddingDeadlineMinutes ?? (23 * 60 + 59)),
          ),
        if (bids != 0) 'maxBids': _jsonNumber(bids),
        if (priority.isNotEmpty) 'priority': priority,
        if (awardMethod.isNotEmpty) 'awardMethod': awardMethod,
        if (note.isNotEmpty) 'noteToBidders': note,
      };
    }

    final message = notificationMessage.trim();
    final trimmedTitle = title.trim();
    final trimmedNotes = notes.trim();
    final staffCount = _number(requiredStaffCount);

    return {
      'residenceId': residenceId,
      'oneToOneClientId': oneToOneClientId,
      'startsAt': _iso(startsAt),
      'endsAt': _iso(endsAt),
      // Web keeps any pre-assigned staff on open shifts (partially filled opens).
      'staffIds': [for (final staff in assignedStaff) staff.staffId],
      'shiftType': shiftType,
      'breakMinutes': breakMinutes,
      'open': asDraft ? false : isOpenShift,
      if (asDraft) 'status': 'draft',
      if (!asDraft && isOpenShift)
        'requiredStaffCount': staffCount == 0 ? null : _jsonNumber(staffCount),
      'reminderMinutesBefore': reminderMinutes,
      'notifyAssignedStaff': asDraft ? false : notifyAssignedStaff,
      if (message.isNotEmpty) 'notificationMessage': message,
      if (trimmedTitle.isNotEmpty) 'title': trimmedTitle,
      if (trimmedNotes.isNotEmpty) 'notes': trimmedNotes,
      if (restOverrideReason.trim().isNotEmpty)
        'restOverrideReason': restOverrideReason.trim(),
      if (!asDraft) 'biddingConfig': biddingConfig,
      if (!asDraft && isRecurring)
        'recurrence': {
          'occurrences': plannedOccurrences(),
          'intervalDays': recurrenceFrequency == 0 ? 7 : recurrenceFrequency,
          if (repeatOnDays.isNotEmpty)
            'weekdays': repeatOnDays.toList()..sort(),
        },
    };
  }

  /// `PATCH /shifts/{id}` body: the create body minus the fields the web
  /// strips on edit (assignments go through `PUT /shifts/{id}/assignments`).
  Map<String, dynamic> toUpdateBody({bool publishDraft = false}) {
    // Keep draft status on Save changes; only Publish Shift promotes it.
    final body = toCreateBody(asDraft: !publishDraft && isLoadedDraft)
      ..remove('staffIds')
      ..remove('recurrence')
      ..remove('tasks');
    if (publishDraft) {
      // Web "Publish Shift": draft → scheduled (same default as create) + notify.
      body['status'] = 'scheduled';
      body['notifyAssignedStaff'] = notifyAssignedStaff;
    } else {
      body.remove('notifyAssignedStaff');
    }
    return body;
  }

  bool get isLoadedDraft =>
      (loadedStatus ?? '').toLowerCase() == 'draft';

  /// Every user-editable value; differs from the initial snapshot when the
  /// form has unsaved edits.
  String snapshot() => jsonEncode({
        'residenceId': residenceId,
        'shiftType': shiftType,
        'shiftDate': shiftDate?.toIso8601String(),
        'start': startMinutes,
        'end': endMinutes,
        'break': breakMinutes,
        'oneToOneClientId': oneToOneClientId,
        'title': title,
        'notes': notes,
        'staff': [
          for (final staff in assignedStaff)
            {
              'id': staff.staffId,
              'taskTitle': staff.taskTitle,
              'taskDescription': staff.taskDescription,
              'note': staff.note,
              'checklist': [
                for (final item in staff.checklist) [item.label, item.done],
              ],
            },
        ],
        'open': isOpenShift,
        'requiredStaffCount': requiredStaffCount,
        'deadlineDate': biddingDeadlineDate?.toIso8601String(),
        'deadlineTime': biddingDeadlineMinutes,
        'maxBids': maxBids,
        'priority': priority,
        'awardMethod': awardMethod,
        'noteToBidders': noteToBidders,
        'recurring': isRecurring,
        'frequency': recurrenceFrequency,
        'days': repeatOnDays.toList()..sort(),
        'ends': ends.value,
        'endDate': endDate?.toIso8601String(),
        'occurrenceCount': occurrenceCount,
        'notify': notifyAssignedStaff,
        'reminder': reminderMinutes,
        'message': notificationMessage,
        'restOverrideReason': restOverrideReason,
      });

  static DateTime _at(DateTime date, int minutes) =>
      TenantClock.at(date, minutes);

  static String _iso(DateTime instant) => instant.toUtc().toIso8601String();

  /// JS `Number(value)` with `NaN` folded to 0.
  static num _number(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    final parsed = num.tryParse(trimmed);
    if (parsed == null || parsed.isNaN) return 0;
    return parsed;
  }

  static num _jsonNumber(num value) =>
      value == value.truncate() ? value.toInt() : value;
}
