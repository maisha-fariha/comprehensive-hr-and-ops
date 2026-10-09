import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../data/mappers/attendance_mapper.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/manual_entry_options.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../attendance_formatters.dart';
import '../widgets/manual_entry/manual_entry_footer.dart';
import '../widgets/manual_entry/manual_entry_forms.dart';
import '../widgets/manual_entry/manual_entry_header.dart';
import '../../../../../core/media/app_file_picker.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

const manualEntryReasons = <(String, String)>[
  ('forgot_clock_in', 'Forgot clock-in'),
  ('forgot_clock_out', 'Forgot clock-out'),
  ('system_error', 'System error'),
  ('device_sync_issue', 'Device sync issue'),
  ('shift_swap', "Covered someone else's shift"),
  ('other', 'Other'),
];

const manualEntryStatuses = <(String, String)>[
  ('pending_approval', 'Pending approval'),
  ('present', 'Present'),
  ('late', 'Late'),
  ('missed', 'Missed — nobody worked it'),
];

const manualEntryBreaks = <(int, String)>[
  (0, 'None'),
  (15, '15 minutes'),
  (30, '30 minutes'),
  (45, '45 minutes'),
  (60, '60 minutes'),
];

/// Web "Manual Attendance Entry" (create) and "Edit Attendance Entry"
/// (the row's Correct action) four-step wizard.
class ManualAttendanceEntryPage extends StatefulWidget {
  /// The record being corrected; null creates a new manual entry.
  final AttendanceRecord? record;

  /// Pre-selected residence for a new entry (the list's residence filter).
  final String? defaultResidenceId;

  const ManualAttendanceEntryPage({
    super.key,
    this.record,
    this.defaultResidenceId,
  });

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

  int _breakMinutes = 0;
  String? _reasonCategory;
  String _status = 'pending_approval';

  bool _isLoadingResidences = false;
  bool _isLoadingStaff = false;
  bool _isLoadingShifts = false;
  bool _isSubmitting = false;

  Map<String, String> _errors = const {};
  String? _formError;
  String _initialSignature = '';

  static const _allowedEvidenceExtensions = {
    'pdf',
    'docx',
    'doc',
    'png',
    'jpg',
    'jpeg',
  };

  bool get _isEdit => widget.record != null;

