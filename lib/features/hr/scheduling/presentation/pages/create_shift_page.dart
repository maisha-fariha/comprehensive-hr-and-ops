import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/create_shift_draft.dart';
import '../../domain/entities/shift_break_duration_option.dart';
import '../../domain/entities/shift_residence_option.dart';
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

/// "Add New Shift" wizard — same steps, fields, validation and
/// `POST /shifts` body as the web scheduling dialog.
class CreateShiftPage extends StatefulWidget {
  /// Pre-selected residence (the scheduling page's residence filter).
  final String? initialResidenceId;

  /// Pre-filled shift date (the scheduling page's selected day).
  final DateTime? initialShiftDate;

  const CreateShiftPage({
    super.key,
    this.initialResidenceId,
    this.initialShiftDate,
  });

  @override
  State<CreateShiftPage> createState() => _CreateShiftPageState();
}

class _CreateShiftPageState extends State<CreateShiftPage> {
  late final SchedulingRepository _repository;
  late final CreateShiftDraft _draft;
  late final String _initialSnapshot;

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _requiredStaffCountController;
  late final TextEditingController _maxBidsController;
  late final TextEditingController _noteToBiddersController;
  late final TextEditingController _occurrenceController;
  late final TextEditingController _messageController;
  final ScrollController _scrollController = ScrollController();

  CreateShiftStep _step = CreateShiftStep.shiftInformation;
  Map<String, String> _errors = const {};
  String? _submitError;
  bool _isSubmitting = false;

  final List<ShiftResidenceOption> _residences = [];
  bool _isLoadingResidences = false;

  final List<ShiftStaffOption> _staffOptions = [];
  bool _isLoadingStaff = false;
  String? _staffError;
  String? _expandedStaffId;

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
    _initialSnapshot = _draft.snapshot();
    _loadResidences();
    _loadStaff();
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
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isDirty => _draft.snapshot() != _initialSnapshot;

  Future<void> _loadResidences() async {
    if (_isLoadingResidences) return;
    setState(() => _isLoadingResidences = true);
    final result = await _repository.getResidences();
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _isLoadingResidences = false;
        _residences
          ..clear()
          ..addAll(data);
      }),
      failure: (error) {
        setState(() => _isLoadingResidences = false);
        AppSnackbar.show('Could not load residences', error.message);
      },
    );
  }

  Future<void> _loadStaff() async {
    if (_isLoadingStaff) return;
    setState(() {
      _isLoadingStaff = true;
      _staffError = null;
    });
    final result = await _repository.getStaffOptions();
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _isLoadingStaff = false;
        _staffOptions
          ..clear()
          ..addAll(data);
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

  void _goTo(CreateShiftStep step) {
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
    final index = _step.index;
    if (index < CreateShiftStep.values.length - 1) {
      _goTo(CreateShiftStep.values[index + 1]);
    }
  }

  void _back() {
    final index = _step.index;
    if (index > 0) _goTo(CreateShiftStep.values[index - 1]);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final errors = _draft.validate();
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      _goTo(CreateShiftDraft.stepOf(errors.keys.first));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    final result = await _repository.createShift(_draft.toCreateBody());
    if (!mounted) return;
    result.when(
      success: (count) {
        Navigator.of(context).pop(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.show(
            count == 1 ? 'Shift created' : '$count shifts created',
            '',
          );
        });
      },
      failure: (error) {
        setState(() {
          _isSubmitting = false;
          _submitError = error.message;
        });
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      },
    );
  }

  Future<void> _requestClose() async {
    if (_isSubmitting) return;
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
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
              for (final option in options)
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
                  onTap: () => Navigator.of(sheetContext).pop(option.value),
                ),
            ],
          ),
        ),
      ),
    );
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
    if (id != null) _update(() => _draft.residenceId = id);
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
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
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
    if (!mounted) return;
    await showCreateShiftStaffPicker(
      context: context,
      options: _staffOptions,
      selectedIds: {for (final staff in _draft.assignedStaff) staff.staffId},
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
        if (_expandedStaffId == option.id) _expandedStaffId = null;
      } else {
        _draft.assignedStaff.add(AssignedShiftStaff.fromOption(option));
        _expandedStaffId = option.id;
      }
    });
  }

  void _removeStaff(String staffId) {
    _update(() {
      _draft.assignedStaff.removeWhere((s) => s.staffId == staffId);
      if (_expandedStaffId == staffId) _expandedStaffId = null;
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

  String? _formatTime(int? minutes) {
    if (minutes == null) return null;
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

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
                onClose: _isSubmitting ? null : _requestClose,
              ),
              CreateShiftStepTabs(
                selected: _step,
                completed: completed,
                onSelected: _isSubmitting ? null : _goTo,
              ),
              CreateShiftCompletionBar(
                currentStep: _draft.completedSteps,
                totalSteps: CreateShiftStep.values.length,
                percent: _draft.completionPercent.toDouble(),
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
                isSubmitting: _isSubmitting,
                plannedOccurrences: _draft.plannedOccurrences(),
                onCancel: _requestClose,
                onBack: _back,
                onNext: _next,
                onSubmit: _submit,
              ),
            ],
          ),
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
            if (time != null) _update(() => _draft.startMinutes = time);
          },
          endTimeValue: _formatTime(_draft.endMinutes),
          onEndTimeTap: () async {
            final time = await _pickTime(_draft.endMinutes);
            if (time != null) _update(() => _draft.endMinutes = time);
          },
          breakDurationValue: CreateShiftChoices.labelOf(
            [
              for (final option in ShiftBreakDurationOption.predefined)
                ShiftFormChoice(option.minutes, option.label),
            ],
            _draft.breakMinutes,
          ),
          onBreakDurationTap: _pickBreak,
          onTextChanged: _onTextChanged,
          errors: _errors,
        );
      case CreateShiftStep.staffAssignment:
        return CreateShiftStaffAssignmentForm(
          assignedStaff: _draft.assignedStaff,
          expandedStaffId: _expandedStaffId,
          isLoadingStaff: _isLoadingStaff,
          onAddStaff: _openStaffPicker,
          onRemoveStaff: _removeStaff,
          onToggleExpand: (id) => setState(
            () => _expandedStaffId = _expandedStaffId == id ? null : id,
          ),
          onChanged: () => setState(() {}),
        );
      case CreateShiftStep.openShift:
        return CreateShiftOpenShiftForm(
          isOpenShift: _draft.isOpenShift,
          onChanged: (value) => _update(() => _draft.isOpenShift = value),
          requiredStaffCountController: _requiredStaffCountController,
          maxBidsController: _maxBidsController,
          noteToBiddersController: _noteToBiddersController,
          deadlineDateValue: _formatDate(_draft.biddingDeadlineDate),
          onDeadlineDateTap: () async {
            final date = await _pickDate(_draft.biddingDeadlineDate);
            if (date != null) _update(() => _draft.biddingDeadlineDate = date);
          },
          deadlineTimeValue: _formatTime(_draft.biddingDeadlineMinutes),
          onDeadlineTimeTap: () async {
            final time = await _pickTime(_draft.biddingDeadlineMinutes);
            if (time != null) {
              _update(() => _draft.biddingDeadlineMinutes = time);
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
        );
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
