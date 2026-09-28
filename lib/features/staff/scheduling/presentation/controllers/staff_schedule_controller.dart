import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_schedule_overview.dart';
import '../../domain/entities/staff_shift.dart';
import '../../domain/entities/week_day.dart';
import '../../domain/repositories/staff_schedule_repository.dart';

/// GetX controller for the "My Schedule" screen.
class StaffScheduleController extends BaseController<StaffScheduleOverview> {
  final StaffScheduleRepository repository;

  /// Monday of the week currently displayed.
  final Rx<DateTime> weekStart =
      IsoDateRange.startOfWeek(DateTime.now()).obs;

  /// Selected day chip within [weekStart]'s week.
  final Rx<DateTime> selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;

  /// BUG_Report004 — optional status filter (`null` = all).
  final RxnString statusFilter = RxnString();

  StaffScheduleController({required this.repository});

  StaffScheduleOverview? get overview => state.value.data;

  /// Shifts that start on the selected day (falls back to full week if none
  /// have parseable dates), then optionally filtered by [statusFilter].
  List<StaffShift> get shiftsForSelectedDay {
    final all = overview?.shifts ?? const <StaffShift>[];
    final day = selectedDate.value;
    var filtered = all.where((shift) {
      final start = shift.startAt;
      if (start == null) return false;
      return start.year == day.year &&
          start.month == day.month &&
          start.day == day.day;
    }).toList();
    if (filtered.isEmpty && all.any((s) => s.startAt == null)) {
      filtered = List<StaffShift>.from(all);
    }
    final status = statusFilter.value?.toLowerCase();
    if (status == null || status.isEmpty || status == 'all') {
      return filtered;
    }
    return filtered
        .where((shift) => shift.statusLabel.toLowerCase().contains(status))
        .toList();
  }

  String get selectedDayShiftsLabel {
    final count = shiftsForSelectedDay.length;
    return count == 1 ? '1 shift' : '$count shifts';
  }

  @override
  void onInit() {
    super.onInit();
    final today = DateTime.now();
    final start = weekStart.value;
    final end = start.add(const Duration(days: 6));
    final todayDate = DateTime(today.year, today.month, today.day);
    if (!todayDate.isBefore(start) && !todayDate.isAfter(end)) {
      selectedDate.value = todayDate;
    } else {
      selectedDate.value = start;
    }
    loadOverview();
  }

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview(
      weekStart: weekStart.value,
      selectedDate: selectedDate.value,
    );
    result.when(
      success: (overview) {
        setSuccess(overview);
        if (overview.loadWarnings.isNotEmpty) {
          AppSnackbar.show(
            'Some schedule data missing',
            overview.loadWarnings.join(' '),
          );
        }
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> goToPreviousWeek() async {
    weekStart.value = weekStart.value.subtract(const Duration(days: 7));
    selectedDate.value = weekStart.value;
    await loadOverview();
  }

  Future<void> goToNextWeek() async {
    weekStart.value = weekStart.value.add(const Duration(days: 7));
    selectedDate.value = weekStart.value;
    await loadOverview();
  }

  void selectDay(WeekDay day) {
    final date = DateTime(day.date.year, day.date.month, day.date.day);
    if (selectedDate.value == date) return;
    selectedDate.value = date;
    final current = overview;
    if (current == null) return;
    setSuccess(
      current.copyWith(
        weekDays: [
          for (final d in current.weekDays)
            d.copyWith(
              isSelected: d.date.year == date.year &&
                  d.date.month == date.month &&
                  d.date.day == date.day,
            ),
        ],
      ),
    );
  }

  /// Refresh one card from `GET /shifts/{id}` (avatars / filled counts).
  Future<void> openShiftDetail(StaffShift shift) async {
    final result = await repository.getShiftDetail(shift.id);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not load shift',
      );
      return;
    }
    final detail = result.value!;
    final current = overview;
    if (current == null) return;
    setSuccess(
      current.copyWith(
        shifts: [
          for (final item in current.shifts)
            item.id == detail.id ? detail : item,
        ],
      ),
    );
  }

