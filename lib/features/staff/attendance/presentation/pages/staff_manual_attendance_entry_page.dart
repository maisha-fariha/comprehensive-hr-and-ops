import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../hr/attendance/domain/entities/manual_entry_options.dart';
import '../../../../hr/attendance/presentation/widgets/manual_entry/manual_entry_footer.dart';
import '../../../../hr/attendance/presentation/widgets/manual_entry/manual_entry_forms.dart';
import '../../../../hr/attendance/presentation/widgets/manual_entry/manual_entry_header.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../../../../../core/media/app_file_picker.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Staff self-service manual attendance wizard (BUG_Report005).
class StaffManualAttendanceEntryPage extends StatefulWidget {
  const StaffManualAttendanceEntryPage({super.key});

  @override
  State<StaffManualAttendanceEntryPage> createState() =>
      _StaffManualAttendanceEntryPageState();
}

class _StaffManualAttendanceEntryPageState
    extends State<StaffManualAttendanceEntryPage> {
  late final StaffAttendanceRepository _repository;
  late final UserSession _session;

  final _staffController = TextEditingController();
  final _notesController = TextEditingController();
  final _approvalNoteController = TextEditingController();

  final List<ManualEntryResidenceOption> _residences = [];
  final List<ManualEntryShiftOption> _shifts = [];
  final List<ManualEntryEvidenceFile> _evidenceFiles = [];

  ManualEntryResidenceOption? _selectedResidence;
  ManualEntryStaffOption? _selectedStaff;
  ManualEntryShiftOption? _selectedShift;
  ManualEntryTab _tab = ManualEntryTab.attendanceDetails;

  DateTime? _originalCheckInAt;
  DateTime? _originalCheckOutAt;
  DateTime? _correctedCheckInAt;
  DateTime? _correctedCheckOutAt;

  String _unpaidBreakLabel = 'None';
  String? _reasonCategoryLabel;
  String _approvalStatusLabel = 'Pending approval';
  bool _isLoadingResidences = false;
  bool _isLoadingShifts = false;
  bool _isSubmitting = false;

  static const _unpaidBreakOptions = [
    'None',
    '15 minutes',
    '30 minutes',
    '45 minutes',
    '60 minutes',
  ];

  static const _reasonOptions = [
    'Forgot clock-in',
    'Forgot clock-out',
    'System error',
    'Device sync issue',
    "Covered someone else's shift",
    'Other',
  ];

  static const _reasonCategoryCodes = {
    'Forgot clock-in': 'forgot_clock_in',
    'Forgot clock-out': 'forgot_clock_out',
    'System error': 'system_error',
    'Device sync issue': 'device_sync_issue',
    "Covered someone else's shift": 'covered_someone_elses_shift',
    'Other': 'other',
  };

  static const _approvalStatusOptions = [
    'Pending approval',
    'Present',
    'Late',
    'Missed',
  ];

  static const _approvalStatusCodes = {
    'Pending approval': 'pending_approval',
    'Present': 'present',
    'Late': 'late',
    'Missed': 'missed',
  };

  static const _allowedEvidenceExtensions = {
    'pdf',
    'docx',
    'doc',
    'png',
    'jpg',
    'jpeg',
  };

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffAttendanceRepository>();
    _session = Get.find<UserSession>();
    _bootstrapStaff();
    _loadResidences();
    _loadShifts();
  }

  void _bootstrapStaff() {
    final staffId = _session.staffId;
    final name = _session.displayName.trim().isEmpty
        ? 'Current staff member'
        : _session.displayName.trim();
    _staffController.text = name;
    _selectedStaff = ManualEntryStaffOption(
      id: staffId ?? '',
      name: name,
      detail: _session.residenceName ?? 'Signed-in staff',
      initials: IsoDateRange.initials(name),
    );
    final residenceId = _session.residenceId;
    final residenceName = _session.residenceName;
    if (residenceId != null && residenceId.isNotEmpty) {
      _selectedResidence = ManualEntryResidenceOption(
        id: residenceId,
        name: residenceName?.isNotEmpty == true ? residenceName! : 'Residence',
      );
    }
  }

  @override
  void dispose() {
    _staffController.dispose();
    _notesController.dispose();
    _approvalNoteController.dispose();
    super.dispose();
  }

  int get _unpaidBreakMinutes {
    final match = RegExp(r'(\d+)').firstMatch(_unpaidBreakLabel);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  String? get _reasonCategory {
    final label = _reasonCategoryLabel;
    if (label == null) return null;
    return _reasonCategoryCodes[label] ?? 'other';
  }

  String get _approvalStatus =>
      _approvalStatusCodes[_approvalStatusLabel] ?? 'pending_approval';

  String? get _paySummaryText {
    final start = _correctedCheckInAt;
    final end = _correctedCheckOutAt;
    if (start == null || end == null) return null;
    final minutes = (end.difference(start).inMinutes - _unpaidBreakMinutes)
        .clamp(0, 24 * 60);
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final worked = hours > 0
        ? (mins > 0 ? '${hours}h ${mins}m' : '${hours}h')
        : '${mins}m';
    return 'This entry covers $worked of worked time'
        '${_unpaidBreakMinutes > 0 ? ' after unpaid break.' : '.'}';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$mm/$dd/${local.year} $hour:$minute $period';
  }

  Future<void> _loadResidences() async {
    setState(() => _isLoadingResidences = true);
    final result = await _repository.getResidences();
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          _residences
            ..clear()
            ..addAll(items);
          final selected = _selectedResidence;
          if (selected != null &&
              !_residences.any((item) => item.id == selected.id)) {
            _residences.insert(0, selected);
          }
          if (_selectedResidence == null && _residences.length == 1) {
            _selectedResidence = _residences.single;
          }
          _isLoadingResidences = false;
        });
      },
      failure: (error) {
        setState(() => _isLoadingResidences = false);
        AppSnackbar.show('Could not load residences', error.message);
      },
    );
  }

  Future<void> _loadShifts() async {
    setState(() => _isLoadingShifts = true);
    final result = await _repository.getRosteredShifts(
      residenceId: _selectedResidence?.id,
      around: _correctedCheckInAt ?? DateTime.now(),
    );
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          _shifts
            ..clear()
            ..addAll(items);
          _isLoadingShifts = false;
        });
      },
      failure: (error) {
        setState(() => _isLoadingShifts = false);
        AppSnackbar.show('Could not load shifts', error.message);
      },
    );
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
  }) {
    return showAppBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(labelOf(option)),
                onTap: () => Navigator.of(context).pop(option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickResidence() async {
    if (_residences.isEmpty && !_isLoadingResidences) {
      await _loadResidences();
    }
    if (!mounted) return;
    if (_residences.isEmpty) {
      AppSnackbar.show('No residences', 'No residences are available.');
      return;
    }
    final selected = await _showOptionSheet<ManualEntryResidenceOption>(
      title: 'Select residence',
      options: _residences,
      labelOf: (item) => item.name,
    );
    if (selected == null) return;
    setState(() {
      _selectedResidence = selected;
      _selectedShift = null;
    });
    await _loadShifts();
  }

  Future<void> _pickShift() async {
    if (_shifts.isEmpty && !_isLoadingShifts) {
      await _loadShifts();
    }
    if (!mounted) return;
    if (_shifts.isEmpty) {
      AppSnackbar.show('No shifts', 'No rostered shifts found near this date.');
      return;
    }
    final selected = await _showOptionSheet<ManualEntryShiftOption>(
      title: 'Select rostered shift',
      options: _shifts,
      labelOf: (item) => item.label,
    );
    if (selected != null) setState(() => _selectedShift = selected);
  }

  Future<void> _pickStringOption({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await _showOptionSheet<String>(
      title: title,
      options: options,
      labelOf: (item) => item,
    );
    if (selected != null) onSelected(selected);
  }

  Future<void> _pickDateTime({
    required ValueChanged<DateTime> onSelected,
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final initial = initialDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    onSelected(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  String _mimeForName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _pickEvidenceFiles() async {
    try {
      final result = await AppFilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _allowedEvidenceExtensions.toList(),
      );
      if (result == null || !mounted) return;

      for (final file in result.files) {
        final path = file.path;
        if (path == null || path.isEmpty) continue;
        final ext = (file.extension ?? file.name.split('.').last).toLowerCase();
        if (!_allowedEvidenceExtensions.contains(ext)) {
          AppSnackbar.show(
            'Unsupported file',
            '${file.name} is not supported.',
          );
          continue;
        }
        final pending = ManualEntryEvidenceFile(
          localPath: path,
          fileName: file.name,
          mimeType: _mimeForName(file.name),
          isUploading: true,
        );
        setState(() => _evidenceFiles.add(pending));
        await _uploadEvidenceAt(_evidenceFiles.length - 1);
      }
    } catch (error) {
      AppSnackbar.show('Could not pick files', error.toString());
    }
  }

  Future<void> _uploadEvidenceAt(int index) async {
    if (index < 0 || index >= _evidenceFiles.length) return;
    final current = _evidenceFiles[index];
    final result = await _repository.uploadEvidenceFile(current);
    if (!mounted) return;
    result.when(
      success: (uploaded) => setState(() => _evidenceFiles[index] = uploaded),
      failure: (error) {
        setState(() {
          _evidenceFiles[index] = current.copyWith(
            isUploading: false,
            uploadError: error.message,
          );
        });
      },
    );
  }

  Future<void> _onSave() async {
    if (_isSubmitting) return;
    final staffId = _session.staffId;
    if (staffId == null || staffId.isEmpty || _selectedResidence == null) {
      AppSnackbar.show(
        'Missing required fields',
        'Staff profile and residence are required.',
      );
      setState(() => _tab = ManualEntryTab.attendanceDetails);
      return;
    }
    if (_correctedCheckInAt == null) {
      AppSnackbar.show(
        'Missing required fields',
        'Corrected clock-in is required.',
      );
      setState(() => _tab = ManualEntryTab.timeCorrection);
      return;
    }
    final reasonCategory = _reasonCategory;
    if (reasonCategory == null) {
      AppSnackbar.show('Missing required fields', 'Reason is required.');
      setState(() => _tab = ManualEntryTab.evidence);
      return;
    }
    if (_evidenceFiles.any((file) => file.isUploading)) {
      AppSnackbar.show(
        'Uploads in progress',
        'Wait for evidence uploads to finish.',
      );
      setState(() => _tab = ManualEntryTab.evidence);
      return;
    }

    final evidence = _evidenceFiles
        .where((file) => file.isReady)
        .map((file) => {'fileUrl': file.fileUrl, 'fileType': file.fileType})
        .toList();
    final note = _approvalNoteController.text.trim().isNotEmpty
        ? _approvalNoteController.text.trim()
        : _notesController.text.trim();

    setState(() => _isSubmitting = true);
    final result = await _repository.recordManualAttendance(
      staffId: staffId,
      residenceId: _selectedResidence!.id,
      shiftId: _selectedShift?.id,
      checkInAtIso: _correctedCheckInAt!.toUtc().toIso8601String(),
      checkOutAtIso: _correctedCheckOutAt?.toUtc().toIso8601String(),
      breakMinutes: _unpaidBreakMinutes,
      reasonCategory: reasonCategory,
      status: _approvalStatus,
      notes: note.isEmpty ? null : note,
      evidence: evidence,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        AppSnackbar.show(
          'Manual entry saved',
          'Attendance record submitted for review.',
        );
        Get.back(result: true);
      },
      failure: (error) =>
          AppSnackbar.show('Could not save entry', error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _tab.index + 1;
    final total = ManualEntryTab.values.length;
    final percent = (step / total) * 100;

    return Scaffold(
      key: const Key('staff-manual-entry-page'),
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    ManualEntryHeader(
                      onClose: _isSubmitting
                          ? null
                          : () => Get.back(result: false),
                    ),
                    const ManualEntryWarningBanner(),
                    ManualEntryStepTabs(
                      selected: _tab,
                      onSelected: _isSubmitting
                          ? null
                          : (tab) => setState(() => _tab = tab),
                    ),
                    ManualEntryCompletionBar(
                      currentStep: step,
                      totalSteps: total,
                      percent: percent,
                    ),
                    Expanded(
                      child: SingleChildScrollView(child: _bodyForTab()),
                    ),
                  ],
                ),
              ),
            ),
            ManualEntryFooter(
              saveButtonKey: const Key('staff-manual-entry-submit'),
              isSubmitting: _isSubmitting,
              onCancel: _isSubmitting ? null : () => Get.back(result: false),
              onSave: _isSubmitting ? null : _onSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyForTab() {
    switch (_tab) {
      case ManualEntryTab.attendanceDetails:
        return KeyedSubtree(
          key: const Key('staff-manual-entry-step-attendance-details'),
          child: ManualEntryDetailsForm(
            residenceValue: _selectedResidence?.name,
            isLoadingResidences: _isLoadingResidences,
            onResidenceTap: _pickResidence,
            staffSearchController: _staffController,
            onStaffSearchChanged: (_) {},
            selectedStaff: _selectedStaff,
            rosteredShiftValue: _selectedShift?.label,
            isLoadingShifts: _isLoadingShifts,
            canPickShift: !_isLoadingShifts,
            onRosteredShiftTap: _pickShift,
          ),
        );
      case ManualEntryTab.timeCorrection:
        return KeyedSubtree(
          key: const Key('staff-manual-entry-step-time-correction'),
          child: ManualEntryTimeCorrectionForm(
            originalCheckInValue: _originalCheckInAt == null
                ? null
                : _formatDateTime(_originalCheckInAt!),
            onOriginalCheckInTap: () => _pickDateTime(
              initialDate: _originalCheckInAt,
              onSelected: (dt) => setState(() => _originalCheckInAt = dt),
            ),
            originalCheckOutValue: _originalCheckOutAt == null
                ? null
                : _formatDateTime(_originalCheckOutAt!),
            onOriginalCheckOutTap: () => _pickDateTime(
              initialDate: _originalCheckOutAt,
              onSelected: (dt) => setState(() => _originalCheckOutAt = dt),
            ),
            correctedCheckInKey: const Key('staff-manual-entry-check-in'),
            correctedCheckInValue: _correctedCheckInAt == null
                ? null
                : _formatDateTime(_correctedCheckInAt!),
            onCorrectedCheckInTap: () => _pickDateTime(
              initialDate: _correctedCheckInAt,
              onSelected: (dt) async {
                setState(() => _correctedCheckInAt = dt);
                await _loadShifts();
              },
            ),
            correctedCheckOutValue: _correctedCheckOutAt == null
                ? null
                : _formatDateTime(_correctedCheckOutAt!),
            onCorrectedCheckOutTap: () => _pickDateTime(
              initialDate: _correctedCheckOutAt,
              onSelected: (dt) => setState(() => _correctedCheckOutAt = dt),
            ),
            unpaidBreakValue: _unpaidBreakLabel,
            onUnpaidBreakTap: () => _pickStringOption(
              title: 'Unpaid break',
              options: _unpaidBreakOptions,
              onSelected: (value) => setState(() => _unpaidBreakLabel = value),
            ),
            paySummaryText: _paySummaryText,
          ),
        );
      case ManualEntryTab.evidence:
        return KeyedSubtree(
          key: const Key('staff-manual-entry-step-evidence'),
          child: ManualEntryEvidenceForm(
            reasonValue: _reasonCategoryLabel,
            onReasonTap: () => _pickStringOption(
              title: 'Select reason',
              options: _reasonOptions,
              onSelected: (value) =>
                  setState(() => _reasonCategoryLabel = value),
            ),
            notesController: _notesController,
            evidenceFiles: List.unmodifiable(_evidenceFiles),
            onAddEvidenceTap: _pickEvidenceFiles,
            onRemoveEvidence: (file) => setState(() {
              _evidenceFiles.removeWhere((f) => f.localPath == file.localPath);
            }),
          ),
        );
      case ManualEntryTab.approval:
        return KeyedSubtree(
          key: const Key('staff-manual-entry-step-approval'),
          child: ManualEntryApprovalForm(
            reasonLabel: _reasonCategoryLabel ?? '-',
            evidenceLabel:
                '${_evidenceFiles.where((f) => f.isReady).length} file(s)',
            correctedClockInLabel: _correctedCheckInAt == null
                ? '-'
                : _formatDateTime(_correctedCheckInAt!),
            correctedClockOutLabel: _correctedCheckOutAt == null
                ? 'Still on shift'
                : _formatDateTime(_correctedCheckOutAt!),
            wasRecordedAsLabel:
                _originalCheckInAt == null && _originalCheckOutAt == null
                ? 'No clock record'
                : [
                    if (_originalCheckInAt != null)
                      _formatDateTime(_originalCheckInAt!),
                    if (_originalCheckOutAt != null)
                      _formatDateTime(_originalCheckOutAt!),
                  ].join(' -> '),
            unpaidBreakLabel: _unpaidBreakLabel == 'None'
                ? '0 minutes'
                : _unpaidBreakLabel,
            statusValue: _approvalStatusLabel,
            onStatusTap: () => _pickStringOption(
              title: 'Select status',
              options: _approvalStatusOptions,
              onSelected: (value) =>
                  setState(() => _approvalStatusLabel = value),
            ),
            noteController: _approvalNoteController,
          ),
        );
    }
  }
}
