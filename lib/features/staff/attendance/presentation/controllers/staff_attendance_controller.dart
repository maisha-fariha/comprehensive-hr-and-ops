import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_attendance_history_item.dart';
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

  /// BUG_Report006 — history date filter (`null` = all dates).
  final Rxn<DateTime> historyDateFilter = Rxn<DateTime>();

  /// BUG_Report006 — `all` | `completed` | `in_progress`.
  final RxString historyStatusFilter = 'all'.obs;

  List<StaffAttendanceHistoryItem> get filteredHistory {
    final items = overview?.history ?? const <StaffAttendanceHistoryItem>[];
    final date = historyDateFilter.value;
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
      if (status == 'completed' && item.isOpen) return false;
      if (status == 'in_progress' && !item.isOpen) return false;
      return true;
    }).toList();
  }

  void setHistoryDateFilter(DateTime? date) => historyDateFilter.value = date;

  void setHistoryStatusFilter(String status) =>
      historyStatusFilter.value = status;

  Future<void> showManualEntryDialog() async {
    final session = Get.find<UserSession>();
    var checkIn = DateTime.now().subtract(const Duration(hours: 8));
    var checkOut = DateTime.now();
    final notesController = TextEditingController();
    var includeCheckOut = true;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Manual Entry'),
        content: StatefulBuilder(
          builder: (context, setState) {
            String label(DateTime dt) =>
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            Future<void> pickIn() async {
              final date = await showDatePicker(
                context: context,
                initialDate: checkIn,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(checkIn),
              );
              if (time == null) return;
              setState(() {
                checkIn = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            Future<void> pickOut() async {
              final date = await showDatePicker(
                context: context,
                initialDate: checkOut,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(checkOut),
              );
              if (time == null) return;
              setState(() {
                checkOut = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  key: const Key('staff-manual-entry-check-in'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Check in'),
                  subtitle: Text(label(checkIn)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: pickIn,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include check out'),
                  value: includeCheckOut,
                  onChanged: (v) => setState(() => includeCheckOut = v),
                ),
                if (includeCheckOut)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Check out'),
                    subtitle: Text(label(checkOut)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: pickOut,
                  ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                if ((session.residenceId ?? '').isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Assign a residence before submitting.',
                      style: TextStyle(color: AppColors.criticalRed),
                    ),
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
            key: const Key('staff-manual-entry-submit'),
            onPressed: () => Get.back(result: true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    final notes = notesController.text.trim();
    notesController.dispose();
    if (confirmed != true) return;

    setLoading(true);
    final result = await repository.recordManualAttendance(
      checkInAtIso: checkIn.toUtc().toIso8601String(),
      checkOutAtIso:
          includeCheckOut ? checkOut.toUtc().toIso8601String() : null,
      notes: notes.isEmpty ? null : notes,
    );
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not save manual entry',
      );
      return;
    }
    Get.snackbar(
      'Manual entry saved',
      'Attendance record submitted for review.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
    await loadOverview();
  }

  @override
  Future<void> refresh() => loadOverview();
}
