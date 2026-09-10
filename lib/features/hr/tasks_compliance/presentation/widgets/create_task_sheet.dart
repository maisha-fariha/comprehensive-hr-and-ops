import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../incidents/presentation/widgets/wizard_form_fields.dart';
import '../../domain/entities/create_task_request.dart';
import '../../domain/entities/task_client_option.dart';
import '../../domain/entities/task_staff_option.dart';
import '../../domain/entities/task_residence_option.dart';
import '../../domain/repositories/tasks_compliance_repository.dart';

/// Opens the "New Task" create form matched to the Tasks & Compliance
/// reference screens.
Future<void> showCreateTaskSheet(
  BuildContext context, {
  VoidCallback? onCreated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateTaskSheet(onCreated: onCreated),
  );
}

class _ChecklistDraft {
  _ChecklistDraft({required this.label});

  final String label;
  bool mustBeDone = false;
}

class _CreateTaskSheet extends StatefulWidget {
  final VoidCallback? onCreated;

  const _CreateTaskSheet({this.onCreated});

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  static const _roomOptions = [
    '101',
    '102',
    '103',
    '201',
    '202',
    '203',
  ];
  static const _taskTypes = [
    'Care',
    'Administrative',
    'Maintenance',
    'Inventory',
    'Compliance',
    'Follow-up',
    'Other',
  ];
  static const _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  late final TasksComplianceRepository _repository;
  List<TaskResidenceOption> _residences = const [];
  bool _loadingResidences = true;
  bool _submitting = false;

  final _residentController = TextEditingController();
  final _staffController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _checklistController = TextEditingController();
  final _notesController = TextEditingController();
  final _dueController = TextEditingController();

  TaskResidenceOption? _residence;
  String? _roomArea;
  String _taskType = 'Care';
  String _priority = 'Medium';
  DateTime? _dueAt;
  bool _requiresReview = false;
  bool _recurring = false;
  final List<_ChecklistDraft> _checklist = [];
  final List<String> _docNames = [];

  Timer? _residentSearchDebounce;
  int _residentSearchRequestId = 0;
  bool _searchingResidents = false;
  bool _showResidentSuggestions = false;
  String _residentSearchError = '';
  List<TaskClientOption> _residentSuggestions = const [];
  TaskClientOption? _selectedResident;

