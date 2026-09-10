import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_overview.dart';
import '../../domain/repositories/attendance_repository.dart';

/// GetX controller for the "Attendance" screen.
class AttendanceController extends BaseController<AttendanceOverview> {
  final AttendanceRepository repository;

  final Rx<AttendanceTab> selectedTab = AttendanceTab.today.obs;

  /// Inclusive local calendar day range driving every tab's data.
  final Rx<DateTime> rangeStart = IsoDateRange.startOfLocalDay().obs;
  final Rx<DateTime> rangeEnd = IsoDateRange.startOfLocalDay().obs;

  int _loadGeneration = 0;

  AttendanceController({required this.repository}) {
    loadOverview();
  }

  AttendanceOverview? get overview => state.value.data;

  void selectTab(AttendanceTab tab) => selectedTab.value = tab;

  Future<void> loadOverview() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getOverview(
      from: rangeStart.value,
      to: rangeEnd.value,
    );
    if (generation != _loadGeneration) return;
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  /// Calendar icon: pick a date range, then reload all tabs for that window.
  Future<void> pickRangeAndReload(BuildContext context) async {
    final now = DateTime.now();
    final weekStart = IsoDateRange.startOfWeek();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final singleDay = _isSameDay(rangeStart.value, rangeEnd.value);
    final selected = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 14)),
      initialDateRange: DateTimeRange(
        start: singleDay ? weekStart : rangeStart.value,
        end: singleDay ? weekEnd : rangeEnd.value,
      ),
      helpText: 'Select attendance range',
    );
    if (selected == null) return;

    rangeStart.value = DateTime(
      selected.start.year,
      selected.start.month,
      selected.start.day,
    );
    rangeEnd.value = DateTime(
      selected.end.year,
      selected.end.month,
      selected.end.day,
    );
    await loadOverview();
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> reviewMissedClockIn(String attendanceId) async {
    final result = await repository.approveAttendance(attendanceId);
    result.when(
      success: (_) => loadOverview(),
      failure: (error) {
        AppSnackbar.show(
          'Could not review',
          error.message,
        );
      },
    );
  }

  @override
  Future<void> refresh() => loadOverview();
}
