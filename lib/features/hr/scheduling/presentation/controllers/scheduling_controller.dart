import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../data/mappers/scheduling_mapper.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../../domain/entities/shift_request.dart';
import '../../domain/repositories/scheduling_repository.dart';

/// GetX controller for the HR/Manager Scheduling screen.
class SchedulingController extends BaseController<SchedulingOverview> {
  final SchedulingRepository repository;

  final Rx<SchedulingTab> selectedTab = SchedulingTab.calendar.obs;

  /// Monday (local) of the week shown on the Calendar week strip.
  final Rx<DateTime> weekOf = IsoDateRange.startOfWeek().obs;

  /// Currently selected day on the week strip.
  final Rx<DateTime> selectedDay = _todayLocal().obs;

  /// True only after the user taps a day cell. Cleared when Schedule is
  /// re-opened from login / another bottom-nav screen so today is selected.
  bool _userPickedDay = false;

  int _loadGeneration = 0;

  SchedulingController({required this.repository}) {
    loadOverview();
  }

  SchedulingOverview? get overview => state.value.data;

  static DateTime _todayLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void selectTab(SchedulingTab tab) => selectedTab.value = tab;

  /// Call when the Schedule tab becomes visible (login, shell open, or
  /// bottom-nav switch). Resets the week strip to today until the user
  /// manually picks another day again.
  Future<void> resetCalendarToToday() async {
    final today = _todayLocal();
    final currentWeek = IsoDateRange.startOfWeek(today);
    final sameWeek = _isSameDay(weekOf.value, currentWeek);

    _userPickedDay = false;
    weekOf.value = currentWeek;
    selectedDay.value = today;

    final current = overview;
    if (sameWeek && current != null) {
      setSuccess(
        current.copyWith(
          calendar: SchedulingMapper.calendarForSelectedDay(
            current: current.calendar,
            selectedDay: today,
          ),
        ),
      );
      return;
    }

    await loadOverview();
  }

  Future<void> loadOverview() async {
    final generation = ++_loadGeneration;
    setLoading(true);

    // Until the user picks a day, always request today's selection when the
    // visible week contains today.
    if (!_userPickedDay) {
      final today = _todayLocal();
      final start = weekOf.value;
      final end = start.add(const Duration(days: 6));
      if (!today.isBefore(start) && !today.isAfter(end)) {
        selectedDay.value = today;
      }
    }

    final requestedWeek = weekOf.value;
    final requestedDay = selectedDay.value;
    final result = await repository.getOverview(
      weekOf: requestedWeek,
      selectedDay: requestedDay,
    );
    if (generation != _loadGeneration) return;

    result.when(
      success: (data) {
        if (!_userPickedDay) {
          final today = _todayLocal();
          final matchedToday = data.calendar.days.any(
            (day) => day.isSelected && _isSameDay(day.date, today),
          );
          if (matchedToday) {
            selectedDay.value = today;
          } else {
            for (final day in data.calendar.days) {
              if (day.isSelected) {
                selectedDay.value = day.date;
                break;
              }
            }
          }
        }
        setSuccess(data);
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  /// Previous week — refetches `/shifts` for the new range.
  Future<void> goToPreviousWeek() {
    weekOf.value = weekOf.value.subtract(const Duration(days: 7));
    _syncSelectionAfterWeekChange();
    return loadOverview();
  }

  /// Next week — refetches `/shifts` for the new range.
  Future<void> goToNextWeek() {
    weekOf.value = weekOf.value.add(const Duration(days: 7));
    _syncSelectionAfterWeekChange();
    return loadOverview();
  }

  void _syncSelectionAfterWeekChange() {
    final today = _todayLocal();
    final start = weekOf.value;
    final end = start.add(const Duration(days: 6));

    if (!_userPickedDay) {
      // Prefer today when browsing back to the current week.
      if (!today.isBefore(start) && !today.isAfter(end)) {
        selectedDay.value = today;
      } else {
        selectedDay.value = start;
      }
      return;
    }

    // Keep a manually picked day only if it still falls in this week.
    final picked = selectedDay.value;
    if (picked.isBefore(start) || picked.isAfter(end)) {
      selectedDay.value = start;
    }
  }

  /// Selects a day on the week strip without refetching when that day is
  /// already inside the loaded week.
  void selectCalendarDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    _userPickedDay = true;

    final current = overview;
    if (current == null) {
      selectedDay.value = date;
      loadOverview();
      return;
    }

    final inLoadedWeek = current.calendar.days.any(
      (d) => _isSameDay(d.date, date),
    );
    if (!inLoadedWeek) {
      weekOf.value = IsoDateRange.startOfWeek(date);
      selectedDay.value = date;
      loadOverview();
      return;
    }

    selectedDay.value = date;
    setSuccess(
      current.copyWith(
        calendar: SchedulingMapper.calendarForSelectedDay(
          current: current.calendar,
          selectedDay: date,
        ),
      ),
    );
  }

  @override
  Future<void> refresh() => loadOverview();

  Future<void> approveRequest(ShiftRequest request) =>
      _decideSwap(request, approve: true);

  Future<void> declineRequest(ShiftRequest request) =>
      _decideSwap(request, approve: false);

  Future<void> _decideSwap(ShiftRequest request, {required bool approve}) async {
    if (!request.canManagerDecide) {
      AppSnackbar.show(
        approve ? 'Cannot approve yet' : 'Cannot decline yet',
        'The colleague asked has not answered yet.',
      );
      return;
    }

    final result = await repository.decideShiftSwap(
      swapId: request.id,
      approve: approve,
    );
    result.when(
      success: (_) => loadOverview(),
      failure: (error) {
        AppSnackbar.show(
          approve ? 'Could not approve' : 'Could not decline',
          error.message,
        );
      },
    );
  }
}