  Timer? _staffSearchDebounce;
  int _staffSearchRequestId = 0;
  bool _searchingStaff = false;
  bool _showStaffSuggestions = false;
  String _staffSearchError = '';
  List<TaskStaffOption> _staffSuggestions = const [];
  final List<TaskStaffOption> _selectedStaff = [];

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<TasksComplianceRepository>();
    _loadResidences();
  }

  Future<void> _loadResidences() async {
    setState(() => _loadingResidences = true);
    final result = await _repository.getResidences();
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          _residences = items;
          _loadingResidences = false;
          if (_residence == null && items.isNotEmpty) {
            _residence = items.first;
          }
        });
      },
      failure: (error) {
        setState(() => _loadingResidences = false);
        AppSnackbar.show('Could not load residences', error.message);
      },
    );
  }

  @override
  void dispose() {
    _residentSearchDebounce?.cancel();
    _staffSearchDebounce?.cancel();
    _residentController.dispose();
    _staffController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _checklistController.dispose();
    _notesController.dispose();
    _dueController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveHelper.getResponsiveRadius(context, 18)),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  ctx,
                  horizontal: 16,
                  top: 16,
                  bottom: 8,
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(ctx, 15),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(
                    option,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.of(ctx).pop(option),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) onSelected(selected);
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dueController.text = _formatDue(_dueAt!);
    });
  }

  String _formatDue(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour24 = value.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year}, ${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  void _onResidentQueryChanged(String value) {
    final selected = _selectedResident;
    if (selected != null && value.trim() != selected.name) {
      _selectedResident = null;
    }

    _residentSearchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _residentSearchRequestId++;
      setState(() {
        _searchingResidents = false;
        _residentSuggestions = const [];
        _showResidentSuggestions = false;
        _residentSearchError = '';
      });
      return;
    }

    setState(() => _showResidentSuggestions = true);
    _residentSearchDebounce = Timer(
      const Duration(milliseconds: 320),
      () => _searchResidents(trimmed),
    );
  }

  Future<void> _searchResidents(String trimmed) async {
    final requestId = ++_residentSearchRequestId;
    setState(() {
      _searchingResidents = true;
      _residentSearchError = '';
    });

    final result = await _repository.searchClients(
      search: trimmed,
      residenceId: _residence?.id,
    );
    if (!mounted || requestId != _residentSearchRequestId) return;

    result.when(
      success: (options) {
        setState(() {
          _searchingResidents = false;
          _residentSuggestions = options;
          _showResidentSuggestions = true;
        });
      },
      failure: (error) {
        setState(() {
          _searchingResidents = false;
          _residentSuggestions = const [];
          _residentSearchError = error.message;
          _showResidentSuggestions = true;
        });
      },
    );
  }

  void _selectResident(TaskClientOption option) {
    _residentSearchDebounce?.cancel();
    _residentSearchRequestId++;
    setState(() {
      _selectedResident = option;
      _residentController.text = option.name;
      _residentSuggestions = const [];
      _showResidentSuggestions = false;
      _residentSearchError = '';
      _searchingResidents = false;
      if (option.residenceId != null && option.residenceId!.isNotEmpty) {
        final match = _residences.where((item) => item.id == option.residenceId);
        if (match.isNotEmpty) {
          _residence = match.first;
        }
      }
    });
  }

  void _onStaffQueryChanged(String value) {
    _staffSearchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _staffSearchRequestId++;
      setState(() {
        _searchingStaff = false;
        _staffSuggestions = const [];
        _showStaffSuggestions = false;
        _staffSearchError = '';
      });
      return;
    }

    setState(() => _showStaffSuggestions = true);
    _staffSearchDebounce = Timer(
      const Duration(milliseconds: 320),
      () => _searchStaff(trimmed),
    );
  }

  Future<void> _searchStaff(String trimmed) async {
    final requestId = ++_staffSearchRequestId;
    setState(() {
      _searchingStaff = true;
      _staffSearchError = '';
    });

    final result = await _repository.searchStaff(
      search: trimmed,
      residenceId: _residence?.id,
    );
    if (!mounted || requestId != _staffSearchRequestId) return;

    result.when(
      success: (options) {
        final selectedIds = _selectedStaff.map((item) => item.id).toSet();
        setState(() {
          _searchingStaff = false;
          _staffSuggestions =
              options.where((item) => !selectedIds.contains(item.id)).toList();
          _showStaffSuggestions = true;
        });
      },
      failure: (error) {
        setState(() {
          _searchingStaff = false;
          _staffSuggestions = const [];
          _staffSearchError = error.message;
          _showStaffSuggestions = true;
        });
      },
    );
  }

  void _dismissStaffSuggestions() {
    if (!_showStaffSuggestions && !_searchingStaff) return;
    _staffSearchDebounce?.cancel();
    _staffSearchRequestId++;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _showStaffSuggestions = false;
      _staffSuggestions = const [];
      _searchingStaff = false;
      _staffSearchError = '';
    });
  }

  void _addStaff(TaskStaffOption option) {
    _staffSearchDebounce?.cancel();
    setState(() {
      if (_selectedStaff.every((item) => item.id != option.id)) {
        _selectedStaff.add(option);
      }
      _staffSuggestions =
          _staffSuggestions.where((item) => item.id != option.id).toList();
      _showStaffSuggestions = _staffSuggestions.isNotEmpty ||
          _searchingStaff ||
          _staffSearchError.isNotEmpty;
      _staffController.clear();
    });
  }

  void _removeStaff(String id) {
    setState(() {
      _selectedStaff.removeWhere((item) => item.id == id);
    });
    final query = _staffController.text.trim();
    if (query.isNotEmpty) {
      _searchStaff(query);
    }
  }

  void _addChecklistStep() {
    final label = _checklistController.text.trim();
    if (label.isEmpty) return;
    setState(() {
      _checklist.add(_ChecklistDraft(label: label));
      _checklistController.clear();
    });
  }

  Future<void> _onCreate() async {
    if (_submitting) return;
    if (_residence == null) {
      AppSnackbar.show('Residence required', 'Select a residence to continue.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      AppSnackbar.show('Task title required', 'Enter a task title to continue.');
      return;
    }

    setState(() => _submitting = true);
    final result = await _repository.createTask(
      CreateTaskRequest(
        residenceId: _residence!.id,
        title: _titleController.text.trim(),
        roomArea: _roomArea,
        clientId: _selectedResident?.id,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        taskType: _taskType,
        priority: _priority,
        dueAt: _dueAt,
        requiresReview: _requiresReview,
        recurring: _recurring,
        assignedStaffIds: [
          for (final staff in _selectedStaff) staff.id,
        ],
        checklist: [
          for (final step in _checklist)
            CreateTaskChecklistItem(
              label: step.label,
              required: step.mustBeDone,
            ),
        ],
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (_) {
        _close();
        widget.onCreated?.call();
        AppSnackbar.show(
          'Task created',
          _recurring
              ? 'Recurring task “${_titleController.text.trim()}” was created.'
              : '“${_titleController.text.trim()}” was created.',
        );
      },
      failure: (error) {
        AppSnackbar.show('Could not create task', error.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.94;
    final roomEnabled = _residence != null;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveHelper.getResponsiveRadius(context, 20)),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  top: 14,
                  bottom: 20,
                ),
                children: [
                  _Header(onClose: _close),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                  if (_loadingResidences)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    )
                  else
                    _ResidenceCard(
                      residence: _residence?.name,
                      roomArea: _roomArea,
                      roomEnabled: roomEnabled,
                      residentController: _residentController,
                      showResidentSuggestions: _showResidentSuggestions,
                      searchingResidents: _searchingResidents,
                      residentSearchError: _residentSearchError,
                      residentSuggestions: _residentSuggestions,
                      selectedResidentId: _selectedResident?.id,
                      onResidentQueryChanged: _onResidentQueryChanged,
                      onResidentSelected: _selectResident,
                      onPickResidence: () => _pickOption(
                        title: 'Select Residence',
                        options: _residences.map((item) => item.name).toList(),
                        onSelected: (value) => setState(() {
                          final match =
                              _residences.where((item) => item.name == value);
                          _residence = match.isEmpty ? null : match.first;
                          _roomArea = null;
                          _selectedResident = null;
                          _residentController.clear();
                          _residentSuggestions = const [];
                          _showResidentSuggestions = false;
                        }),
                      ),
                      onPickRoom: !roomEnabled
                          ? null
                          : () => _pickOption(
                                title: 'Room / Area',
                                options: _roomOptions,
                                onSelected: (value) =>
                                    setState(() => _roomArea = value),
                              ),
                    ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                  const WizardFieldLabel('Assigned Staff'),
                  TapRegion(
                    groupId: 'create_task_staff_search',
                    onTapOutside: (_) => _dismissStaffSuggestions(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AssignedStaffSearchField(
                          controller: _staffController,
                          selected: _selectedStaff,
                          hint: 'Add staff',
                          onChanged: _onStaffQueryChanged,
                          onRemove: _removeStaff,
                        ),
                        if (_showStaffSuggestions) ...[
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              8,
                            ),
                          ),
                          _StaffSuggestionsPanel(
                            searching: _searchingStaff,
                            error: _staffSearchError,
                            suggestions: _staffSuggestions,
                            onSelected: _addStaff,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                  const _Hint(
                    'Select one staff member or several — or leave unassigned',
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                  const WizardFieldLabel('Task Title', required: true),
                  WizardTextField(
                    controller: _titleController,
                    hint: 'e.g. Fridge Temperature Check',
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                  const WizardFieldLabel('Description'),
                  WizardTextField(
                    controller: _descriptionController,
                    hint: 'Describe what needs to be done...',
                    maxLines: 4,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                  const WizardFieldLabel('Task Type', required: true),
                  WizardDropdownField(
                    value: _taskType,
                    placeholder: 'Select type',
                    onTap: () => _pickOption(
                      title: 'Task Type',
                      options: _taskTypes,
                      onSelected: (value) => setState(() => _taskType = value),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                  const WizardFieldLabel('Priority', required: true),
                  WizardDropdownField(
                    value: _priority,
                    placeholder: 'Select priority',
                    onTap: () => _pickOption(
                      title: 'Priority',
                      options: _priorities,
                      onSelected: (value) => setState(() => _priority = value),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                  const WizardFieldLabel('Due'),
                  WizardDateField(
                    controller: _dueController,
                    hint: 'dd/mm/yyyy, --:-- --',
                    onTap: _pickDue,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                  const WizardFieldLabel('Checklist'),
                  _ChecklistComposer(
                    controller: _checklistController,
                    onAdd: _addChecklistStep,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                  const _Hint(
                    'Tick “must be done” for a step the task cannot be closed without',
                  ),
                  if (_checklist.isNotEmpty) ...[
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                    for (var i = 0; i < _checklist.length; i++) ...[
                      if (i > 0)
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveHeight(context, 8),
                        ),
                      _ChecklistItemRow(
                        item: _checklist[i],
                        onMustBeDoneChanged: (value) =>
                            setState(() => _checklist[i].mustBeDone = value),
                        onRemove: () => setState(() => _checklist.removeAt(i)),
                      ),
                    ],
                  ],
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                  _ToggleBlock(
                    title: 'Needs a review',
                    subtitle:
                        'Somebody with review rights has to agree it was done before it counts',
                    value: _requiresReview,
                    onChanged: (value) => setState(() => _requiresReview = value),
                    bordered: false,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                  const WizardFieldLabel('Notes'),
                  WizardTextField(
                    controller: _notesController,
                    hint: 'Add a note or reminder for this task...',
                    maxLines: 3,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                  const _Hint('Saved against the task, with your name and the time'),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                  const WizardFieldLabel('Docs (Optional)'),
                  _DocsDropzone(
                    files: _docNames,
                    onTap: () {
                      // UI placeholder until file picker is wired.
                      setState(() {
                        _docNames.add('attachment_${_docNames.length + 1}.pdf');
                      });
                    },
                    onRemove: (index) => setState(() => _docNames.removeAt(index)),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                  _ToggleBlock(
                    title: 'Recurring Task',
                    subtitle:
                        'Repeat this task on a schedule and share it between staff',
                    value: _recurring,
                    onChanged: (value) => setState(() => _recurring = value),
                    bordered: true,
                  ),
                ],
              ),
            ),
            _Footer(onCancel: _close, onCreate: _onCreate),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 44);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.secondaryTeal,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
          ),
          alignment: Alignment.center,
          child: const AppSvgIcon(
            AppAssets.clipboardCheck,
            size: 22,
            color: Colors.white,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Task',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  color: AppColors.textHeading,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
              Text(
                'Create and assign task, add checklist, notes, and attachments.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: ResponsiveHelper.getResponsiveSize(context, 34),
            height: ResponsiveHelper.getResponsiveSize(context, 34),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.searchBorder),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.close_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResidenceCard extends StatelessWidget {
  final String? residence;
  final String? roomArea;
  final bool roomEnabled;
  final TextEditingController residentController;
  final bool showResidentSuggestions;
  final bool searchingResidents;
  final String residentSearchError;
  final List<TaskClientOption> residentSuggestions;
  final String? selectedResidentId;
  final ValueChanged<String> onResidentQueryChanged;
  final ValueChanged<TaskClientOption> onResidentSelected;
  final VoidCallback onPickResidence;
  final VoidCallback? onPickRoom;

  const _ResidenceCard({
    required this.residence,
    required this.roomArea,
    required this.roomEnabled,
    required this.residentController,
    required this.showResidentSuggestions,
    required this.searchingResidents,
    required this.residentSearchError,
    required this.residentSuggestions,
    required this.selectedResidentId,
    required this.onResidentQueryChanged,
    required this.onResidentSelected,
    required this.onPickResidence,
    required this.onPickRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Residence Information',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          const WizardFieldLabel('Select Residence', required: true),
          WizardDropdownField(
            value: residence,
            placeholder: 'Select Residence',
            onTap: onPickResidence,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Text(
            'Room / Area',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 7)),
          Opacity(
            opacity: roomEnabled ? 1 : 0.72,
            child: WizardDropdownField(
              value: roomArea,
              placeholder: roomEnabled ? 'Select Room / Area' : 'Pick a residence first',
              onTap: onPickRoom,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          const WizardFieldLabel('Resident (Optional)'),
          WizardSearchField(
            controller: residentController,
            hint: 'Search resident (optional)...',
            onChanged: onResidentQueryChanged,
          ),
          if (showResidentSuggestions) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            _ResidentSuggestionsPanel(
              searching: searchingResidents,
              error: residentSearchError,
              suggestions: residentSuggestions,
              selectedId: selectedResidentId,
              onSelected: onResidentSelected,
            ),
          ],
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          const _Hint('Only when the work is about one person'),
        ],
      ),
    );
  }
}



class _AssignedStaffSearchField extends StatelessWidget {
  final TextEditingController controller;
  final List<TaskStaffOption> selected;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onRemove;

  const _AssignedStaffSearchField({
    required this.controller,
    required this.selected,
    required this.hint,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final chipStyle = TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w600,
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
      color: AppColors.textHeading,
    );

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: ResponsiveHelper.getResponsiveWidth(context, 6),
              runSpacing: ResponsiveHelper.getResponsiveHeight(context, 6),
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final staff in selected)
                  InputChip(
                    label: Text(staff.name, style: chipStyle),
                    onDeleted: () => onRemove(staff.id),
                    deleteIconColor: AppColors.textSecondary,
                    backgroundColor: AppColors.filterButtonBackground,
                    side: BorderSide(color: AppColors.searchBorder),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveWidth(context, 6),
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: ResponsiveHelper.getResponsiveWidth(context, 96),
                    maxWidth: ResponsiveHelper.getResponsiveWidth(context, 220),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        13.5,
                      ),
                      color: AppColors.textHeading,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: selected.isEmpty ? hint : 'Add more…',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13.5,
                        ),
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveHelper.getResponsiveHeight(context, 4),
            ),
            child: const AppSvgIcon(
              AppAssets.search,
              size: 17,
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffSuggestionsPanel extends StatelessWidget {
  final bool searching;
  final String error;
  final List<TaskStaffOption> suggestions;
  final ValueChanged<TaskStaffOption> onSelected;

  const _StaffSuggestionsPanel({
    required this.searching,
    required this.error,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: ResponsiveHelper.getResponsiveHeight(context, 220),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: searching
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.secondaryTeal),
              ),
            )
          : error.isNotEmpty && suggestions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : suggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No staff found.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = suggestions[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            option.name,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                13.5,
                              ),
                              color: AppColors.textHeading,
                            ),
                          ),
                          subtitle: option.subtitle == null
                              ? null
                              : Text(
                                  option.subtitle!,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      12,
                                    ),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
    );
  }
}

class _ResidentSuggestionsPanel extends StatelessWidget {
  final bool searching;
  final String error;
  final List<TaskClientOption> suggestions;
  final String? selectedId;
  final ValueChanged<TaskClientOption> onSelected;

  const _ResidentSuggestionsPanel({
    required this.searching,
    required this.error,
    required this.suggestions,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: ResponsiveHelper.getResponsiveHeight(context, 220),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: searching
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.secondaryTeal),
              ),
            )
          : error.isNotEmpty && suggestions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : suggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No residents found.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = suggestions[index];
                        final selected = selectedId == option.id;
                        return ListTile(
                          dense: true,
                          title: Text(
                            option.name,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                13.5,
                              ),
                              color: AppColors.textHeading,
                            ),
                          ),
                          subtitle: option.subtitle == null
                              ? null
                              : Text(
                                  option.subtitle!,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      12,
                                    ),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.secondaryTeal,
                                )
                              : null,
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
    );
  }
}

class _ChecklistComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _ChecklistComposer({
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 48);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    return Row(
      children: [
        Expanded(
          child: WizardTextField(
            controller: controller,
            hint: 'Add a step — “Check the fridge temperature”',
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Material(
          color: AppColors.secondaryTeal,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: ResponsiveHelper.getResponsiveSize(context, 22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistItemRow extends StatelessWidget {
  final _ChecklistDraft item;
  final ValueChanged<bool> onMustBeDoneChanged;
  final VoidCallback onRemove;

  const _ChecklistItemRow({
    required this.item,
    required this.onMustBeDoneChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textHeading,
              ),
            ),
          ),
          Text(
            'Must be done',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
              color: AppColors.textSecondary,
            ),
          ),
          Checkbox(
            value: item.mustBeDone,
            onChanged: (value) => onMustBeDoneChanged(value ?? false),
            activeColor: AppColors.secondaryTeal,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          IconButton(
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool bordered;

  const _ToggleBlock({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.bordered,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AppColors.textHeading,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.secondaryTeal,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.cardBorder,
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );

    if (!bordered) return content;

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: content,
    );
  }
}

class _DocsDropzone extends StatelessWidget {
  final List<String> files;
  final VoidCallback onTap;
  final ValueChanged<int> onRemove;

  const _DocsDropzone({
    required this.files,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 44);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: const Color(0xFFD5DEE6),
              radius: radius,
            ),
            child: Container(
              width: double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                vertical: 24,
                horizontal: 16,
              ),
              child: Column(
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EEF3),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, 12),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: ResponsiveHelper.getResponsiveSize(context, 22),
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                        color: AppColors.textBody,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Click to upload',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' or drag & drop'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Text(
                    'PDF, JPG, PNG · Max 15MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (var i = 0; i < files.length; i++) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.searchBorder),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: ResponsiveHelper.getResponsiveSize(context, 18),
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Expanded(
                  child: Text(
                    files[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(i),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 18),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  const _Footer({required this.onCancel, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Material(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(radius),
                child: InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(radius),
                  child: Container(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: AppColors.searchBorder),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Material(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(radius),
                child: InkWell(
                  onTap: onCreate,
                  borderRadius: BorderRadius.circular(radius),
                  child: Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Text(
                      'Create Task',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
        color: AppColors.textMuted,
        height: 1.35,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