  Future<void> requestOpenShift(String shiftId, {String? note}) async {
    setLoading(true);
    final result = await repository.bidOnShift(shiftId, note: note);
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not request shift',
      );
      return;
    }
    AppSnackbar.show('Shift request sent', 'Your bid was submitted.');
    await loadOverview();
  }

  Future<void> requestCoverSwap(StaffShift shift) async {
    final note = await _promptNote(
      title: 'Request cover',
      hint: 'Why do you need cover for this shift?',
    );
    if (note == null) return;

    setLoading(true);
    final result = await repository.requestSwap(
      fromShiftId: shift.id,
      note: note.isEmpty ? null : note,
    );
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not request swap',
      );
      return;
    }
    AppSnackbar.show('Swap requested', 'Waiting for manager approval.');
    await loadOverview();
  }

  Future<void> respondToSwap({
    required String swapId,
    required bool accepted,
  }) async {
    setLoading(true);
    final result = await repository.respondToSwap(
      swapId: swapId,
      accepted: accepted,
    );
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: accepted
            ? 'Could not accept swap'
            : 'Could not decline swap',
      );
      return;
    }
    AppSnackbar.show(
      accepted ? 'Swap accepted' : 'Swap declined',
      accepted
          ? 'Sent to a manager for final decision.'
          : 'The requester was notified.',
    );
    await loadOverview();
  }

  Future<void> cancelSwap(String swapId) async {
    setLoading(true);
    final result = await repository.cancelSwap(swapId);
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not cancel request',
      );
      return;
    }
    AppSnackbar.show('Request cancelled', 'Your swap request was withdrawn.');
    await loadOverview();
  }

  void setStatusFilter(String? status) {
    statusFilter.value =
        (status == null || status.isEmpty || status == 'all') ? null : status;
  }

  Future<void> showFilterSheet() async {
    final current = statusFilter.value ?? 'all';
    final selected = await Get.bottomSheet<String>(
      SafeArea(
        child: Container(
          key: const Key('staff-schedule-filter-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Filter shifts',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              for (final option in const [
                'all',
                'scheduled',
                'open',
                'completed',
              ])
                ListTile(
                  title: Text(
                    option == 'all'
                        ? 'All statuses'
                        : option[0].toUpperCase() + option.substring(1),
                  ),
                  trailing: current == option
                      ? const Icon(Icons.check_rounded, color: Color(0xFF0E7C7B))
                      : null,
                  onTap: () => Get.back(result: option),
                ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
    if (selected != null) setStatusFilter(selected);
  }

  Future<void> showCreateShiftDialog() async {
    final session = Get.find<UserSession>();
    final residenceId = session.residenceId;
    if (residenceId == null || residenceId.isEmpty) {
      AppSnackbar.show(
        'Residence required',
        'Assign a residence before creating a shift.',
      );
      return;
    }

    final titleController = TextEditingController(text: 'Coverage shift');
    final date = selectedDate.value;
    final dateLabel =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    var startTime = '09:00';
    var endTime = '17:00';

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Create Shift'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('staff-create-shift-title'),
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                Text('Date: $dateLabel'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const Key('staff-create-shift-start'),
                  initialValue: startTime,
                  decoration: const InputDecoration(labelText: 'Start'),
                  items: const [
                    DropdownMenuItem(value: '07:00', child: Text('07:00')),
                    DropdownMenuItem(value: '09:00', child: Text('09:00')),
                    DropdownMenuItem(value: '14:00', child: Text('14:00')),
                    DropdownMenuItem(value: '22:00', child: Text('22:00')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => startTime = value);
                  },
                ),
                DropdownButtonFormField<String>(
                  key: const Key('staff-create-shift-end'),
                  initialValue: endTime,
                  decoration: const InputDecoration(labelText: 'End'),
                  items: const [
                    DropdownMenuItem(value: '15:00', child: Text('15:00')),
                    DropdownMenuItem(value: '17:00', child: Text('17:00')),
                    DropdownMenuItem(value: '22:00', child: Text('22:00')),
                    DropdownMenuItem(value: '07:00', child: Text('07:00')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => endTime = value);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('staff-create-shift-submit'),
            onPressed: () => Get.back(result: true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    final title = titleController.text.trim();
    titleController.dispose();
    if (confirmed != true) return;

    setLoading(true);
    final result = await repository.createShift(
      residenceId: residenceId,
      shiftDate: dateLabel,
      startTime: startTime,
      endTime: endTime,
      title: title.isEmpty ? null : title,
    );
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not create shift',
      );
      return;
    }
    AppSnackbar.show('Shift created', 'Your shift was added to the schedule.');
    await loadOverview();
  }

  Future<String?> _promptNote({
    required String title,
    required String hint,
  }) async {
    final field = TextEditingController();
    final submitted = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: TextField(
          controller: field,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    final text = field.text.trim();
    field.dispose();
    if (submitted != true) return null;
    return text;
  }

  @override
  Future<void> refresh() => loadOverview();
}
