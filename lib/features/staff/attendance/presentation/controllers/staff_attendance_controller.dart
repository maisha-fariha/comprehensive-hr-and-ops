import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../domain/entities/staff_attendance_overview.dart';
import '../../domain/repositories/staff_attendance_repository.dart';

/// GetX controller for the "Attendance" screen.
class StaffAttendanceController extends BaseController<StaffAttendanceOverview> {
  final StaffAttendanceRepository repository;

  StaffAttendanceController({required this.repository}) {
    loadOverview();
  }

  StaffAttendanceOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> clockIn() => _run(
        () => repository.checkIn(
          shiftId: overview?.shiftId,
          residenceId: overview?.residenceId,
        ),
        successMessage: 'Clocked in.',
      );

  Future<void> clockOut() => _run(
        () => repository.checkOut(
          shiftId: overview?.shiftId,
          residenceId: overview?.residenceId,
        ),
        successMessage: 'Clocked out.',
      );

  Future<void> toggleBreak() {
    final current = overview;
    if (current == null) return Future.value();
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

  @override
  Future<void> refresh() => loadOverview();
}
