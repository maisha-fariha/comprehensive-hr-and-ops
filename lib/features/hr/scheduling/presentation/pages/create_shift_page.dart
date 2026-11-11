import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/app_permissions.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../domain/entities/create_shift_draft.dart';
import '../../domain/entities/shift_break_duration_option.dart';
import '../../domain/entities/shift_residence_option.dart';
import '../../domain/entities/shift_staff_conflict.dart';
import '../../domain/entities/shift_staff_option.dart';
import '../../domain/entities/shift_type_option.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../widgets/create_shift/create_shift_footer.dart';
import '../widgets/create_shift/create_shift_header.dart';
import '../widgets/create_shift/create_shift_info_form.dart';
import '../widgets/create_shift/create_shift_notifications_form.dart';
import '../widgets/create_shift/create_shift_open_shift_form.dart';
import '../widgets/create_shift/create_shift_recurring_form.dart';
import '../widgets/create_shift/create_shift_staff_assignment_form.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// "Add New Shift" wizard — same steps, fields, validation and
/// `POST /shifts` body as the web scheduling dialog.
class CreateShiftPage extends StatefulWidget {
  /// Pre-selected residence (the scheduling page's residence filter).
  final String? initialResidenceId;

  /// Pre-filled shift date (the scheduling page's selected day).
  final DateTime? initialShiftDate;

  /// Opens the wizard as the web "Edit Shift" dialog for this shift.
  final String? editShiftId;

  const CreateShiftPage({
    super.key,
    this.initialResidenceId,
    this.initialShiftDate,
    this.editShiftId,
  });

  @override
  State<CreateShiftPage> createState() => _CreateShiftPageState();
}

class _CreateShiftPageState extends State<CreateShiftPage> {
  late final SchedulingRepository _repository;
  late CreateShiftDraft _draft;
  late String _initialSnapshot;
  bool _isLoadingShift = false;
  String? _shiftError;

  bool get _isEdit => widget.editShiftId != null;

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _requiredStaffCountController;
  late final TextEditingController _maxBidsController;
  late final TextEditingController _noteToBiddersController;
  late final TextEditingController _occurrenceController;
  late final TextEditingController _messageController;
  late final TextEditingController _restOverrideReasonController;
  final ScrollController _scrollController = ScrollController();

  CreateShiftStep _step = CreateShiftStep.shiftInformation;
  Map<String, String> _errors = const {};
  String? _submitError;
  /// Which footer action is in flight (Bug Report 002 — only that button spins).
  String? _busyAction;
  Future<void>? _clockReady;

  final List<ShiftResidenceOption> _residences = [];
  bool _isLoadingResidences = false;
  List<ShiftClientOption> _clients = [];

  final List<ShiftStaffOption> _staffOptions = [];
  bool _isLoadingStaff = false;
  String? _staffError;

