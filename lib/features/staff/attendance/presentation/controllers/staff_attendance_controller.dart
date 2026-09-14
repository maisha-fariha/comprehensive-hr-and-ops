import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../domain/entities/staff_attendance_overview.dart';
import '../../domain/repositories/staff_attendance_repository.dart';

/// GetX controller for the "Attendance" screen.
class StaffAttendanceController extends BaseController<StaffAttendanceOverview> {
  final StaffAttendanceRepository repository;

  /// Live HH:MM:SS from [StaffAttendanceOverview.checkInAt].
  final RxString liveElapsedLabel = '00:00:00'.obs;

  Timer? _ticker;

  StaffAttendanceController({required this.repository});

  StaffAttendanceOverview? get overview => state.value.data;

  @override
  void onInit() {
    super.onInit();
    loadOverview();
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

  Future<void> clockIn() => _clock(isCheckIn: true);

  Future<void> clockOut() => _clock(isCheckIn: false);

  Future<void> _clock({required bool isCheckIn}) async {
    final current = overview;
    final selfieUrl = await _pickAndUploadSelfieOptional();

    setLoading(true);
    final result = isCheckIn
        ? await repository.checkIn(
            shiftId: current?.shiftId,
            residenceId: current?.residenceId,
            selfieUrl: selfieUrl,
          )
        : await repository.checkOut(
            shiftId: current?.shiftId,
            residenceId: current?.residenceId,
            selfieUrl: selfieUrl,
          );
    setLoading(false);

    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: isCheckIn ? 'Could not clock in' : 'Could not clock out',
      );
      return;
    }

    Get.snackbar(
      'Attendance',
      isCheckIn ? 'Clocked in.' : 'Clocked out.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
    await loadOverview();
  }

  /// Optional selfie → `POST /uploads?category=attendance`.
  /// Returns URL, or null if skipped / cancelled.
  Future<String?> _pickAndUploadSelfieOptional() async {
    final choice = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Selfie verification'),
        content: const Text(
          'Optionally attach a selfie for this clock action. '
          'It is uploaded to attendance before check-in/out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: 'skip'),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'pick'),
            child: const Text('Choose photo'),
          ),
        ],
      ),
    );
    if (choice != 'pick') return null;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final file = picked?.files.single;
    final path = file?.path;
    if (path == null || path.isEmpty) return null;

    setLoading(true);
    final upload = await repository.uploadAttendanceSelfie(
      localPath: path,
      fileName: file!.name,
    );
    setLoading(false);

    if (upload.isFailure) {
      AppErrorDialog.showResultError(
        upload.error,
        fallbackTitle: 'Could not upload selfie',
      );
      return null;
    }
    return upload.value;
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

  @override
  Future<void> refresh() => loadOverview();
}