  bool get _canDecide => _session.can('attendance:manage');

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<AttendanceRepository>();
    _session = Get.find<UserSession>();
    final record = widget.record;
    if (record != null) _prefill(record);
    _initialSignature = _signature();
    _bootstrap();
  }

  void _prefill(AttendanceRecord record) {
    _selectedResidence = ManualEntryResidenceOption(
      id: record.residenceId,
      name: record.residenceName,
    );
    _selectedStaff = ManualEntryStaffOption(
      id: record.staffId,
      name: record.staffName,
      detail: [
        if (record.staffRole != null) record.staffRole!,
        if (record.residenceName.isNotEmpty) record.residenceName,
      ].join(' · '),
      initials: record.staffInitials,
    );
    final shiftId = record.shiftId;
    if (shiftId != null) {
      final startsAt = record.shiftStartsAt;
      final endsAt = record.shiftEndsAt;
      _selectedShift = ManualEntryShiftOption(
        id: shiftId,
        label: startsAt != null && endsAt != null
            ? '${AttendanceMapper.formatDateTime(startsAt)} – '
                '${AttendanceMapper.formatDateTime(endsAt)}'
            : 'Rostered shift',
        startsAt: startsAt ?? DateTime.now(),
        endsAt: endsAt ?? DateTime.now(),
      );
    }
    _originalCheckInAt = record.originalCheckInAt ?? record.checkInAt;
    _originalCheckOutAt = record.originalCheckOutAt ?? record.checkOutAt;
    _correctedCheckInAt = record.checkInAt;
    _correctedCheckOutAt = record.checkOutAt;
    _breakMinutes = record.breakMinutes;
    _reasonCategory = record.reasonCategory;
    _status = record.status;
    _notesController.text = record.notes ?? '';
    _approvalNoteController.text = record.adminNote ?? '';
    for (final evidence in record.evidence) {
      final name = evidence.fileUrl.split('/').last;
      _evidenceFiles.add(
        ManualEntryEvidenceFile(
          localPath: evidence.fileUrl,
          fileName: name,
          mimeType: evidence.fileType,
          fileUrl: evidence.fileUrl,
        ),
      );
    }
  }

  Future<void> _bootstrap() async {
    await _loadResidences();
    final defaultId = widget.defaultResidenceId;
    if (_isEdit || defaultId == null || defaultId.isEmpty) return;
    final match = _residences.where((r) => r.id == defaultId);
    if (match.isNotEmpty && mounted) {
      setState(() => _selectedResidence = match.first);
      _initialSignature = _signature();
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

  String _signature() => [
        _selectedResidence?.id,
        _selectedStaff?.id,
        _selectedShift?.id,
        _originalCheckInAt,
        _originalCheckOutAt,
        _correctedCheckInAt,
        _correctedCheckOutAt,
        _breakMinutes,
        _reasonCategory,
        _status,
        _notesController.text.trim(),
        _approvalNoteController.text.trim(),
        _staffSearchController.text.trim(),
        _evidenceFiles.map((f) => f.localPath).join(','),
      ].join('|');

  bool get _hasUnsavedChanges => _signature() != _initialSignature;

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
    return showAppPopup<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AppSheetDialog(
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

  static String _labelOf<T>(List<(T, String)> options, T? value) {
    for (final option in options) {
      if (option.$1 == value) return option.$2;
    }
    return value?.toString() ?? '';
  }

  int? _minutesBetween(DateTime? from, DateTime? to) =>
      from == null || to == null ? null : to.difference(from).inMinutes;

  String? get _paySummaryText {
    final span = _minutesBetween(_correctedCheckInAt, _correctedCheckOutAt);
    if (span == null) return null;
    final worked = (span - _breakMinutes) < 0 ? 0 : span - _breakMinutes;
    return 'This entry works out at ${AttendanceFormat.span(worked)} — '
        '${AttendanceFormat.span(span)} less a $_breakMinutes-minute break.';
  }

  String? get _recordedSpan {
    final span = _minutesBetween(_originalCheckInAt, _originalCheckOutAt);
    return span == null ? null : AttendanceFormat.span(span);
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

  String _orDash(String value) => value.isEmpty ? '—' : value;

  /// Steps whose required fields are filled, as the web progress counts them.
  int get _completedSteps {
    var count = 0;
    if (_selectedStaff != null && _selectedResidence != null) count++;
    if (_correctedCheckInAt != null) count++;
    if (_reasonCategory != null) count++;
    if (_status.isNotEmpty) count++;
    return count;
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
        AppSnackbar.show('Could not load residences', error.message);
      },
    );
  }

  void _onStaffSearchChanged(String query) {
    _staffSearchDebounce?.cancel();
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
            ..addAll(items.take(8));
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
      _staffSearchController.clear();
      _staffResults.clear();
      _selectedShift = null;
      _shifts.clear();
      _errors = Map.of(_errors)..remove('staffId');
    });
    await _loadShifts();
  }

  void _changeStaff() {
    setState(() {
      _selectedStaff = null;
      _selectedShift = null;
      _shifts.clear();
    });
  }

  Future<void> _loadShifts() async {
    final staffId = _selectedStaff?.id;
    if (staffId == null) return;
    setState(() => _isLoadingShifts = true);
    final result = await _repository.getRosteredShifts(
      staffId: staffId,
      residenceId: _selectedResidence?.id,
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
      _selectedShift = null;
      _shifts.clear();
      _errors = Map.of(_errors)..remove('residenceId');
    });
    if (_selectedStaff != null) await _loadShifts();
  }

  Future<void> _pickShift() async {
    if (_shifts.isEmpty && !_isLoadingShifts) {
      await _loadShifts();
    }
    if (!mounted) return;
    if (_shifts.isEmpty) {
      AppSnackbar.show(
        'No shifts',
        'No rostered shifts found for this staff member.',
      );
      return;
    }
    final selected = await _showOptionSheet<ManualEntryShiftOption>(
      title: 'Select rostered shift',
      options: _shifts,
      labelOf: (item) => item.label,
    );
    if (selected == null) return;
    setState(() {
      _selectedShift = selected;
      _correctedCheckInAt = selected.startsAt;
      _correctedCheckOutAt = selected.endsAt;
    });
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
  }) {
    return showAppBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
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
          ),
        );
      },
    );
  }

  Future<void> _pickOption<T>({
    required String title,
    required List<(T, String)> options,
    required ValueChanged<T> onSelected,
  }) async {
    final selected = await _showOptionSheet<(T, String)>(
      title: title,
      options: options,
      labelOf: (item) => item.$2,
    );
    if (selected != null) onSelected(selected.$1);
  }

  Future<void> _pickDateTime({
    DateTime? initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final start = (initial ?? DateTime.now()).toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(start.year - 1),
      lastDate: DateTime(start.year + 1, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
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

  List<Map<String, dynamic>> get _evidencePayload => [
        for (final f in _evidenceFiles.where((f) => f.isReady))
          {'fileUrl': f.fileUrl, 'fileType': ?f.mimeType},
      ];

  Map<String, dynamic> _buildCreatePayload() {
    final notes = _notesController.text.trim();
    final evidence = _evidencePayload;
    return {
      'staffId': _selectedStaff!.id,
      'residenceId': _selectedResidence!.id,
      'checkInAt': _correctedCheckInAt!.toUtc().toIso8601String(),
      'breakMinutes': _breakMinutes,
      'status': _status,
      'reasonCategory': _reasonCategory,
      'shiftId': ?_selectedShift?.id,
      'checkOutAt': ?_correctedCheckOutAt?.toUtc().toIso8601String(),
      'originalCheckInAt': ?_originalCheckInAt?.toUtc().toIso8601String(),
      'originalCheckOutAt': ?_originalCheckOutAt?.toUtc().toIso8601String(),
      if (notes.isNotEmpty) 'notes': notes,
      if (evidence.isNotEmpty) 'evidence': evidence,
    };
  }

  Map<String, dynamic> _buildUpdatePayload() {
    final notes = _notesController.text.trim();
    final evidence = _evidencePayload;
    return {
      'checkInAt': _correctedCheckInAt!.toUtc().toIso8601String(),
      'checkOutAt': _correctedCheckOutAt?.toUtc().toIso8601String(),
      'breakMinutes': _breakMinutes,
      'status': _status,
      'reasonCategory': _reasonCategory,
      'notes': notes.isEmpty ? null : notes,
      if (evidence.isNotEmpty) 'evidence': evidence,
    };
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (_selectedStaff == null) errors['staffId'] = 'Select a staff member';
    if (_selectedResidence == null) errors['residenceId'] = 'Select a residence';
    final checkIn = _correctedCheckInAt;
    final checkOut = _correctedCheckOutAt;
    if (checkIn == null) {
      errors['checkInAt'] = 'A clock-in time is required';
    }
    if (checkOut != null && !checkOut.isAfter(checkIn ?? DateTime(0))) {
      errors['checkOutAt'] = 'Clock-out has to be after clock-in';
    }
    if (_reasonCategory == null) {
      errors['reasonCategory'] = 'Say why this entry was typed';
    }
    if (_reasonCategory == 'other' && _notesController.text.trim().isEmpty) {
      errors['notes'] =
          "Say what happened — 'Other' on its own tells an approver nothing";
    }
    return errors;
  }

  static ManualEntryTab _tabForField(String field) => switch (field) {
        'staffId' || 'residenceId' => ManualEntryTab.attendanceDetails,
        'checkInAt' || 'checkOutAt' => ManualEntryTab.timeCorrection,
        _ => ManualEntryTab.evidence,
      };

  Future<void> _onSave() async {
    if (_isSubmitting) return;

    final errors = _validate();
    if (errors.isNotEmpty) {
      final tab = ManualEntryTab.values.firstWhere(
        (t) => errors.keys.any((field) => _tabForField(field) == t),
      );
      setState(() {
        _errors = errors;
        _tab = tab;
        _formError = 'Fix the highlighted field on "${tab.label}" before saving.';
      });
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

    setState(() {
      _errors = const {};
      _formError = null;
      _isSubmitting = true;
    });
    try {
      final record = widget.record;
      final result = record != null
          ? await _repository.updateAttendance(record.id, _buildUpdatePayload())
          : await _repository.recordManualAttendance(_buildCreatePayload());
      if (!mounted) return;

      result.when(
        success: (_) {
          AppSnackbar.show(
            'Attendance',
            _isEdit ? 'Correction recorded' : 'Attendance recorded',
          );
          Navigator.of(context).pop(true);
        },
        failure: (error) => setState(() => _formError = error.message),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = ManualEntryTab.values.length;
    final completed = _completedSteps;

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
                        title: _isEdit
                            ? 'Edit Attendance Entry'
                            : 'Manual Attendance Entry',
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
                        currentStep: completed,
                        totalSteps: total,
                        percent: completed / total * 100,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (_formError != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                  child: Container(
                                    key: const ValueKey('manual-entry-error'),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.criticalBackgroundSoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _formError!,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.5,
                                        color: AppColors.criticalRed,
                                      ),
                                    ),
                                  ),
                                ),
                              _bodyForTab(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ManualEntryFooter(
                isSubmitting: _isSubmitting,
                saveLabel: _isEdit ? 'Save correction' : 'Save entry',
                saveButtonKey: const ValueKey('manual-entry-save'),
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
          onChangeStaff: _changeStaff,
          rosteredShiftValue: _selectedShift?.label,
          isLoadingShifts: _isLoadingShifts,
          canPickShift: _selectedStaff != null,
          pickedStaffShiftPlaceholder: 'No shift — a standalone entry',
          onRosteredShiftTap: _pickShift,
          residenceError: _errors['residenceId'],
          staffError: _errors['staffId'],
        );
      case ManualEntryTab.timeCorrection:
        return ManualEntryTimeCorrectionForm(
          originalReadOnly: _isEdit,
          recordedSpan: _recordedSpan,
          originalCheckInValue: _originalCheckInAt == null
              ? null
              : _isEdit
                  ? AttendanceFormat.wallClock(_originalCheckInAt)
                  : _formatDateTime(_originalCheckInAt!),
          onOriginalCheckInTap: () => _pickDateTime(
            initial: _originalCheckInAt,
            onSelected: (dt) => setState(() => _originalCheckInAt = dt),
          ),
          originalCheckOutValue: _originalCheckOutAt == null
              ? null
              : _isEdit
                  ? AttendanceFormat.wallClock(_originalCheckOutAt)
                  : _formatDateTime(_originalCheckOutAt!),
          onOriginalCheckOutTap: () => _pickDateTime(
            initial: _originalCheckOutAt,
            onSelected: (dt) => setState(() => _originalCheckOutAt = dt),
          ),
          correctedCheckInValue: _correctedCheckInAt == null
              ? null
              : _formatDateTime(_correctedCheckInAt!),
          correctedCheckInKey: const ValueKey('manual-entry-check-in'),
          onCorrectedCheckInTap: () => _pickDateTime(
            initial: _correctedCheckInAt,
            onSelected: (dt) => setState(() {
              _correctedCheckInAt = dt;
              _errors = Map.of(_errors)..remove('checkInAt');
            }),
          ),
          correctedCheckOutValue: _correctedCheckOutAt == null
              ? null
              : _formatDateTime(_correctedCheckOutAt!),
          onCorrectedCheckOutTap: () => _pickDateTime(
            initial: _correctedCheckOutAt ?? _correctedCheckInAt,
            onSelected: (dt) => setState(() {
              _correctedCheckOutAt = dt;
              _errors = Map.of(_errors)..remove('checkOutAt');
            }),
          ),
          unpaidBreakValue: _labelOf(manualEntryBreaks, _breakMinutes),
          onUnpaidBreakTap: () => _pickOption<int>(
            title: 'Unpaid break',
            options: manualEntryBreaks,
            onSelected: (v) => setState(() => _breakMinutes = v),
          ),
          paySummaryText: _paySummaryText,
          correctedCheckInError: _errors['checkInAt'],
          correctedCheckOutError: _errors['checkOutAt'],
        );
      case ManualEntryTab.evidence:
        return ManualEntryEvidenceForm(
          reasonValue: _reasonCategory == null
              ? null
              : _labelOf(manualEntryReasons, _reasonCategory),
          onReasonTap: () => _pickOption<String>(
            title: 'Select reason',
            options: manualEntryReasons,
            onSelected: (v) => setState(() {
              _reasonCategory = v;
              _errors = Map.of(_errors)..remove('reasonCategory');
            }),
          ),
          notesController: _notesController,
          evidenceFiles: List.unmodifiable(_evidenceFiles),
          onAddEvidenceTap: _pickEvidenceFiles,
          onRemoveEvidence: (file) => setState(() {
            _evidenceFiles.removeWhere((f) => f.localPath == file.localPath);
          }),
          reasonError: _errors['reasonCategory'],
          notesError: _errors['notes'],
        );
      case ManualEntryTab.approval:
        return ManualEntryApprovalForm(
          reasonLabel: _reasonCategory == null
              ? '—'
              : _labelOf(manualEntryReasons, _reasonCategory),
          evidenceLabel: '${_evidenceFiles.length} file(s)',
          correctedClockInLabel:
              _orDash(AttendanceFormat.wallClock(_correctedCheckInAt)),
          correctedClockOutLabel: _correctedCheckOutAt == null
              ? 'Still on shift'
              : AttendanceFormat.wallClock(_correctedCheckOutAt),
          wasRecordedAsLabel: _originalCheckInAt == null
              ? 'No clock record'
              : AttendanceFormat.wallClock(_originalCheckInAt),
          unpaidBreakLabel: '$_breakMinutes minutes',
          statusValue: _labelOf(manualEntryStatuses, _status),
          onStatusTap: () => _pickOption<String>(
            title: 'Select status',
            options: manualEntryStatuses,
            onSelected: (v) => setState(() => _status = v),
          ),
          noteController: _approvalNoteController,
          canDecide: _canDecide,
        );
    }
  }
}

/// Opens the wizard; [record] switches it to "Edit Attendance Entry".
Future<bool?> openManualAttendanceEntry({
  AttendanceRecord? record,
  String? defaultResidenceId,
}) {
  return Get.to<bool>(
        () => ManualAttendanceEntryPage(
          record: record,
          defaultResidenceId: defaultResidenceId,
        ),
      ) ??
      Future.value();
}
