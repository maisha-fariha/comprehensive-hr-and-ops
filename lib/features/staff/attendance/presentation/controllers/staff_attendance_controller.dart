import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../hr/attendance/domain/entities/manual_entry_options.dart';
import '../../domain/entities/staff_attendance_history_item.dart';
import '../../domain/entities/staff_attendance_overview.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../pages/staff_manual_attendance_entry_page.dart';
import '../widgets/staff_clock_action_sheet.dart';

/// GetX controller for the "Attendance" screen.
class StaffAttendanceController
    extends BaseController<StaffAttendanceOverview> {
  final StaffAttendanceRepository repository;

  /// Live HH:MM:SS from [StaffAttendanceOverview.checkInAt].
  final RxString liveElapsedLabel = '00:00:00'.obs;

  /// Residence options for filters + clock dialog.
  final RxList<ManualEntryResidenceOption> residenceOptions =
      <ManualEntryResidenceOption>[].obs;

  Timer? _ticker;

  StaffAttendanceController({required this.repository});

  StaffAttendanceOverview? get overview => state.value.data;

  @override
  void onInit() {
    super.onInit();
    loadOverview();
    _loadResidences();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: (overview) {
        setSuccess(overview);
        liveElapsedLabel.value = overview.elapsedTimeLabel;
        _restartTicker(overview.checkInAt);
      },
      failure: (error) {
        _ticker?.cancel();
        setError(error.message);
      },
    );
    setLoading(false);
  }

  void _restartTicker(DateTime? checkInAt) {
    _ticker?.cancel();
    if (checkInAt == null) {
      liveElapsedLabel.value = '00:00:00';
      return;
    }
    liveElapsedLabel.value = IsoDateRange.elapsedHms(checkInAt);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      liveElapsedLabel.value = IsoDateRange.elapsedHms(checkInAt);
    });
  }

  Future<void> clockIn() => _openClockSheet(isCheckIn: true);

  Future<void> clockOut() => _openClockSheet(isCheckIn: false);

  Future<void> _openClockSheet({required bool isCheckIn}) async {
    if (residenceOptions.isEmpty) await _loadResidences();
    final context = Get.context;
    if (context == null || !context.mounted) return;
    final current = overview;

    final saved = await StaffClockActionSheet.show(
      context,
      isCheckIn: isCheckIn,
      residences: residenceOptions.toList(),
      initialResidenceId: current?.residenceId,
      shiftId: current?.shiftId,
      showNotRosteredWarning:
          isCheckIn && !(current?.hasRosteredShiftNow ?? false),
    );
    if (saved == true) {
      Get.snackbar(
        'Attendance',
        isCheckIn ? 'Clocked in.' : 'Clocked out.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
      );
      await loadOverview();
    }
  }

  Future<void> toggleBreak() {
    final current = overview;
    if (current == null || !current.isOnShift) return Future.value();
    if (current.isOnBreak) {
      return _run(
        () => repository.endBreak(residenceId: current.residenceId),
        successMessage: 'Break ended.',
      );
    }
    return _run(
      () => repository.startBreak(residenceId: current.residenceId),
      successMessage: 'Break started.',
    );
  }

  Future<void> _run(
    Future<Result<void>> Function() action, {
    required String successMessage,
  }) async {
    setLoading(true);
    final result = await action();
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not update attendance',
      );
      return;
    }
    Get.snackbar(
      'Attendance',
      successMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
    await loadOverview();
  }

  /// History date filter (`null` = all dates).
  final Rxn<DateTime> historyDateFilter = Rxn<DateTime>();

  /// `all` or a residence id.
  final RxString historyResidenceFilter = 'all'.obs;

  /// `all` | `present` | `late` | `missed` | `pending_approval`.
  final RxString historyStatusFilter = 'all'.obs;

  List<StaffAttendanceHistoryItem> get filteredHistory {
    final items = overview?.history ?? const <StaffAttendanceHistoryItem>[];
    final date = historyDateFilter.value;
    final residence = historyResidenceFilter.value;
    final status = historyStatusFilter.value;
    return items.where((item) {
      if (date != null) {
        final at = item.occurredAt;
        if (at == null ||
            at.year != date.year ||
            at.month != date.month ||
            at.day != date.day) {
          return false;
        }
      }
      if (residence != 'all' && item.residenceId != residence) return false;
      if (status != 'all') {
        final s = item.status;
        if (status == 'present') {
          if (s != 'present' &&
              s != 'on_time' &&
              s != 'ontime' &&
              s != 'completed') {
            return false;
          }
        } else if (s != status) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void setHistoryDateFilter(DateTime? date) => historyDateFilter.value = date;

  void setHistoryResidenceFilter(String residenceId) =>
      historyResidenceFilter.value = residenceId;

  void setHistoryStatusFilter(String status) =>
      historyStatusFilter.value = status;

  Future<void> _loadResidences() async {
    final result = await repository.getResidences();
    result.when(
      success: (items) => residenceOptions.assignAll(items),
      failure: (_) {},
    );
  }

  Future<void> showManualEntryDialog() async {
    final saved = await Get.to<bool>(
      () => const StaffManualAttendanceEntryPage(),
    );
    if (saved == true) await loadOverview();
  }

  @override
  Future<void> refresh() async {
    await Future.wait([loadOverview(), _loadResidences()]);
  }
}
