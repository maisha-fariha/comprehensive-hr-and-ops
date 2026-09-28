import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../hr/scheduling/domain/entities/shift_break_duration_option.dart';
import '../../../../hr/scheduling/domain/entities/shift_reminder_option.dart';
import '../../../../hr/scheduling/domain/entities/shift_type_option.dart';
import '../../../../hr/scheduling/presentation/widgets/create_shift/create_shift_fields.dart';
import '../../../../hr/scheduling/presentation/widgets/create_shift/create_shift_header.dart';
import '../../../../hr/scheduling/presentation/widgets/create_shift/create_shift_notifications_form.dart';
import '../../../../hr/scheduling/presentation/widgets/create_shift/create_shift_open_shift_form.dart';
import '../../../../hr/scheduling/presentation/widgets/create_shift/create_shift_recurring_form.dart';
import '../../domain/entities/staff_shift_form_option.dart';
import '../../domain/repositories/staff_schedule_repository.dart';

/// Staff "Add New Shift" wizard matching web parity (BUG_Report004).
class StaffCreateShiftPage extends StatefulWidget {
  final StaffScheduleRepository repository;
  final DateTime initialDate;

  const StaffCreateShiftPage({
    super.key,
    required this.repository,
    required this.initialDate,
  });

  @override
  State<StaffCreateShiftPage> createState() => _StaffCreateShiftPageState();
}

class _StaffCreateShiftPageState extends State<StaffCreateShiftPage> {
  static const _steps = [
    _WizardStep(
      title: 'Shift Information',
      subtitle: 'Timing & residence',
      keySuffix: 'shift-information',
      icon: Icons.calendar_today_outlined,
    ),
    _WizardStep(
      title: 'Staff Assignment',
      subtitle: 'Assign or leave open',
      keySuffix: 'staff-assignment',
      icon: Icons.groups_outlined,
    ),
    _WizardStep(
      title: 'Open Shift',
      subtitle: 'Bidding & eligibility',
      keySuffix: 'open-shift',
      icon: Icons.wifi_tethering_rounded,
    ),
    _WizardStep(
      title: 'Recurring',
      subtitle: 'Repeat pattern',
      keySuffix: 'recurring',
      icon: Icons.autorenew_rounded,
    ),
    _WizardStep(
      title: 'Notifications',
      subtitle: 'Alerts & reminders',
      keySuffix: 'notifications',
      icon: Icons.notifications_none_rounded,
    ),
  ];

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _messageController = TextEditingController();
  final _checklistDraftControllers = <String, TextEditingController>{};

  final List<StaffShiftResidenceOption> _residences = [];
  final List<StaffShiftStaffOption> _staffPool = [];
  final Map<String, _StaffAssignmentDraft> _assignments = {};

  StaffShiftResidenceOption? _selectedResidence;
  ShiftTypeOption _selectedShiftType = ShiftTypeOption.predefined.first;
  ShiftBreakDurationOption _selectedBreak =
      ShiftBreakDurationOption.defaultOption;
  ShiftReminderOption _selectedReminder = ShiftReminderOption.defaultOption;

