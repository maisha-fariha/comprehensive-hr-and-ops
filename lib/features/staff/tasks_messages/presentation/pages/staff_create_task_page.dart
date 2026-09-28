import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/task_creation_options.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';

/// Multi-step New Task wizard matching web create-task fields (BUG_Report009).
class StaffCreateTaskPage extends StatefulWidget {
  final StaffTasksMessagesRepository repository;
  final TaskCreationOptions options;

  const StaffCreateTaskPage({
    super.key,
    required this.repository,
    required this.options,
  });

  @override
  State<StaffCreateTaskPage> createState() => _StaffCreateTaskPageState();
}

class _StaffCreateTaskPageState extends State<StaffCreateTaskPage> {
  static const _steps = [
    _WizardStep('Details', 'details'),
    _WizardStep('Assignment', 'assignment'),
    _WizardStep('Schedule & Review', 'review'),
  ];

  static const _taskTypes = [
    ('administrative', 'Administrative'),
    ('maintenance', 'Maintenance'),
    ('inventory', 'Inventory'),
    ('compliance', 'Compliance'),
    ('follow_up', 'Follow-up'),
    ('other', 'Other'),
  ];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _priority;
  late String _taskType;
  late String _shiftId;
  late String _residenceId;
  late final Set<String> _assignedStaffIds;
  DateTime? _dueAt;
  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final options = widget.options;
    _priority = 'medium';
    _taskType = 'administrative';
    _shiftId = options.shifts.isNotEmpty ? options.shifts.first.id : '';
    _residenceId =
        options.defaultResidenceId ??
        (options.residences.isNotEmpty ? options.residences.first.id : '');
    _assignedStaffIds = {
      if (options.defaultStaffId != null && options.defaultStaffId!.isNotEmpty)
        options.defaultStaffId!,
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TaskCreationOption? _findOption(List<TaskCreationOption> items, String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _dueAt = picked);
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_titleController.text.trim().isEmpty) {
        AppSnackbar.show('Title required', 'Enter a task title to continue.');
        return false;
      }
      return true;
    }
    if (_currentStep == 1) {
      if (_residenceId.isEmpty) {
        AppSnackbar.show('Residence required', 'Select a residence.');
        return false;
      }
      if (_shiftId.isEmpty) {
        AppSnackbar.show('Shift required', 'Select a shift for this task.');
        return false;
      }
      if (_assignedStaffIds.isEmpty) {
        AppSnackbar.show('Assignee required', 'Add at least one staff member.');
        return false;
      }
      return true;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_validateCurrentStep()) return;
    if (_titleController.text.trim().isEmpty ||
        _residenceId.isEmpty ||
        _shiftId.isEmpty ||
        _assignedStaffIds.isEmpty) {
      setState(() => _currentStep = 0);
      _validateCurrentStep();
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await widget.repository.createTask(
      title: _titleController.text,
      description: _descriptionController.text,
      priority: _priority,
      dueAt: _dueAt,
      taskType: _taskType,
      shiftId: _shiftId,
      residenceId: _residenceId,
      assignedStaffIds: _assignedStaffIds.toList(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not create task',
      );
      return;
    }

    AppSnackbar.show('Task created', _titleController.text.trim());
    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    return Scaffold(
      key: const Key('staff-create-task-page'),
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('New Task'),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
      ),
      body: Column(
        children: [
          _StepHeader(
            steps: _steps,
            currentStep: _currentStep,
            onStepTap: (index) {
              if (index <= _currentStep) {
                setState(() => _currentStep = index);
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: KeyedSubtree(
                key: Key('staff-create-task-step-${step.key}'),
                child: switch (_currentStep) {
                  0 => _buildDetailsStep(),
                  1 => _buildAssignmentStep(),
                  _ => _buildReviewStep(),
                },
              ),
            ),
          ),
          _Footer(
            isFirst: _currentStep == 0,
            isLast: _currentStep == _steps.length - 1,
            isSubmitting: _isSubmitting,
            onBack: () => setState(() => _currentStep -= 1),
            onNext: () {
              if (!_validateCurrentStep()) return;
              setState(() => _currentStep += 1);
            },
            onCreate: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('staff-create-task-title'),
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'What needs to be done?',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('staff-create-task-description'),
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('staff-create-task-type'),
          initialValue: _taskType,
          decoration: const InputDecoration(labelText: 'Task type'),
          items: [
            for (final entry in _taskTypes)
              DropdownMenuItem(value: entry.$1, child: Text(entry.$2)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _taskType = value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('staff-create-task-priority'),
          initialValue: _priority,
          decoration: const InputDecoration(labelText: 'Priority'),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(value: 'high', child: Text('High')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _priority = value);
          },
        ),
      ],
    );
  }

  Widget _buildAssignmentStep() {
    final options = widget.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('staff-create-task-residence'),
          initialValue: _residenceId.isEmpty ? null : _residenceId,
          decoration: const InputDecoration(labelText: 'Residence'),
          items: [
            for (final item in options.residences)
              DropdownMenuItem(value: item.id, child: Text(item.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _residenceId = value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('staff-create-task-shift'),
          initialValue: _shiftId.isEmpty ? null : _shiftId,
          decoration: const InputDecoration(labelText: 'Shift'),
          items: [
            for (final item in options.shifts)
              DropdownMenuItem(
                value: item.id,
                child: Text(
                  item.subtitle.isEmpty
                      ? item.label
                      : '${item.label} · ${item.subtitle}',
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _shiftId = value);
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Assignees',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final staff in options.staff)
              FilterChip(
                key: Key('staff-create-task-assignee-${staff.id}'),
                label: Text(staff.label),
                selected: _assignedStaffIds.contains(staff.id),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _assignedStaffIds.add(staff.id);
                    } else {
                      _assignedStaffIds.remove(staff.id);
                    }
                  });
                },
              ),
          ],
        ),
        if (options.staff.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No staff available for this residence.',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final options = widget.options;
    final residence = _findOption(options.residences, _residenceId);
    final shift = _findOption(options.shifts, _shiftId);
    final assignees = options.staff
        .where((s) => _assignedStaffIds.contains(s.id))
        .map((s) => s.label)
        .join(', ');
    final typeLabel = _taskTypes
        .firstWhere(
          (e) => e.$1 == _taskType,
          orElse: () => (_taskType, _taskType),
        )
        .$2;
    final dueLabel = _dueAt == null
        ? 'No due date'
        : '${_dueAt!.year}-${_dueAt!.month.toString().padLeft(2, '0')}-${_dueAt!.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: const Key('staff-create-task-due'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Due date'),
          subtitle: Text(dueLabel),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: _pickDueDate,
        ),
        const SizedBox(height: 8),
        _ReviewRow(
          label: 'Title',
          value: _titleController.text.trim().isEmpty
              ? '—'
              : _titleController.text.trim(),
          onEdit: () => setState(() => _currentStep = 0),
        ),
        _ReviewRow(
          label: 'Type / Priority',
          value: '$typeLabel · ${_priority[0].toUpperCase()}${_priority.substring(1)}',
          onEdit: () => setState(() => _currentStep = 0),
        ),
        _ReviewRow(
          label: 'Residence',
          value: residence?.label ?? '—',
          onEdit: () => setState(() => _currentStep = 1),
        ),
        _ReviewRow(
          label: 'Shift',
          value: shift?.label ?? '—',
          onEdit: () => setState(() => _currentStep = 1),
        ),
        _ReviewRow(
          label: 'Assignees',
          value: assignees.isEmpty ? '—' : assignees,
          onEdit: () => setState(() => _currentStep = 1),
        ),
        if (_descriptionController.text.trim().isNotEmpty)
          _ReviewRow(
            label: 'Description',
            value: _descriptionController.text.trim(),
            onEdit: () => setState(() => _currentStep = 0),
          ),
      ],
    );
  }
}

class _WizardStep {
  final String label;
  final String key;
  const _WizardStep(this.label, this.key);
}

class _StepHeader extends StatelessWidget {
  final List<_WizardStep> steps;
  final int currentStep;
  final ValueChanged<int> onStepTap;

  const _StepHeader({
    required this.steps,
    required this.currentStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: () => onStepTap(i),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: i <= currentStep
                          ? AppColors.secondaryTeal
                          : AppColors.searchBorder,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: i <= currentStep
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: i == currentStep
                            ? AppColors.textHeading
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < steps.length - 1)
              const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ],
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            if (!isFirst)
              TextButton(
                onPressed: isSubmitting ? null : onBack,
                child: const Text('Back'),
              ),
            const Spacer(),
            if (!isLast)
              FilledButton(
                onPressed: isSubmitting ? null : onNext,
                child: const Text('Next'),
              )
            else
              FilledButton(
                key: const Key('staff-create-task-submit'),
                onPressed: isSubmitting ? null : onCreate,
                child: Text(isSubmitting ? 'Creating…' : 'Create'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _ReviewRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}
