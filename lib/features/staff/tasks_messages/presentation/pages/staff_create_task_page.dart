import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/task_creation_options.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';

/// Single-scroll New Task form matching web create-task modal (BUG_Report009).
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

class _ChecklistStep {
  final String id;
  String label;
  bool required;

  _ChecklistStep({
    required this.id,
    required this.label,
    this.required = false,
  });
}

class _StaffCreateTaskPageState extends State<StaffCreateTaskPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _checklistController = TextEditingController();
  final _staffSearchController = TextEditingController();
  final _residentSearchController = TextEditingController();

  late String _residenceId;
  String? _shiftId;
  String? _roomArea;
  String? _clientId;
  late final Set<String> _assignedStaffIds;
  DateTime? _dueAt;
  TimeOfDay? _dueTime;
  bool _requiresReview = false;
  bool _isRecurring = false;
  bool _isSubmitting = false;
  bool _loadingLookups = false;

  List<TaskCreationOption> _shifts = const [];
  List<TaskCreationOption> _rooms = const [];
  List<TaskCreationOption> _clients = const [];
  List<_ChecklistStep> _checklist = [];
  final List<String> _docNames = [];

  @override
  void initState() {
    super.initState();
    final options = widget.options;
    _residenceId =
        options.defaultResidenceId ??
        (options.residences.isNotEmpty ? options.residences.first.id : '');
    _shifts = options.shifts;
    _assignedStaffIds = {};
    if (_residenceId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onResidenceChanged(_residenceId));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _checklistController.dispose();
    _staffSearchController.dispose();
    _residentSearchController.dispose();
    super.dispose();
  }

  Future<void> _onResidenceChanged(String residenceId) async {
    setState(() {
      _residenceId = residenceId;
      _shiftId = null;
      _roomArea = null;
      _clientId = null;
      _loadingLookups = true;
    });
    final results = await Future.wait([
      widget.repository.getTaskShifts(residenceId),
      widget.repository.getTaskRooms(residenceId),
      widget.repository.getTaskClients(residenceId),
    ]);
    if (!mounted) return;
    setState(() {
      _shifts = results[0].value ?? const [];
      _rooms = results[1].value ?? const [];
      _clients = results[2].value ?? const [];
      if (_shifts.isNotEmpty) _shiftId = _shifts.first.id;
      _loadingLookups = false;
    });
  }

  Future<void> _pickDue() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (!mounted) return;
    setState(() {
      _dueAt = date;
      _dueTime = time;
    });
  }

  void _addChecklistStep() {
    final label = _checklistController.text.trim();
    if (label.isEmpty) return;
    setState(() {
      _checklist.add(
        _ChecklistStep(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          label: label,
        ),
      );
      _checklistController.clear();
    });
  }

  Future<void> _pickDocs() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      for (final file in result.files) {
        final name = file.name.trim();
        if (name.isNotEmpty && !_docNames.contains(name)) {
          _docNames.add(name);
        }
      }
    });
  }

  DateTime? get _combinedDueAt {
    final date = _dueAt;
    if (date == null) return null;
    final time = _dueTime;
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String get _dueLabel {
    if (_dueAt == null) return 'dd/mm/yyyy, --:--';
    final d =
        '${_dueAt!.day.toString().padLeft(2, '0')}/'
        '${_dueAt!.month.toString().padLeft(2, '0')}/'
        '${_dueAt!.year}';
    if (_dueTime == null) return '$d, --:--';
    final t =
        '${_dueTime!.hour.toString().padLeft(2, '0')}:'
        '${_dueTime!.minute.toString().padLeft(2, '0')}';
    return '$d, $t';
  }

  List<TaskCreationOption> get _filteredStaff {
    final q = _staffSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.options.staff;
    return widget.options.staff
        .where((item) => item.label.toLowerCase().contains(q))
        .toList();
  }

  List<TaskCreationOption> get _filteredClients {
    final q = _residentSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return _clients;
    return _clients
        .where((item) => item.label.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_residenceId.isEmpty) {
      AppSnackbar.show('Residence required', 'Select a residence.');
      return;
    }
    if (!_isRecurring && (_shiftId == null || _shiftId!.isEmpty)) {
      AppSnackbar.show('Shift required', 'Pick a residence first, then a shift.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      AppSnackbar.show('Title required', 'Enter a task title.');
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await widget.repository.createTask(
      title: _titleController.text,
      description: _descriptionController.text,
      dueAt: _combinedDueAt,
      shiftId: _shiftId,
      residenceId: _residenceId,
      assignedStaffIds: _assignedStaffIds.toList(),
      clientId: _clientId,
      roomArea: _roomArea,
      checklist: [
        for (final step in _checklist)
          {'label': step.label, 'required': step.required},
      ],
      requiresReview: _requiresReview,
      notes: _notesController.text,
      isRecurring: _isRecurring,
      recurrenceFrequency: 'daily',
      recurrenceTimesOfDay: const [9 * 60],
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
          Expanded(
            child: SingleChildScrollView(
              key: const Key('staff-create-task-form'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderBanner(),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('staff-create-task-residence'),
                    initialValue: _residenceId.isEmpty ? null : _residenceId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Residence *',
                      hintText: 'Select Residence',
                    ),
                    items: [
                      for (final item in widget.options.residences)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) _onResidenceChanged(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: Key('staff-create-task-room-$_residenceId'),
                    initialValue: _roomArea,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Room / Area',
                      hintText: _residenceId.isEmpty
                          ? 'Pick a residence first'
                          : 'Select room or area',
                    ),
                    items: [
                      ...{
                        for (final item in _rooms) item.label,
                        'Kitchen',
                        'Lounge',
                        'Garden',
                        'Office',
                      }.map(
                        (label) => DropdownMenuItem(
                          value: label,
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _residenceId.isEmpty
                        ? null
                        : (value) => setState(() => _roomArea = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: Key('staff-create-task-shift-$_residenceId'),
                    initialValue: _shiftId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Shift *',
                      hintText: _residenceId.isEmpty
                          ? 'Pick a residence first'
                          : (_loadingLookups
                                ? 'Loading shifts…'
                                : 'Select shift'),
                    ),
                    items: [
                      for (final item in _shifts)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            item.subtitle.isEmpty
                                ? item.label
                                : '${item.label} · ${item.subtitle}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _residenceId.isEmpty
                        ? null
                        : (value) => setState(() => _shiftId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('staff-create-task-resident-search'),
                    controller: _residentSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Resident',
                      hintText: 'Search resident (optional)...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Only when the work is about one person',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (_filteredClients.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final client in _filteredClients.take(8))
                          ChoiceChip(
                            key: Key('staff-create-task-client-${client.id}'),
                            label: Text(client.label),
                            selected: _clientId == client.id,
                            onSelected: (selected) {
                              setState(() {
                                _clientId = selected ? client.id : null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('staff-create-task-staff-search'),
                    controller: _staffSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Add Staff',
                      hintText: 'Add Staff',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A task can wait unassigned, but somebody has to pick it up',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final staff in _filteredStaff)
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
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('staff-create-task-title'),
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title *',
                      hintText: 'e.g. Fridge Temperature Check',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('staff-create-task-description'),
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe what needs to be done...',
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('staff-create-task-due'),
                    onPressed: _pickDue,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(_dueLabel),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Checklist',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('staff-create-task-checklist-input'),
                          controller: _checklistController,
                          decoration: const InputDecoration(
                            hintText:
                                "Add a step — 'Check the fridge temperature'",
                          ),
                          onSubmitted: (_) => _addChecklistStep(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('staff-create-task-checklist-add'),
                        onPressed: _addChecklistStep,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Tick 'must be done' for a step the task cannot be closed without",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (_checklist.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final step in _checklist)
                      CheckboxListTile(
                        key: Key('staff-create-task-checklist-${step.id}'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: step.required,
                        title: Text(step.label),
                        secondary: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _checklist.remove(step)),
                        ),
                        onChanged: (value) {
                          setState(() => step.required = value ?? false);
                        },
                      ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    key: const Key('staff-create-task-needs-review'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Needs a review',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Somebody with review rights has to agree it was done before it counts',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    value: _requiresReview,
                    activeThumbColor: AppColors.secondaryTeal,
                    onChanged: (value) => setState(() => _requiresReview = value),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('staff-create-task-notes'),
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add a note or reminder for this task...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Saved against the task, with your name and the time',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Docs (Optional)',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    key: const Key('staff-create-task-docs'),
                    onTap: _pickDocs,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          style: BorderStyle.solid,
                          width: 1.2,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Click to upload or drag & drop',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'PDF, JPG, PNG · Max 15MB',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_docNames.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final name in _docNames)
                          Chip(
                            label: Text(name),
                            onDeleted: () =>
                                setState(() => _docNames.remove(name)),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    key: const Key('staff-create-task-recurring'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Recurring Task',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Repeat this task on a schedule and share it between staff',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    value: _isRecurring,
                    activeThumbColor: AppColors.secondaryTeal,
                    onChanged: (value) => setState(() => _isRecurring = value),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : Get.back,
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('staff-create-task-submit'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(
                      _isSubmitting ? 'Creating…' : 'Create Task',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondaryTeal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Task',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Create and assign task, add checklist, notes, and attachments.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