  ShiftConflictsResult _conflicts = const ShiftConflictsResult();
  Set<String> _staffWithOverlappingShifts = {};
  int _conflictSerial = 0;

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<SchedulingRepository>();
    final residenceId = widget.initialResidenceId?.trim();
    _draft = CreateShiftDraft(
      residenceId: residenceId == null || residenceId.isEmpty ? null : residenceId,
      shiftDate: widget.initialShiftDate ?? DateTime.now(),
    );
    _titleController = TextEditingController(text: _draft.title);
    _notesController = TextEditingController(text: _draft.notes);
    _requiredStaffCountController =
        TextEditingController(text: _draft.requiredStaffCount);
    _maxBidsController = TextEditingController(text: _draft.maxBids);
    _noteToBiddersController =
        TextEditingController(text: _draft.noteToBidders);
    _occurrenceController =
        TextEditingController(text: _draft.occurrenceCount);
    _messageController =
        TextEditingController(text: _draft.notificationMessage);
    _restOverrideReasonController =
        TextEditingController(text: _draft.restOverrideReason);
    _initialSnapshot = _draft.snapshot();
    _clockReady = _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadDefaultBreak();
    if (!mounted) return;
    if (_isEdit) await _loadShift();
    if (!mounted) return;
    _loadResidences();
    _loadStaff();
    _loadClients();
  }

  Future<void> _loadDefaultBreak() async {
    final result = await _repository.getDefaultBreakMinutes();
    if (!mounted || _isEdit) return;
    result.when(
      success: (minutes) => _update(() => _draft.breakMinutes = minutes),
      failure: (_) {},
    );
  }

  Future<void> _loadShift() async {
    setState(() {
      _isLoadingShift = true;
      _shiftError = null;
    });
    final result = await _repository.getShiftDraft(widget.editShiftId!);
    if (!mounted) return;
    result.when(
      success: (draft) => setState(() {
        _isLoadingShift = false;
        _draft = draft;
        _labelAssignedStaff();
        _titleController.text = draft.title;
        _notesController.text = draft.notes;
        _requiredStaffCountController.text = draft.requiredStaffCount;
        _maxBidsController.text = draft.maxBids;
        _noteToBiddersController.text = draft.noteToBidders;
        _occurrenceController.text = draft.occurrenceCount;
        _messageController.text = draft.notificationMessage;
        _initialSnapshot = draft.snapshot();
      }),
      failure: (error) => setState(() {
        _isLoadingShift = false;
        _shiftError = error.message;
      }),
    );
  }

  /// Fills each assigned person's role/residence from the staff list, like
  /// the web's `shiftToFormValues` staff-label lookup.
  void _labelAssignedStaff() {
    final staff = _draft.assignedStaff;
    for (var i = 0; i < staff.length; i++) {
      final current = staff[i];
      if (current.roleLabel.isNotEmpty || current.residenceLabel.isNotEmpty) {
        continue;
      }
      final option =
          _staffOptions.where((o) => o.id == current.staffId).firstOrNull;
      if (option == null) continue;
      staff[i] = AssignedShiftStaff(
        staffId: current.staffId,
        staffName: current.staffName,
        roleLabel: option.role ?? '',
        residenceLabel: option.residenceLabel ?? '',
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _requiredStaffCountController.dispose();
    _maxBidsController.dispose();
    _noteToBiddersController.dispose();
    _occurrenceController.dispose();
    _messageController.dispose();
    _restOverrideReasonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isDirty => _draft.snapshot() != _initialSnapshot;

  Future<void> _loadResidences() async {
    if (_isLoadingResidences) return;
    setState(() => _isLoadingResidences = true);
    final result = await _repository.getResidences();
    if (!mounted) return;
    final loaded = <ShiftResidenceOption>[];
    String? loadError;
    result.when(
      success: loaded.addAll,
      failure: (error) => loadError = error.message,
    );
    UserSession? session;
    try {
      session = Get.find<UserSession>();
    } catch (_) {}
    final merged = mergeResidencePickerOptions<ShiftResidenceOption>(
      loaded: loaded,
      idOf: (r) => r.id,
      nameOf: (r) => r.name,
      create: (id, name) => ShiftResidenceOption(id: id, name: name),
      sessionId: session?.residenceId,
      sessionName: session?.residenceName,
    );
    setState(() {
      _isLoadingResidences = false;
      _residences
        ..clear()
        ..addAll(merged);
    });
    if (loadError != null && merged.isEmpty) {
      AppSnackbar.show('Could not load residences', loadError!);
    }
  }

  Future<void> _loadStaff() async {
    if (_isLoadingStaff) return;
    final residenceId =
        _draft.residenceId.isEmpty ? null : _draft.residenceId;
    // Web only offers staff for the selected residence.
    if (residenceId == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingStaff = false;
        _staffError = null;
        _staffOptions.clear();
      });
      return;
    }
    setState(() {
      _isLoadingStaff = true;
      _staffError = null;
    });
    final result = await _repository.getStaffOptions(residenceId: residenceId);
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _isLoadingStaff = false;
        _staffOptions
          ..clear()
          ..addAll(data);
        final allowed = {for (final o in data) o.id};
        _draft.assignedStaff
            .removeWhere((s) => allowed.isNotEmpty && !allowed.contains(s.staffId));
        _labelAssignedStaff();
      }),
      failure: (error) => setState(() {
        _isLoadingStaff = false;
        _staffError = error.message;
      }),
    );
  }

  /// Applies a change, then re-checks only the fields already showing an
  /// error so messages clear (or update) as the user fixes them.
  void _update(VoidCallback change) {
    setState(() {
      change();
      if (_errors.isNotEmpty) {
        final current = _draft.validate();
        _errors = {
          for (final key in _errors.keys)
            if (current.containsKey(key)) key: current[key]!,
        };
      }
    });
    _refreshStaffConflicts();
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _staffingBlocked =>
      !_draft.isOpenShift &&
      (_conflicts.conflicts.isNotEmpty || _conflicts.leave.isNotEmpty);

  static const _staffingBlockedToast =
      'Someone on this shift is already rostered then, or on leave — change who is on it first.';

  /// Web `useShiftConflicts` plus the overlapping-shift "Has Shift" badge.
  /// The badge query is every residence; conflict banners stay on this home.
  Future<void> _refreshStaffConflicts() async {
    final serial = ++_conflictSerial;
    final window = _draft.shiftWindow;
    final staffIds = [
      for (final staff in _draft.assignedStaff) staff.staffId,
    ]..sort();

    if (window == null) {
      if (!mounted || serial != _conflictSerial) return;
      setState(() {
        _conflicts = const ShiftConflictsResult();
        _staffWithOverlappingShifts = {};
      });
      return;
    }

    final from = _dayKey(window.$1.subtract(const Duration(days: 1)));
    final to = _dayKey(window.$2.add(const Duration(days: 1)));
    final excludeId = widget.editShiftId;
    final residenceId = _draft.residenceId.isEmpty ? null : _draft.residenceId;

    // Web `useShifts` for the badge sends from/to/limit only, so a shift at
    // another residence still marks "(Has Shift)". Conflicts stay scoped
    // to the residence on this form.
    final shiftsFuture = _repository.listShiftsInRange(
      from: from,
      to: to,
    );
    final conflictsFuture = staffIds.isEmpty
        ? Future<Result<ShiftConflictsResult>>.value(
            Result.success(const ShiftConflictsResult()),
          )
        : _repository.checkStaffConflicts(
            staffIds: staffIds,
            startsAtIso: window.$1.toUtc().toIso8601String(),
            endsAtIso: window.$2.toUtc().toIso8601String(),
            residenceId: residenceId,
            excludeShiftId: excludeId,
          );

    final shiftsResult = await shiftsFuture;
    final conflictsResult = await conflictsFuture;
    if (!mounted || serial != _conflictSerial) return;

    final hasShift = <String>{};
    shiftsResult.when(
      success: (rows) {
        for (final row in rows) {
          if (excludeId != null && row.id == excludeId) continue;
          if (row.status == 'cancelled') continue;
          if (!row.startsAt.isBefore(window.$2)) continue;
          if (!row.endsAt.isAfter(window.$1)) continue;
          hasShift.addAll(row.staffIds);
        }
      },
      failure: (_) {},
    );

    var nextConflicts = const ShiftConflictsResult();
    conflictsResult.when(
      success: (value) => nextConflicts = value,
      failure: (_) {},
    );

    setState(() {
      _staffWithOverlappingShifts = hasShift;
      _conflicts = nextConflicts;
      if (nextConflicts.rest.isEmpty &&
          _draft.restOverrideReason.isNotEmpty) {
        _draft.restOverrideReason = '';
        _restOverrideReasonController.clear();
        _errors = {
          for (final entry in _errors.entries)
            if (entry.key != CreateShiftField.restOverrideReason)
              entry.key: entry.value,
        };
      }
    });
  }

  bool _validateRestOverrideReason() {
    if (_draft.isOpenShift || _conflicts.rest.isEmpty) {
      if (_errors.containsKey(CreateShiftField.restOverrideReason)) {
        setState(() {
          _errors = {
            for (final entry in _errors.entries)
              if (entry.key != CreateShiftField.restOverrideReason)
                entry.key: entry.value,
          };
        });
      }
      return true;
    }
    if (_draft.restOverrideReason.trim().isNotEmpty) {
      if (_errors.containsKey(CreateShiftField.restOverrideReason)) {
        setState(() {
          _errors = {
            for (final entry in _errors.entries)
              if (entry.key != CreateShiftField.restOverrideReason)
                entry.key: entry.value,
          };
        });
      }
      return true;
    }
    setState(() {
      _errors = {
        ..._errors,
        CreateShiftField.restOverrideReason:
            'Say why you are rostering them with less rest',
      };
    });
    return false;
  }

  void _onTextChanged(String _) {
    _update(() {
      _draft
        ..title = _titleController.text
        ..notes = _notesController.text
        ..requiredStaffCount = _requiredStaffCountController.text
        ..maxBids = _maxBidsController.text
        ..noteToBidders = _noteToBiddersController.text
        ..occurrenceCount = _occurrenceController.text
        ..notificationMessage = _messageController.text;
    });
  }

  /// Surface start/end overlap as soon as both times are set (web-parity UX).
  void _surfaceTimeOverlapError() {
    final current = _draft.validate();
    setState(() {
      final next = Map<String, String>.from(_errors);
      next.remove(CreateShiftField.startTime);
      next.remove(CreateShiftField.endTime);
      if (current.containsKey(CreateShiftField.endTime)) {
        next[CreateShiftField.endTime] = current[CreateShiftField.endTime]!;
      }
      if (current.containsKey(CreateShiftField.startTime)) {
        next[CreateShiftField.startTime] = current[CreateShiftField.startTime]!;
      }
      _errors = next;
    });
  }

  void _refreshBiddingError() {
    final message = _draft.validate()[CreateShiftField.biddingDeadline];
    setState(() {
      final next = Map<String, String>.from(_errors);
      if (message == null) {
        next.remove(CreateShiftField.biddingDeadline);
      } else {
        next[CreateShiftField.biddingDeadline] = message;
      }
      _errors = next;
    });
  }

  void _goTo(CreateShiftStep step) {
    if (step == CreateShiftStep.openShift) {
      step = CreateShiftStep.staffAssignment;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _next() {
    final stepErrors = _draft.validateStep(_step);
    if (stepErrors.isNotEmpty) {
      setState(() => _errors = {..._errors, ...stepErrors});
      return;
    }
    if (_step == CreateShiftStep.staffAssignment &&
        !_validateRestOverrideReason()) {
      return;
    }
    if (_step == CreateShiftStep.staffAssignment && _staffingBlocked) {
      AppSnackbar.show('Staff assignment', _staffingBlockedToast);
      return;
    }
    // Web combines Assign Staff + Open Shift on one step; skip the legacy
    // dedicated Open Shift page when staffing method was already chosen.
    var index = _step.index + 1;
    if (index == CreateShiftStep.openShift.index) {
      index += 1;
    }
    if (index < CreateShiftStep.values.length) {
      _goTo(CreateShiftStep.values[index]);
    }
  }

  void _goToGuarded(CreateShiftStep step) {
    // Web blocks leaving Staff Assignment while conflicts/leave are present.
    final leavingStaff =
        _step == CreateShiftStep.staffAssignment &&
        step != CreateShiftStep.staffAssignment;
    if (leavingStaff && !_validateRestOverrideReason()) {
      return;
    }
    if (leavingStaff && _staffingBlocked) {
      AppSnackbar.show('Staff assignment', _staffingBlockedToast);
      return;
    }
    _goTo(step);
  }

  void _back() {
    var index = _step.index - 1;
    if (index == CreateShiftStep.openShift.index) {
      index -= 1;
    }
    if (index >= 0) _goTo(CreateShiftStep.values[index]);
  }

  Future<void> _submit({bool asDraft = false}) async {
    if (_busyAction != null) return;
    await _clockReady;
    if (!mounted || _busyAction != null) return;
    final errors = _draft.validate();
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      _goTo(CreateShiftDraft.stepOf(errors.keys.first));
      return;
    }
    if (!asDraft && !_validateRestOverrideReason()) {
      _goTo(CreateShiftStep.staffAssignment);
      return;
    }
    if (!asDraft && _staffingBlocked) {
      AppSnackbar.show('Staff assignment', _staffingBlockedToast);
      _goTo(CreateShiftStep.staffAssignment);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busyAction = asDraft
          ? CreateShiftBusyAction.draft
          : CreateShiftBusyAction.submit;
      _submitError = null;
    });
    if (_isEdit) {
      await _saveEdit();
      return;
    }
    final result = await _repository.createShift(
      _draft.toCreateBody(asDraft: asDraft),
    );
    if (!mounted) return;
    result.when(
      success: (count) {
        Navigator.of(context).pop(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.show(
            asDraft
                ? (count == 1 ? 'Draft saved' : '$count drafts saved')
                : (count == 1 ? 'Shift created' : '$count shifts created'),
            '',
          );
        });
      },
      failure: (error) {
        setState(() {
          _busyAction = null;
          _submitError = error.message;
        });
        if (_isStaffingConflictCode(error.code)) {
          _goTo(CreateShiftStep.staffAssignment);
        }
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      },
    );
  }

  Future<void> _deleteShift() async {
    final id = widget.editShiftId;
    if (id == null || _busyAction != null) return;
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete this shift?',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textHeading,
          ),
        ),
        content: const Text(
          'This permanently removes the shift and any bids on it. This cannot be undone.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Keep shift',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.criticalRed,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busyAction = CreateShiftBusyAction.delete;
      _submitError = null;
    });
    final result = await _repository.deleteShift(id);
    if (!mounted) return;
    result.when(
      success: (_) {
        Navigator.of(context).pop(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.show('Shift deleted', '');
        });
      },
      failure: (error) {
        setState(() {
          _busyAction = null;
          _submitError = error.message;
        });
      },
    );
  }

  bool _isStaffingConflictCode(String? code) =>
      code == 'SHIFT_OVERLAP' ||
      code == 'STAFF_ON_LEAVE' ||
      code == 'INSUFFICIENT_REST';

  Future<void> _saveEdit({bool publishDraft = false}) async {
    final staffIds = [for (final staff in _draft.assignedStaff) staff.staffId];
    final staffUnchanged = staffIds.length == _draft.loadedStaffIds.length &&
        staffIds.toSet().containsAll(_draft.loadedStaffIds);
    // Publishing a draft notifies via PATCH; skip assignment PUT when staff
    // list is unchanged so assignees are not notified twice.
    final skipAssignments = publishDraft
        ? staffUnchanged
        : staffUnchanged &&
            (_draft.restOverrideReason.trim().isEmpty);
    final result = await _repository.updateShift(
      shiftId: widget.editShiftId!,
      payload: _draft.toUpdateBody(publishDraft: publishDraft),
      staffIds: staffIds,
      restOverrideReason: _draft.restOverrideReason,
      updateAssignments: !skipAssignments,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        Navigator.of(context).pop(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.show(
            publishDraft ? 'Shift published' : 'Shift updated',
            '',
          );
        });
      },
      failure: (error) {
        setState(() {
          _busyAction = null;
          _submitError = error.message;
        });
        if (_isStaffingConflictCode(error.code)) {
          _goTo(CreateShiftStep.staffAssignment);
        }
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      },
    );
  }

  Future<void> _publishDraft() async {
    if (_busyAction != null) return;
    await _clockReady;
    if (!mounted || _busyAction != null) return;
    final errors = _draft.validate();
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      _goTo(CreateShiftDraft.stepOf(errors.keys.first));
      return;
    }
    if (!_validateRestOverrideReason()) {
      _goTo(CreateShiftStep.staffAssignment);
      return;
    }
    if (_staffingBlocked) {
      AppSnackbar.show('Staff assignment', _staffingBlockedToast);
      _goTo(CreateShiftStep.staffAssignment);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busyAction = CreateShiftBusyAction.publish;
      _submitError = null;
    });
    await _saveEdit(publishDraft: true);
  }

  Future<void> _requestClose() async {
    if (_busyAction != null) return;
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Discard unsaved changes?',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textHeading,
          ),
        ),
        content: const Text(
          "You have unsaved edits on this form. If you leave now, they'll be lost.",
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
            onPressed: () => Navigator.of(dialogContext).pop(false),
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
            onPressed: () => Navigator.of(dialogContext).pop(true),
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
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<T?> _pickOption<T>({
    required String title,
    required List<ShiftFormChoice<T>> options,
    required T? selected,
    required bool hasSelection,
    bool searchable = false,
  }) {
    final query = TextEditingController();
    final sheet = showAppBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final needle = query.text.trim().toLowerCase();
          final visible = !searchable || needle.isEmpty
              ? options
              : [
                  for (final option in options)
                    if (option.label.toLowerCase().contains(needle)) option,
                ];
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
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
                    if (searchable)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: TextField(
                          controller: query,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search…',
                            isDense: true,
                          ),
                        ),
                      ),
                    for (final option in visible)
                      ListTile(
                        title: Text(
                          option.label,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            color: AppColors.textHeading,
                          ),
                        ),
                        trailing: hasSelection && option.value == selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.secondaryTeal,
                              )
                            : null,
                        onTap: () =>
                            Navigator.of(sheetContext).pop(option.value),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    return sheet.whenComplete(query.dispose);
  }

  Future<void> _pickResidence() async {
    if (_residences.isEmpty && !_isLoadingResidences) await _loadResidences();
    if (!mounted) return;
    if (_residences.isEmpty) {
      AppSnackbar.show('No residences', 'No residences are available.');
      return;
    }
    final id = await _pickOption<String>(
      title: 'Residence',
      options: [
        for (final residence in _residences)
          ShiftFormChoice(residence.id, residence.name),
      ],
      selected: _draft.residenceId,
      hasSelection: _draft.residenceId.isNotEmpty,
    );
    if (id == null || id == _draft.residenceId) return;
    _update(() {
      _draft.residenceId = id;
      _draft.oneToOneClientId = null;
      _draft.oneToOneClientName = null;
      _draft.assignedStaff.clear();
    });
    _loadClients();
    _loadStaff();
  }

  Future<void> _loadClients() async {
    final residenceId = _draft.residenceId;
    if (residenceId.isEmpty) {
      if (_clients.isNotEmpty && mounted) setState(() => _clients = []);
      return;
    }
    final result = await _repository.getClients(residenceId);
    if (!mounted || _draft.residenceId != residenceId) return;
    result.when(
      success: (rows) => setState(() {
        _clients = rows;
        final selected = _draft.oneToOneClientId;
        if (selected == null) return;
        ShiftClientOption? match;
        for (final row in rows) {
          if (row.id == selected) match = row;
        }
        if (match == null) {
          _draft.oneToOneClientId = null;
          _draft.oneToOneClientName = null;
        } else {
          _draft.oneToOneClientName = match.name;
        }
      }),
      failure: (_) => setState(() => _clients = []),
    );
  }

  Future<void> _pickOneToOne() async {
    if (_draft.residenceId.isEmpty) return;
    final id = await _pickOption<String>(
      title: 'One-to-one with',
      searchable: true,
      options: [
        const ShiftFormChoice('', 'Not one-to-one'),
        for (final client in _clients)
          ShiftFormChoice(client.id, client.name),
      ],
      selected: _draft.oneToOneClientId ?? '',
      hasSelection: true,
    );
    if (id == null) return;
    String? name;
    for (final client in _clients) {
      if (client.id == id) name = client.name;
    }
    _update(() {
      _draft.oneToOneClientId = id.isEmpty ? null : id;
      _draft.oneToOneClientName = id.isEmpty ? null : name;
    });
  }

  Future<void> _pickShiftType() async {
    final id = await _pickOption<String>(
      title: 'Shift Type',
      options: [
        for (final option in ShiftTypeOption.predefined)
          ShiftFormChoice(option.id, option.label),
      ],
      selected: _draft.shiftType,
      hasSelection: _draft.shiftType.isNotEmpty,
    );
    if (id == null) return;
    final option = ShiftTypeOption.predefined.firstWhere((o) => o.id == id);
    _update(() => _draft.applyShiftType(option));
  }

  Future<void> _pickBreak() async {
    final minutes = await _pickOption<int>(
      title: 'Break Duration',
      options: [
        for (final option in ShiftBreakDurationOption.predefined)
          ShiftFormChoice(option.minutes, option.label),
      ],
      selected: _draft.breakMinutes,
      hasSelection: true,
    );
    if (minutes != null) _update(() => _draft.breakMinutes = minutes);
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    final initial = current ?? DateTime(now.year, now.month, now.day);
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3, 12, 31),
      builder: _pickerTheme,
    );
  }

  Future<int?> _pickTime(int? current) async {
    final minutes = current ?? 0;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: _pickerTheme(context, child),
      ),
    );
    if (selected == null) return null;
    return selected.hour * 60 + selected.minute;
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.secondaryTeal,
            ),
      ),
      child: child!,
    );
  }

  Future<void> _openStaffPicker() async {
    if (_staffOptions.isEmpty && !_isLoadingStaff) await _loadStaff();
    await _refreshStaffConflicts();
    if (!mounted) return;
    await showCreateShiftStaffPicker(
      context: context,
      options: _staffOptions,
      selectedIds: {for (final staff in _draft.assignedStaff) staff.staffId},
      hasShiftIds: _staffWithOverlappingShifts,
      errorMessage: _staffError,
      onRetry: _loadStaff,
      onToggle: _toggleStaff,
    );
  }

  void _toggleStaff(ShiftStaffOption option) {
    _update(() {
      final index =
          _draft.assignedStaff.indexWhere((s) => s.staffId == option.id);
      if (index >= 0) {
        _draft.assignedStaff.removeAt(index);
      } else {
        _draft.assignedStaff.add(AssignedShiftStaff.fromOption(option));
      }
    });
  }

  void _removeStaff(String staffId) {
    _update(() {
      _draft.assignedStaff.removeWhere((s) => s.staffId == staffId);
    });
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Settings → General time format (same for every role).
  ///
  /// Create-shift chips keep zero-padded hours (`07:00 AM` / `07:00`) to match
  /// the web inputs; the 12h vs 24h choice still comes from tenant settings.
  static String? formatShiftTime(int? minutes) {
    if (minutes == null) return null;
    final hour = minutes ~/ 60;
    final m = (minutes % 60).toString().padLeft(2, '0');
    if (TenantClock.is24Hour) {
      return '${hour.toString().padLeft(2, '0')}:$m';
    }
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${h12.toString().padLeft(2, '0')}:$m ${hour < 12 ? 'AM' : 'PM'}';
  }

  String? _formatTime(int? minutes) => formatShiftTime(minutes);

  String? get _residenceLabel {
    if (_draft.residenceId.isEmpty) return null;
    for (final residence in _residences) {
      if (residence.id == _draft.residenceId) return residence.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final completed = {
      for (final step in CreateShiftStep.values)
        if (_draft.isStepComplete(step)) step,
    };
    final isFirst = _step == CreateShiftStep.values.first;
    final isLast = _step == CreateShiftStep.values.last;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceWhite,
        body: SafeArea(
          child: Column(
            children: [
              CreateShiftHeader(
                title: _isEdit
                    ? (_draft.isLoadedDraft ? 'Edit Draft Shift' : 'Edit Shift')
                    : 'Add New Shift',
                onClose: _busyAction != null ? null : _requestClose,
              ),
              if (_isLoadingShift || _shiftError != null)
                Expanded(child: _shiftLoadState())
              else ...[
                CreateShiftStepTabs(
                  selected: _step,
                  completed: completed,
                  onSelected: _busyAction != null ? null : _goToGuarded,
                ),
                CreateShiftCompletionBar(
                  currentStep: CreateShiftStepX.visibleSteps
                      .where(_draft.isStepComplete)
                      .length,
                  totalSteps: CreateShiftStepX.visibleSteps.length,
                  percent: (() {
                    final total = CreateShiftStepX.visibleSteps.length;
                    if (total == 0) return 0.0;
                    final done = CreateShiftStepX.visibleSteps
                        .where(_draft.isStepComplete)
                        .length;
                    return (done / total * 100).roundToDouble();
                  })(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_submitError != null) _SubmitErrorBanner(_submitError!),
                        _bodyForStep(),
                      ],
                    ),
                  ),
                ),
                CreateShiftFooter(
                  isFirstStep: isFirst,
                  isLastStep: isLast,
                  busyAction: _busyAction,
                  plannedOccurrences: _draft.plannedOccurrences(),
                  onCancel: _requestClose,
                  onBack: _back,
                  onNext: _next,
                  onSubmit: () => _submit(),
                  onSaveDraft: _isEdit ? null : () => _submit(asDraft: true),
                  onPublish: _isEdit && _draft.isLoadedDraft
                      ? _publishDraft
                      : null,
                  onDelete: _isEdit ? _deleteShift : null,
                  isEdit: _isEdit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _shiftLoadState() {
    if (_isLoadingShift) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryTeal),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _shiftError ?? 'Could not load this shift.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadShift, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _bodyForStep() {
    switch (_step) {
      case CreateShiftStep.shiftInformation:
        return CreateShiftInfoForm(
          titleController: _titleController,
          notesController: _notesController,
          residenceValue: _residenceLabel,
          isLoadingResidences:
              _isLoadingResidences && _draft.residenceId.isNotEmpty,
          onResidenceTap: _pickResidence,
          shiftTypeValue: _draft.shiftTypeOption?.label,
          onShiftTypeTap: _pickShiftType,
          shiftDateValue: _formatDate(_draft.shiftDate),
          onShiftDateTap: () async {
            final date = await _pickDate(_draft.shiftDate);
            if (date != null) _update(() => _draft.shiftDate = date);
          },
          startTimeValue: _formatTime(_draft.startMinutes),
          onStartTimeTap: () async {
            final time = await _pickTime(_draft.startMinutes);
            if (time != null) {
              _update(() => _draft.startMinutes = time);
              _surfaceTimeOverlapError();
            }
          },
          endTimeValue: _formatTime(_draft.endMinutes),
          onEndTimeTap: () async {
            final time = await _pickTime(_draft.endMinutes);
            if (time != null) {
              _update(() => _draft.endMinutes = time);
              _surfaceTimeOverlapError();
            }
          },
          breakDurationValue: CreateShiftChoices.labelOf(
            [
              for (final option in ShiftBreakDurationOption.predefined)
                ShiftFormChoice(option.minutes, option.label),
            ],
            _draft.breakMinutes,
          ),
          onBreakDurationTap: _pickBreak,
          oneToOneValue: _draft.oneToOneClientName ?? 'Not one-to-one',
          oneToOneEnabled: _draft.residenceId.isNotEmpty,
          onOneToOneTap: _pickOneToOne,
          onTextChanged: _onTextChanged,
          errors: _errors,
        );
      case CreateShiftStep.staffAssignment:
        return CreateShiftStaffAssignmentForm(
          assignedStaff: _draft.assignedStaff,
          isLoadingStaff: _isLoadingStaff,
          isOpenShift: _draft.isOpenShift,
          scheduleConflicts: _conflicts.conflicts,
          leaveConflicts: _conflicts.leave,
          restConflicts: _conflicts.rest,
          minimumRestHours: _conflicts.minimumRestHours,
          restOverrideReasonController: _restOverrideReasonController,
          restOverrideReasonError:
              _errors[CreateShiftField.restOverrideReason],
          onRestOverrideReasonChanged: (value) => _update(() {
            _draft.restOverrideReason = value;
          }),
          residenceName: _residenceLabel,
          onOpenShiftChanged: (value) => _update(() {
            // Keep assigned staff while toggling methods so switching back
            // to "Assign Specific Staff" restores the previous picks.
            _draft.isOpenShift = value;
          }),
          openShiftFields: CreateShiftOpenShiftForm(
            embedded: true,
            isOpenShift: true,
            onChanged: (_) {},
            requiredStaffCountController: _requiredStaffCountController,
            maxBidsController: _maxBidsController,
            noteToBiddersController: _noteToBiddersController,
            deadlineDateValue: _formatDate(_draft.biddingDeadlineDate),
            deadlineError: _errors[CreateShiftField.biddingDeadline],
            onDeadlineDateTap: () async {
              final date = await _pickDate(_draft.biddingDeadlineDate);
              if (date != null) {
                _update(() => _draft.biddingDeadlineDate = date);
                _refreshBiddingError();
              }
            },
            deadlineTimeValue: _formatTime(_draft.biddingDeadlineMinutes),
            onDeadlineTimeTap: () async {
              final time = await _pickTime(_draft.biddingDeadlineMinutes);
              if (time != null) {
                _update(() => _draft.biddingDeadlineMinutes = time);
                _refreshBiddingError();
              }
            },
            priorityValue: CreateShiftChoices.labelOf(
              CreateShiftChoices.priorities,
              _draft.priority,
            ),
            onPriorityTap: () async {
              final value = await _pickOption<String>(
                title: 'Priority',
                options: CreateShiftChoices.priorities,
                selected: _draft.priority,
                hasSelection: true,
              );
              if (value != null) _update(() => _draft.priority = value);
            },
            awardMethodValue: CreateShiftChoices.labelOf(
              CreateShiftChoices.awardMethods,
              _draft.awardMethod,
            ),
            onAwardMethodTap: () async {
              final value = await _pickOption<String>(
                title: 'Award Method',
                options: CreateShiftChoices.awardMethods,
                selected: _draft.awardMethod,
                hasSelection: true,
              );
              if (value != null) _update(() => _draft.awardMethod = value);
            },
            onTextChanged: _onTextChanged,
          ),
          onAddStaff: _openStaffPicker,
          onRemoveStaff: _removeStaff,
        );
      case CreateShiftStep.openShift:
        // Legacy step — navigation skips this; kept for enum/progress parity.
        return const SizedBox.shrink();
      case CreateShiftStep.recurring:
        return CreateShiftRecurringForm(
          isRecurring: _draft.isRecurring,
          onChanged: (value) => _update(() => _draft.isRecurring = value),
          frequencyValue: CreateShiftChoices.labelOf(
            CreateShiftChoices.frequencies,
            _draft.recurrenceFrequency,
          ),
          onFrequencyTap: () async {
            final value = await _pickOption<int>(
              title: 'Frequency',
              options: CreateShiftChoices.frequencies,
              selected: _draft.recurrenceFrequency,
              hasSelection: true,
            );
            if (value != null) {
              _update(() => _draft.recurrenceFrequency = value);
            }
          },
          repeatOnDays: _draft.repeatOnDays,
          onToggleDay: (day) => _update(() {
            if (!_draft.repeatOnDays.remove(day)) _draft.repeatOnDays.add(day);
          }),
          ends: _draft.ends,
          onEndsChanged: (value) => _update(() => _draft.ends = value),
          endDateValue: _formatDate(_draft.endDate),
          onEndDateTap: () async {
            final date = await _pickDate(_draft.endDate ?? _draft.shiftDate);
            if (date != null) _update(() => _draft.endDate = date);
          },
          occurrenceController: _occurrenceController,
          onTextChanged: _onTextChanged,
          plannedOccurrences:
              _draft.shiftDate == null ? 0 : _draft.plannedOccurrences(),
          errors: _errors,
        );
      case CreateShiftStep.notifications:
        return CreateShiftNotificationsForm(
          notifyAssignedStaff: _draft.notifyAssignedStaff,
          onNotifyAssignedStaffChanged: (value) =>
              _update(() => _draft.notifyAssignedStaff = value),
          reminderValue: _draft.reminderMinutes == null
              ? null
              : CreateShiftChoices.labelOf(
                  CreateShiftChoices.reminders,
                  _draft.reminderMinutes,
                ),
          onReminderTap: _pickReminder,
          messageController: _messageController,
          onTextChanged: _onTextChanged,
        );
    }
  }

  Future<void> _pickReminder() async {
    const noReminder = -1;
    final value = await _pickOption<int>(
      title: 'Reminder',
      options: [
        for (final option in CreateShiftChoices.reminders)
          ShiftFormChoice(option.value ?? noReminder, option.label),
      ],
      selected: _draft.reminderMinutes,
      hasSelection: _draft.reminderMinutes != null,
    );
    if (value == null) return;
    _update(
      () => _draft.reminderMinutes = value == noReminder ? null : value,
    );
  }
}

class _SubmitErrorBanner extends StatelessWidget {
  final String message;

  const _SubmitErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('create-shift-submit-error'),
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.criticalRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.5,
            color: AppColors.criticalRed,
          ),
        ),
      ),
    );
  }
}
