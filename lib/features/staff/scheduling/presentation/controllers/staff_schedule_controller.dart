import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../domain/entities/staff_schedule_overview.dart';
import '../../domain/repositories/staff_schedule_repository.dart';

/// GetX controller for the "My Schedule" screen.
class StaffScheduleController extends BaseController<StaffScheduleOverview> {
  final StaffScheduleRepository repository;

  StaffScheduleController({required this.repository}) {
    loadOverview();
  }

  StaffScheduleOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> requestOpenShift(String shiftId) async {
    setLoading(true);
    final result = await repository.bidOnShift(shiftId);
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not request shift',
      );
      return;
    }
    Get.snackbar(
      'Shift request sent',
      'Your bid was submitted.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
    await loadOverview();
  }

  @override
  Future<void> refresh() => loadOverview();
}
