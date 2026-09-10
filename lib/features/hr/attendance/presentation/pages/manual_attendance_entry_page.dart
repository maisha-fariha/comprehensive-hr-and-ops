import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/manual_entry_options.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../widgets/manual_entry/manual_entry_footer.dart';
import '../widgets/manual_entry/manual_entry_forms.dart';
import '../widgets/manual_entry/manual_entry_header.dart';

/// Multi-step Manual Attendance Entry screen matching the HR design reference.
class ManualAttendanceEntryPage extends StatefulWidget {
  const ManualAttendanceEntryPage({super.key});

  @override
  State<ManualAttendanceEntryPage> createState() =>
      _ManualAttendanceEntryPageState();
}

class _ManualAttendanceEntryPageState extends State<ManualAttendanceEntryPage> {
  late final AttendanceRepository _repository;
  late final UserSession _session;

  ManualEntryTab _tab = ManualEntryTab.attendanceDetails;

  final _staffSearchController = TextEditingController();
  final _notesController = TextEditingController();
  final _approvalNoteController = TextEditingController();
  Timer? _staffSearchDebounce;

  final List<ManualEntryResidenceOption> _residences = [];
  final List<ManualEntryStaffOption> _staffResults = [];
  final List<ManualEntryShiftOption> _shifts = [];
  final List<ManualEntryEvidenceFile> _evidenceFiles = [];

  ManualEntryResidenceOption? _selectedResidence;
  ManualEntryStaffOption? _selectedStaff;
  ManualEntryShiftOption? _selectedShift;

  DateTime? _originalCheckInAt;
  DateTime? _originalCheckOutAt;
  DateTime? _correctedCheckInAt;
  DateTime? _correctedCheckOutAt;

  String _unpaidBreakLabel = 'None';
  String? _reasonCategoryLabel;
  String _approvalStatusLabel = 'Pending approval';

  bool _isLoadingResidences = false;
  bool _isLoadingStaff = false;
  bool _isLoadingShifts = false;
  bool _isSubmitting = false;

  /// Residence auto-filled from session; changing away from this counts as an edit.
  String? _bootstrappedResidenceId;

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

  static const _approvalStatusOptions = [
    'Pending approval',
    'Present',
    'Late',
    'Missed — nobody worked it',
  ];

  static const _allowedEvidenceExtensions = {
    'pdf',
    'docx',
    'doc',
    'png',
    'jpg',
    'jpeg',
  };

  static const _reasonCategoryCodes = {
    'Forgot clock-in': 'forgot_clock_in',
    'Forgot clock-out': 'forgot_clock_out',
    'System error': 'system_error',
    'Device sync issue': 'device_sync_issue',
    "Covered someone else's shift": 'covered_someone_elses_shift',
    'Other': 'other',
  };