  DateTime _shiftDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 15, minute: 0);

  int _currentStep = 0;
  bool _isLoadingResidences = false;
  bool _isLoadingStaff = false;
  bool _isSubmitting = false;
  bool _isOpenShift = false;
  bool _isRecurring = false;
  bool _notifyAssignedStaff = true;

  @override
  void initState() {
    super.initState();
    _shiftDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _applyShiftTypeTimes(_selectedShiftType);
    _seedResidenceFromSession();
    _loadResidences();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _messageController.dispose();
    for (final draft in _assignments.values) {
      draft.dispose();
    }
    for (final c in _checklistDraftControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedResidenceFromSession() {
    final session = Get.find<UserSession>();
    final id = session.residenceId;
    final name = session.residenceName;
    if (id == null || id.isEmpty) return;
    _selectedResidence = StaffShiftResidenceOption(
      id: id,
      name: (name == null || name.isEmpty) ? 'Assigned residence' : name,
    );
  }

  void _applyShiftTypeTimes(ShiftTypeOption type) {
    if (!type.hasPresetTimes) return;
    _startTime = TimeOfDay(hour: type.startHour!, minute: type.startMinute!);
    _endTime = TimeOfDay(hour: type.endHour!, minute: type.endMinute!);
  }

  Future<void> _loadResidences() async {
    setState(() => _isLoadingResidences = true);
    final result = await widget.repository.getResidences();
    if (!mounted) return;
    setState(() => _isLoadingResidences = false);
    result.when(
      success: (data) {
        setState(() {
          _residences
            ..clear()
            ..addAll(data);
          final selectedId = _selectedResidence?.id;
          if (selectedId != null) {
            for (final option in data) {
              if (option.id == selectedId) {
                _selectedResidence = option;
                break;
              }
            }
          } else if (data.isNotEmpty) {
            _selectedResidence = data.first;
          }
        });
      },
      failure: (error) =>
          AppSnackbar.show('Could not load residences', error.message),
    );
  }

  Future<void> _loadStaffPool({String? search}) async {
    setState(() => _isLoadingStaff = true);
    final result = await widget.repository.searchStaff(
      search: search,
      residenceId: _selectedResidence?.id,
    );
    if (!mounted) return;
    setState(() => _isLoadingStaff = false);
    result.when(
      success: (data) => setState(() {
        _staffPool
          ..clear()
          ..addAll(data);
      }),
      failure: (error) =>
          AppSnackbar.show('Could not load staff', error.message),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _shiftDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) {
      setState(() {
        _shiftDate = DateTime(selected.year, selected.month, selected.day);
      });
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
      _selectedShiftType = const ShiftTypeOption(
        id: 'custom',
        name: 'Custom',
        label: 'Custom',
      );
    });
  }

  Future<void> _pickFromSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T> onSelected,
  }) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  ),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(labelOf(option)),
                  onTap: () => Navigator.pop(context, option),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) onSelected(selected);
  }

  Future<void> _showAddStaffPicker() async {
    await _loadStaffPool();
    if (!mounted) return;
    final searchController = TextEditingController();
    Timer? debounce;

    final picked = await showModalBottomSheet<StaffShiftStaffOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.7,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Add staff',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search staff by name...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (value) {
                          debounce?.cancel();
                          debounce = Timer(
                            const Duration(milliseconds: 350),
                            () async {
                              await _loadStaffPool(search: value);
                              if (context.mounted) setModalState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _isLoadingStaff
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: _staffPool.length,
                              itemBuilder: (context, index) {
                                final staff = _staffPool[index];
                                final already =
                                    _assignments.containsKey(staff.id);
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFE8E4F5),
                                    child: Text(
                                      staff.initials,
                                      style: const TextStyle(
                                        color: Color(0xFF5B4B8A),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  title: Text(staff.name),
                                  subtitle: Text(
                                    staff.detail.isEmpty
                                        ? 'No category recorded'
                                        : staff.detail,
                                  ),
                                  trailing: already
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: AppColors.secondaryTeal,
                                        )
                                      : null,
                                  onTap: already
                                      ? null
                                      : () => Navigator.pop(context, staff),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    debounce?.cancel();
    searchController.dispose();
    if (picked == null || !mounted) return;
    setState(() {
      _assignments[picked.id] = _StaffAssignmentDraft(staff: picked);
      _checklistDraftControllers[picked.id] = TextEditingController();
    });
  }

  void _removeAssignment(String staffId) {
    setState(() {
      _assignments.remove(staffId)?.dispose();
      _checklistDraftControllers.remove(staffId)?.dispose();
    });
  }

  void _addChecklistItem(String staffId) {
    final draft = _checklistDraftControllers[staffId];
    final text = draft?.text.trim() ?? '';
    if (text.isEmpty) return;
    setState(() {
      _assignments[staffId]?.checklist.add(text);
      draft?.clear();
    });
  }

  bool _validateCurrentStep() {
    if (_currentStep != 0) return true;
    if (_selectedResidence == null || _selectedResidence!.id.trim().isEmpty) {
      AppSnackbar.show('Missing details', 'Please select a residence.');
      return false;
    }
    return true;
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep == 0) {
      Get.back();
      return;
    }
    setState(() => _currentStep--);
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Map<String, dynamic> _buildPayload() {
    final startsAt = _combine(_shiftDate, _startTime);
    var endsAt = _combine(_shiftDate, _endTime);
    if (!endsAt.isAfter(startsAt)) {
      endsAt = endsAt.add(const Duration(days: 1));
    }

    final staffIds = _assignments.keys.toList();
    final assignments = <Map<String, dynamic>>[];
    for (final entry in _assignments.entries) {
      final draft = entry.value;
      final taskTitle = draft.taskTitleController.text.trim();
      final taskDescription = draft.taskDescriptionController.text.trim();
      if (taskTitle.isEmpty &&
          taskDescription.isEmpty &&
          draft.checklist.isEmpty) {
        continue;
      }
      assignments.add({
        'staffId': entry.key,
        'taskTitle': taskTitle,
        'taskDescription': taskDescription,
        'checklist': draft.checklist,
      });
    }

    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    final message = _messageController.text.trim();

    final payload = <String, dynamic>{
      'residenceId': _selectedResidence!.id,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      'shiftType': _selectedShiftType.id,
      'breakMinutes': _selectedBreak.minutes,
      'requiredStaffCount': staffIds.isEmpty ? 1 : staffIds.length,
      'staffIds': staffIds,
      'notifyAssignedStaff': _notifyAssignedStaff,
      if (title.isNotEmpty) 'title': title,
      if (notes.isNotEmpty) 'notes': notes,
      if (_selectedReminder.minutesBefore != null)
        'reminderMinutesBefore': _selectedReminder.minutesBefore,
      if (message.isNotEmpty) 'notificationMessage': message,
      if (assignments.isNotEmpty) 'assignments': assignments,
    };

    if (_isOpenShift) {
      final closesAt = DateTime(
        _shiftDate.year,
        _shiftDate.month,
        _shiftDate.day,
      ).subtract(const Duration(minutes: 1));
      payload['biddingConfig'] = {
        'biddingClosesAt': closesAt.toUtc().toIso8601String(),
        'maxBids': 5,
        'priority': 'medium',
        'awardMethod': 'manual',
        'noteToBidders': 'Open to all qualified care workers.',
      };
    }

    if (_isRecurring) {
      payload['recurrence'] = {
        'occurrences': 4,
        'intervalDays': 7,
        'weekdays': [_shiftDate.weekday],
      };
    }

    return payload;
  }

  Future<void> _createShift() async {
    if (_isSubmitting || !_validateCurrentStep()) return;
    setState(() => _isSubmitting = true);
    final result = await widget.repository.createShift(_buildPayload());
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        AppSnackbar.show(
          'Shift created',
          'Your shift was added to the schedule.',
        );
        Get.back(result: true);
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not create shift',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedSteps = _currentStep;
    final percent = ((completedSteps / _steps.length) * 100).round();

    return Scaffold(
      key: const Key('staff-create-shift-page'),
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            CreateShiftHeader(onClose: () => Get.back()),
            const Divider(height: 1, color: AppColors.cardBorder),
            _StepSidebar(
              steps: _steps,
              currentStep: _currentStep,
              completedSteps: completedSteps,
              percent: percent,
              onTap: (index) {
                if (index <= _currentStep || _validateCurrentStep()) {
                  setState(() => _currentStep = index);
                }
              },
            ),
            Expanded(
              child: KeyedSubtree(
                key: Key(
                  'staff-create-shift-step-${_steps[_currentStep].keySuffix}',
                ),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [_buildStepBody()],
                ),
              ),
            ),
            _Footer(
              isFirst: _currentStep == 0,
              isLast: _currentStep == _steps.length - 1,
              isSubmitting: _isSubmitting,
              onBack: _back,
              onNext: _next,
              onCreate: _createShift,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    return switch (_currentStep) {
      0 => _buildShiftInformation(),
      1 => _buildStaffAssignment(),
      2 => CreateShiftOpenShiftForm(
          isOpenShift: _isOpenShift,
          onChanged: (value) => setState(() => _isOpenShift = value),
        ),
      3 => CreateShiftRecurringForm(
          isRecurring: _isRecurring,
          onChanged: (value) => setState(() => _isRecurring = value),
        ),
      _ => CreateShiftNotificationsForm(
          notifyAssignedStaff: _notifyAssignedStaff,
          onNotifyAssignedStaffChanged: (value) =>
              setState(() => _notifyAssignedStaff = value),
          selectedReminder: _selectedReminder,
          onReminderTap: () => _pickFromSheet<ShiftReminderOption>(
            title: 'Reminder',
            options: ShiftReminderOption.predefined,
            labelOf: (o) => o.label,
            onSelected: (o) => setState(() => _selectedReminder = o),
          ),
          messageController: _messageController,
        ),
    };
  }

  Widget _buildShiftInformation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shift Information',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set the timing, residence, and role coverage for this shift.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const CreateShiftFieldLabel('Residence', required: true),
          CreateShiftDropdownField(
            value: _selectedResidence?.name,
            placeholder: _isLoadingResidences
                ? 'Loading residences…'
                : 'Select residence',
            onTap: () => _pickFromSheet<StaffShiftResidenceOption>(
              title: 'Residence',
              options: _residences,
              labelOf: (o) => o.name,
              onSelected: (o) {
                setState(() => _selectedResidence = o);
                _loadStaffPool();
              },
            ),
          ),
          const SizedBox(height: 16),
          const CreateShiftFieldLabel('Shift Type', required: true),
          CreateShiftDropdownField(
            value: _selectedShiftType.label,
            placeholder: 'Select shift type',
            onTap: () => _pickFromSheet<ShiftTypeOption>(
              title: 'Shift Type',
              options: ShiftTypeOption.predefined,
              labelOf: (o) => o.label,
              onSelected: (o) {
                setState(() {
                  _selectedShiftType = o;
                  _applyShiftTypeTimes(o);
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          const CreateShiftFieldLabel('Shift Date', required: true),
          CreateShiftDateField(
            value: _formatDate(_shiftDate),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          const CreateShiftFieldLabel('Start Time', required: true),
          CreateShiftTimeField(
            value: _formatTime(_startTime),
            onTap: () => _pickTime(start: true),
          ),
          const SizedBox(height: 16),
          const CreateShiftFieldLabel('End Time', required: true),
          CreateShiftTimeField(
            value: _formatTime(_endTime),
            onTap: () => _pickTime(start: false),
          ),
          const CreateShiftHelperText(
            'Earlier than the start means it runs overnight.',
          ),
          const SizedBox(height: 16),
          const CreateShiftFieldLabel('Break Duration', required: true),
          CreateShiftDropdownField(
            value: _selectedBreak.label,
            placeholder: 'Select break',
            onTap: () => _pickFromSheet<ShiftBreakDurationOption>(
              title: 'Break Duration',
              options: ShiftBreakDurationOption.predefined,
              labelOf: (o) => o.label,
              onSelected: (o) => setState(() => _selectedBreak = o),
            ),
          ),
          const SizedBox(height: 16),
          const CreateShiftFieldLabel('Title'),
          CreateShiftTextField(
            key: const Key('staff-create-shift-title'),
            controller: _titleController,
            hint: 'Optional — e.g. Weekend cover',
          ),
          const SizedBox(height: 16),
          const CreateShiftFieldLabel('Shift Notes'),
          CreateShiftTextField(
            key: const Key('staff-create-shift-notes'),
            controller: _notesController,
            hint:
                'Add any handover notes or special instructions for this shift...',
            maxLines: 4,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffAssignment() {
    final assigned = _assignments.values.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Staff Assignment',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Assign staff members to this shift and configure each person\'s tasks, or leave it open for bidding.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const CreateShiftFieldLabel('Assigned Staff'),
          _AssignedStaffField(
            assignments: assigned,
            onAdd: _showAddStaffPicker,
            onRemove: _removeAssignment,
          ),
          const SizedBox(height: 18),
          Text(
            'Assigned Staff (${assigned.length})',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 10),
          if (assigned.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.searchBorder),
              ),
              child: const Text(
                'No staff assigned yet. Add staff above, or leave open for bidding.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final draft in assigned) ...[
              _StaffTaskCard(
                draft: draft,
                checklistDraftController:
                    _checklistDraftControllers[draft.staff.id]!,
                onToggleExpand: () => setState(() {
                  draft.expanded = !draft.expanded;
                }),
                onRemove: () => _removeAssignment(draft.staff.id),
                onAddChecklist: () => _addChecklistItem(draft.staff.id),
                onRemoveChecklist: (index) => setState(() {
                  draft.checklist.removeAt(index);
                }),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _WizardStep {
  final String title;
  final String subtitle;
  final String keySuffix;
  final IconData icon;

  const _WizardStep({
    required this.title,
    required this.subtitle,
    required this.keySuffix,
    required this.icon,
  });
}

class _StaffAssignmentDraft {
  final StaffShiftStaffOption staff;
  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController taskDescriptionController =
      TextEditingController();
  final List<String> checklist = [];
  bool expanded = true;

  _StaffAssignmentDraft({required this.staff});

  void dispose() {
    taskTitleController.dispose();
    taskDescriptionController.dispose();
  }
}

class _StepSidebar extends StatelessWidget {
  final List<_WizardStep> steps;
  final int currentStep;
  final int completedSteps;
  final int percent;
  final ValueChanged<int> onTap;

  const _StepSidebar({
    required this.steps,
    required this.currentStep,
    required this.completedSteps,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          SizedBox(
            height: 78,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < steps.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Builder(
                      builder: (context) {
                        final step = steps[index];
                        final selected = index == currentStep;
                        return InkWell(
                          key: Key('staff-create-shift-step-${step.keySuffix}'),
                          onTap: () => onTap(index),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 148,
                            height: 78,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEEF4FF)
                                  : AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primaryNavy
                                    : AppColors.searchBorder,
                                width: selected ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primaryNavy
                                        : AppColors.filterButtonBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    step.icon,
                                    size: 16,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        step.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.5,
                                          color: selected
                                              ? AppColors.primaryNavy
                                              : AppColors.textHeading,
                                        ),
                                      ),
                                      Text(
                                        step.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPLETION',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.6,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'STEP $completedSteps OF ${steps.length}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: completedSteps / steps.length,
                    minHeight: 6,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.secondaryTeal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$percent% complete',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedStaffField extends StatelessWidget {
  final List<_StaffAssignmentDraft> assignments;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _AssignedStaffField({
    required this.assignments,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final draft in assignments)
            InputChip(
              label: Text(draft.staff.name),
              onDeleted: () => onRemove(draft.staff.id),
              deleteIconColor: AppColors.textMuted,
              backgroundColor: const Color(0xFFF4F6F8),
            ),
          TextButton.icon(
            key: const Key('staff-create-shift-add-staff'),
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: const Text('Add staff...'),
          ),
        ],
      ),
    );
  }
}

class _StaffTaskCard extends StatelessWidget {
  final _StaffAssignmentDraft draft;
  final TextEditingController checklistDraftController;
  final VoidCallback onToggleExpand;
  final VoidCallback onRemove;
  final VoidCallback onAddChecklist;
  final ValueChanged<int> onRemoveChecklist;

  const _StaffTaskCard({
    required this.draft,
    required this.checklistDraftController,
    required this.onToggleExpand,
    required this.onRemove,
    required this.onAddChecklist,
    required this.onRemoveChecklist,
  });

  @override
  Widget build(BuildContext context) {
    final category = draft.staff.detail.isEmpty
        ? 'No category recorded'
        : draft.staff.detail;

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.searchBorder),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE8E4F5),
                child: Text(
                  draft.staff.initials,
                  style: const TextStyle(
                    color: Color(0xFF5B4B8A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                draft.staff.name,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                category,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.textMuted,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onToggleExpand,
                    icon: Icon(
                      draft.expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              onTap: onToggleExpand,
            ),
            if (draft.expanded) ...[
              const Divider(height: 1, color: AppColors.cardBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CreateShiftFieldLabel('Task Title'),
                    CreateShiftTextField(
                      controller: draft.taskTitleController,
                      hint: 'e.g. Morning medication round',
                    ),
                    const CreateShiftHelperText(
                      'Leave empty to assign the shift without a task.',
                    ),
                    const SizedBox(height: 12),
                    const CreateShiftFieldLabel('Task Description'),
                    CreateShiftTextField(
                      controller: draft.taskDescriptionController,
                      hint:
                          'Describe what this staff member is responsible for during this shift...',
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 12),
                    const CreateShiftFieldLabel('Task Checklist'),
                    CreateShiftTextField(
                      controller: checklistDraftController,
                      hint: 'Add a checklist item...',
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onAddChecklist,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add checklist item'),
                    ),
                    for (var i = 0; i < draft.checklist.length; i++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.check_box_outline_blank_rounded,
                          size: 18,
                        ),
                        title: Text(draft.checklist[i]),
                        trailing: IconButton(
                          onPressed: () => onRemoveChecklist(i),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onCreate;

  const _Footer({
    required this.isFirst,
    required this.isLast,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: AppColors.criticalRed),
                    ),
                    TextSpan(text: ' Required fields'),
                  ],
                ),
              ),
            ),
            OutlinedButton(
              onPressed: isSubmitting
                  ? null
                  : (isFirst ? () => Get.back() : onBack),
              child: Text(isFirst ? 'Cancel' : 'Back'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              key: isLast ? const Key('staff-create-shift-submit') : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
              ),
              onPressed: isSubmitting ? null : (isLast ? onCreate : onNext),
              child: Text(
                isSubmitting
                    ? 'Saving…'
                    : (isLast ? 'Create shift' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