  static const _approvalStatusCodes = {
    'Pending approval': 'pending_approval',
    'Present': 'present',
    'Late': 'late',
    'Missed — nobody worked it': 'missed',
  };

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<AttendanceRepository>();
    _session = Get.find<UserSession>();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadResidences();
    final sessionResidenceId = _session.residenceId;
    if (sessionResidenceId != null && sessionResidenceId.isNotEmpty) {
      final match = _residences.where((r) => r.id == sessionResidenceId);
      if (match.isNotEmpty) {
        setState(() {
          _selectedResidence = match.first;
          _bootstrappedResidenceId = match.first.id;
        });
      } else if (_session.residenceName != null &&
          _session.residenceName!.isNotEmpty) {
        setState(() {
          _selectedResidence = ManualEntryResidenceOption(
            id: sessionResidenceId,
            name: _session.residenceName!,
          );
          _bootstrappedResidenceId = sessionResidenceId;
        });
      }
    }
  }

  @override
  void dispose() {
    _staffSearchDebounce?.cancel();
    _staffSearchController.dispose();
    _notesController.dispose();
    _approvalNoteController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (_selectedStaff != null) return true;
    if (_selectedShift != null) return true;
    if (_originalCheckInAt != null ||
        _originalCheckOutAt != null ||
        _correctedCheckInAt != null ||
        _correctedCheckOutAt != null) {
      return true;
    }
    if (_unpaidBreakLabel != 'None') return true;
    if (_reasonCategoryLabel != null) return true;
    if (_approvalStatusLabel != 'Pending approval') return true;
    if (_notesController.text.trim().isNotEmpty) return true;
    if (_approvalNoteController.text.trim().isNotEmpty) return true;
    if (_evidenceFiles.isNotEmpty) return true;
    if (_staffSearchController.text.trim().isNotEmpty) return true;
    if (_selectedResidence != null &&
        _selectedResidence!.id != _bootstrappedResidenceId) {
      return true;
    }
    return false;
  }

  Future<void> _close() async {
    if (_isSubmitting) return;
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await _showDiscardDialog();
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Discard changes?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textHeading,
            ),
          ),
          content: const Text(
            'You have unsaved changes. If you leave now, your edits will be lost.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Keep editing',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Discard',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  color: AppColors.criticalRed,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int get _unpaidBreakMinutes {
    final match = RegExp(r'(\d+)').firstMatch(_unpaidBreakLabel);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  String? get _paySummaryText {
    final start = _correctedCheckInAt;
    final end = _correctedCheckOutAt;
    if (start == null || end == null) return null;
    var minutes = end.difference(start).inMinutes - _unpaidBreakMinutes;
    if (minutes < 0) minutes = 0;
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

  String get _approvalReasonSummary => _reasonCategoryLabel ?? '—';

  String get _approvalEvidenceSummary =>
      '${_evidenceFiles.length} file(s)';

  String get _approvalClockInSummary =>
      _correctedCheckInAt == null ? '—' : _formatDateTime(_correctedCheckInAt!);

  String get _approvalClockOutSummary => _correctedCheckOutAt == null
      ? 'Still on shift'
      : _formatDateTime(_correctedCheckOutAt!);

  String get _approvalWasRecordedAsSummary {
    final inn = _originalCheckInAt;
    final out = _originalCheckOutAt;
    if (inn == null && out == null) return 'No clock record';
    if (inn != null && out != null) {
      return '${_formatDateTime(inn)} → ${_formatDateTime(out)}';
    }
    return _formatDateTime(inn ?? out!);
  }

  String get _approvalUnpaidBreakSummary {
    if (_unpaidBreakLabel == 'None') return '0 minutes';
    return _unpaidBreakLabel;
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
          _isLoadingResidences = false;
        });
      },
      failure: (error) {
        setState(() => _isLoadingResidences = false);
        AppSnackbar.show(
          'Could not load residences',
          error.message,
        );
      },
    );
  }

  void _onStaffSearchChanged(String query) {
    _staffSearchDebounce?.cancel();
    if (_selectedStaff != null && query.trim() != _selectedStaff!.name) {
      setState(() {
        _selectedStaff = null;
        _selectedShift = null;
        _shifts.clear();
      });
    }
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _staffResults.clear();
        _isLoadingStaff = false;
      });
      return;
    }
    _staffSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchStaff(trimmed);
    });
  }

  Future<void> _searchStaff(String query) async {
    setState(() => _isLoadingStaff = true);
    final result = await _repository.searchStaff(
      search: query,
      residenceId: _selectedResidence?.id,
    );
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          _staffResults
            ..clear()
            ..addAll(items);
          _isLoadingStaff = false;
        });
      },
      failure: (error) {
        setState(() => _isLoadingStaff = false);
        AppSnackbar.show('Could not search staff', error.message);
      },
    );
  }

  Future<void> _selectStaff(ManualEntryStaffOption staff) async {
    setState(() {
      _selectedStaff = staff;
      _staffSearchController.text = staff.name;
      _staffResults.clear();
      _selectedShift = null;
      _shifts.clear();
    });
    await _loadShifts();
  }

  Future<void> _loadShifts() async {
    final staffId = _selectedStaff?.id;
    if (staffId == null) return;
    setState(() => _isLoadingShifts = true);
    final result = await _repository.getRosteredShifts(
      staffId: staffId,
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
      _selectedStaff = null;
      _selectedShift = null;
      _staffResults.clear();
      _shifts.clear();
      _staffSearchController.clear();
    });
  }

  Future<void> _pickShift() async {
    if (_shifts.isEmpty && !_isLoadingShifts) {
      await _loadShifts();
    }
    if (!mounted) return;
    if (_shifts.isEmpty) {
      AppSnackbar.show(
        'No shifts',
        'No rostered shifts found for this staff member in the selected range.',
      );
      return;
    }
    final selected = await _showOptionSheet<ManualEntryShiftOption>(
      title: 'Select rostered shift',
      options: _shifts,
      labelOf: (item) => item.label,
    );
    if (selected == null) return;
    setState(() => _selectedShift = selected);
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
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
                  title: Text(
                    labelOf(option),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(option),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
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
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _allowedEvidenceExtensions.toList(),
      );
      if (result == null || !mounted) return;

      for (final file in result.files) {
        final path = file.path;
        if (path == null || path.isEmpty) continue;
        final name = file.name;
        final ext = (file.extension ?? name.split('.').last).toLowerCase();
        if (!_allowedEvidenceExtensions.contains(ext)) {
          AppSnackbar.show(
            'Unsupported file',
            '$name must be PDF, DOCX, or PNG.',
          );
          continue;
        }
        const maxBytes = 15 * 1024 * 1024;
        if (file.size > maxBytes) {
          AppSnackbar.show('File too large', '$name exceeds the 15MB limit.');
          continue;
        }
        if (_evidenceFiles.any((f) => f.localPath == path)) continue;

        final pending = ManualEntryEvidenceFile(
          localPath: path,
          fileName: name,
          mimeType: _mimeForName(name),
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
      success: (uploaded) {
        setState(() => _evidenceFiles[index] = uploaded);
      },
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

  Map<String, dynamic> _buildPayload() {
    final evidenceNotes = _notesController.text.trim();
    final approvalNote = _approvalNoteController.text.trim();
    final notes = approvalNote.isNotEmpty ? approvalNote : evidenceNotes;
    final reasonLabel = _reasonCategoryLabel;
    final reasonCategory = reasonLabel == null
        ? null
        : _reasonCategoryCodes[reasonLabel] ?? 'other';

    final payload = <String, dynamic>{
      'staffId': _selectedStaff!.id,
      'residenceId': _selectedResidence!.id,
      'checkInAt': _correctedCheckInAt!.toUtc().toIso8601String(),
      'status':
          _approvalStatusCodes[_approvalStatusLabel] ?? 'pending_approval',
      'breakMinutes': _unpaidBreakMinutes,
      'shiftId': ?_selectedShift?.id,
      'checkOutAt': ?_correctedCheckOutAt?.toUtc().toIso8601String(),
      'originalCheckInAt': ?_originalCheckInAt?.toUtc().toIso8601String(),
      'originalCheckOutAt': ?_originalCheckOutAt?.toUtc().toIso8601String(),
      'reasonCategory': ?reasonCategory,
      'reason': ?reasonLabel,
      if (notes.isNotEmpty) 'notes': notes,
    };

    final evidence = _evidenceFiles
        .where((f) => f.isReady)
        .map(
          (f) => {
            'fileUrl': f.fileUrl,
            'fileType': f.fileType,
          },
        )
        .toList();
    if (evidence.isNotEmpty) {
      payload['evidence'] = evidence;
    }
    return payload;
  }

  Future<void> _onSave() async {
    if (_isSubmitting) return;

    if (_selectedResidence == null || _selectedStaff == null) {
      AppSnackbar.show(
        'Missing required fields',
        'Residence and staff member are required.',
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
    if (_reasonCategoryLabel == null) {
      AppSnackbar.show('Missing required fields', 'Reason is required.');
      setState(() => _tab = ManualEntryTab.evidence);
      return;
    }
    if (_evidenceFiles.any((f) => f.isUploading)) {
      AppSnackbar.show(
        'Uploads in progress',
        'Wait for evidence uploads to finish before saving.',
      );
      setState(() => _tab = ManualEntryTab.evidence);
      return;
    }
    if (_evidenceFiles.any((f) => f.uploadError != null)) {
      AppSnackbar.show(
        'Upload failed',
        'Remove or re-upload failed evidence files before saving.',
      );
      setState(() => _tab = ManualEntryTab.evidence);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _repository.recordManualAttendance(_buildPayload());
      if (!mounted) return;

      await result.when(
        success: (_) async {
          if (!mounted) return;
          AppSnackbar.show(
            'Manual entry saved',
            'Attendance record created successfully.',
          );
          Navigator.of(context).pop(true);
        },
        failure: (error) async {
          AppSnackbar.show('Could not save entry', error.message);
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _tab.index + 1;
    final total = ManualEntryTab.values.length;
    final percent = (step / total) * 100;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isSubmitting) return;
        await _close();
      },
      child: Scaffold(
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
                        onClose: _isSubmitting ? null : () => _close(),
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
                        child: SingleChildScrollView(
                          child: _bodyForTab(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ManualEntryFooter(
                isSubmitting: _isSubmitting,
                onCancel: _isSubmitting ? null : () => _close(),
                onSave: _isSubmitting ? null : _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bodyForTab() {
    switch (_tab) {
      case ManualEntryTab.attendanceDetails:
        return ManualEntryDetailsForm(
          residenceValue: _selectedResidence?.name,
          isLoadingResidences: _isLoadingResidences,
          onResidenceTap: _pickResidence,
          staffSearchController: _staffSearchController,
          onStaffSearchChanged: _onStaffSearchChanged,
          staffResults: List.unmodifiable(_staffResults),
          isLoadingStaff: _isLoadingStaff,
          selectedStaff: _selectedStaff,
          onStaffSelected: _selectStaff,
          rosteredShiftValue: _selectedShift?.label,
          isLoadingShifts: _isLoadingShifts,
          canPickShift: _selectedStaff != null,
          onRosteredShiftTap: _pickShift,
        );
      case ManualEntryTab.timeCorrection:
        return ManualEntryTimeCorrectionForm(
          originalCheckInValue: _originalCheckInAt == null
              ? null
              : _formatDateTime(_originalCheckInAt!),
          onOriginalCheckInTap: () => _pickDateTime(
            onSelected: (dt) => setState(() => _originalCheckInAt = dt),
          ),
          originalCheckOutValue: _originalCheckOutAt == null
              ? null
              : _formatDateTime(_originalCheckOutAt!),
          onOriginalCheckOutTap: () => _pickDateTime(
            onSelected: (dt) => setState(() => _originalCheckOutAt = dt),
          ),
          correctedCheckInValue: _correctedCheckInAt == null
              ? null
              : _formatDateTime(_correctedCheckInAt!),
          onCorrectedCheckInTap: () => _pickDateTime(
            onSelected: (dt) async {
              setState(() => _correctedCheckInAt = dt);
              if (_selectedStaff != null) await _loadShifts();
            },
          ),
          correctedCheckOutValue: _correctedCheckOutAt == null
              ? null
              : _formatDateTime(_correctedCheckOutAt!),
          onCorrectedCheckOutTap: () => _pickDateTime(
            onSelected: (dt) => setState(() => _correctedCheckOutAt = dt),
          ),
          unpaidBreakValue: _unpaidBreakLabel,
          onUnpaidBreakTap: () => _pickStringOption(
            title: 'Unpaid break',
            options: _unpaidBreakOptions,
            onSelected: (v) => setState(() => _unpaidBreakLabel = v),
          ),
          paySummaryText: _paySummaryText,
        );
      case ManualEntryTab.evidence:
        return ManualEntryEvidenceForm(
          reasonValue: _reasonCategoryLabel,
          onReasonTap: () => _pickStringOption(
            title: 'Select reason',
            options: _reasonOptions,
            onSelected: (v) => setState(() => _reasonCategoryLabel = v),
          ),
          notesController: _notesController,
          evidenceFiles: List.unmodifiable(_evidenceFiles),
          onAddEvidenceTap: _pickEvidenceFiles,
          onRemoveEvidence: (file) => setState(() {
            _evidenceFiles.removeWhere((f) => f.localPath == file.localPath);
          }),
        );
      case ManualEntryTab.approval:
        return ManualEntryApprovalForm(
          reasonLabel: _approvalReasonSummary,
          evidenceLabel: _approvalEvidenceSummary,
          correctedClockInLabel: _approvalClockInSummary,
          correctedClockOutLabel: _approvalClockOutSummary,
          wasRecordedAsLabel: _approvalWasRecordedAsSummary,
          unpaidBreakLabel: _approvalUnpaidBreakSummary,
          statusValue: _approvalStatusLabel,
          onStatusTap: () => _pickStringOption(
            title: 'Select status',
            options: _approvalStatusOptions,
            onSelected: (v) => setState(() => _approvalStatusLabel = v),
          ),
          noteController: _approvalNoteController,
        );
    }
  }
}

/// Opens [ManualAttendanceEntryPage] from Attendance.
Future<bool?> openManualAttendanceEntry() {
  return Get.to<bool>(() => const ManualAttendanceEntryPage()) ??
      Future.value();
}
