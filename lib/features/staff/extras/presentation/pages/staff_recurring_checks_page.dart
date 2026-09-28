import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../domain/entities/staff_residence.dart';
import '../../domain/repositories/staff_extras_repository.dart';
import '../../../tasks_messages/domain/entities/recurring_check_instance.dart';
import '../../../tasks_messages/domain/entities/recurring_check_schedule.dart';
import '../../../tasks_messages/domain/repositories/staff_tasks_messages_repository.dart';

/// Dedicated Recurring Checks module (BUG_Report008).
class StaffRecurringChecksPage extends StatefulWidget {
  const StaffRecurringChecksPage({super.key});

  @override
  State<StaffRecurringChecksPage> createState() =>
      _StaffRecurringChecksPageState();
}

class _StaffRecurringChecksPageState extends State<StaffRecurringChecksPage>
    with SingleTickerProviderStateMixin {
  late final StaffTasksMessagesRepository _repository;
  StaffExtrasRepository? _extrasRepository;
  late final TabController _tabController;

  bool _loading = true;
  String? _error;
  List<RecurringCheckSchedule> _schedules = const [];
  List<RecurringCheckInstance> _dueItems = const [];
  List<RecurringCheckInstance> _checks = const [];
  List<StaffResidence> _residences = const [];
  List<Map<String, String>> _residentOptions = const [];

  String _residenceFilter = 'all';
  DateTime _day = DateTime.now();
  String _statusFilter = 'all';
  bool _onlyMine = false;

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffTasksMessagesRepository>();
    if (GetIt.instance.isRegistered<StaffExtrasRepository>()) {
      _extrasRepository = GetIt.instance<StaffExtrasRepository>();
    }
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final start = IsoDateRange.startOfLocalDay(_day);
    final end = start.add(const Duration(days: 1));
    final schedulesResult = await _repository.getRecurringCheckSchedules();
    final instancesResult = await _repository.getRecurringCheckInstances(
      from: start,
      to: end,
      status: _statusFilter,
      residenceId: _residenceFilter,
      mine: _onlyMine,
    );
    final entriesResult = await _repository.getRecurringCheckEntries(
      residenceId: _residenceFilter,
      from: start,
      to: end,
    );
    final residencesResult = await _extrasRepository?.getResidences();
    final residents = await _loadResidentOptions(_residenceFilter);

    if (!mounted) return;
    if (schedulesResult.isFailure &&
        instancesResult.isFailure &&
        entriesResult.isFailure) {
      setState(() {
        _error =
            schedulesResult.error?.message ??
            instancesResult.error?.message ??
            entriesResult.error?.message ??
            'Could not load recurring checks.';
        _loading = false;
      });
      return;
    }

    final instances = instancesResult.value ?? const <RecurringCheckInstance>[];
    final recordedEntries =
        entriesResult.value ?? const <RecurringCheckInstance>[];
    setState(() {
      _schedules = schedulesResult.value ?? const [];
      _dueItems = instances.where((item) => !item.isRecorded).toList();
      _checks = recordedEntries.isNotEmpty
          ? recordedEntries
          : instances.where((item) => item.isRecorded).toList();
      _residences = residencesResult?.value ?? const [];
      _residentOptions = residents;
      _loading = false;
    });
  }

  Future<List<Map<String, String>>> _loadResidentOptions(
    String residenceId,
  ) async {
    final extras = _extrasRepository;
    if (extras == null) return _residentOptionsFromLoadedData();
    final result = await extras.getResidenceClients(residenceId);
    if (result.isSuccess && (result.value?.isNotEmpty ?? false)) {
      return result.value ?? const [];
    }
    return _residentOptionsFromLoadedData();
  }

  List<Map<String, String>> _residentOptionsFromLoadedData() {
    final rows = <String, Map<String, String>>{};
    for (final item in [..._dueItems, ..._checks]) {
      if (item.clientId.isEmpty) continue;
      rows[item.clientId] = {
        'id': item.clientId,
        'title': item.clientName.isEmpty ? 'Resident' : item.clientName,
        'subtitle': item.roomLabel,
        'residenceId': item.residenceId,
      };
    }
    for (final schedule in _schedules) {
      if (schedule.clientId.isEmpty) continue;
      rows[schedule.clientId] = {
        'id': schedule.clientId,
        'title': schedule.clientName.isEmpty ? 'Resident' : schedule.clientName,
        'subtitle': schedule.residenceName,
        'residenceId': schedule.residenceId,
      };
    }
    return rows.values.toList(growable: false);
  }

  Future<List<Map<String, String>>> _loadStaffOptions(
    String residenceId,
  ) async {
    final extras = _extrasRepository;
    if (extras == null ||
        residenceId.isEmpty ||
        residenceId == 'all') {
      return const [];
    }
    final result = await extras.getResidenceStaffMembers(residenceId);
    return result.when(
      success: (items) async => items,
      failure: (_) async => const <Map<String, String>>[],
    );
  }

  Future<void> _openNewSchedule() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _NewScheduleDialog(
        residences: _residences,
        residents: _residentOptions,
        onResidenceChanged: _loadResidentOptions,
        onStaffChanged: _loadStaffOptions,
        onSubmit: (input) => _repository.createRecurringCheckSchedule(
          residenceId: input.residenceId,
          clientId: input.clientId,
          name: input.name,
          checkType: input.checkType,
          instructions: input.instructions,
          frequency: input.frequency,
          intervalMinutes: input.intervalMinutes,
          activeFromMinute: input.activeFromMinute,
          activeToMinute: input.activeToMinute,
          effectiveFrom: input.startsAt,
          expiresAt: input.stopsAt,
          alertEnabled: input.alertEnabled,
          assignedRole: input.assignedRole,
          assignedStaffId: input.assignedStaffId,
        ),
      ),
    );
    if (created == true) {
      AppSnackbar.show('Schedule created', 'Recurring check schedule saved.');
      _load();
    }
  }

  Future<void> _openEditSchedule(RecurringCheckSchedule schedule) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _NewScheduleDialog(
        title: 'Edit recurring check',
        submitLabel: 'Save changes',
        initialSchedule: schedule,
        residences: _residences,
        residents: _residentOptions,
        onResidenceChanged: _loadResidentOptions,
        onStaffChanged: _loadStaffOptions,
        onSubmit: (input) => _repository.updateRecurringCheckSchedule(
          scheduleId: schedule.id,
          fields: input.toApiFields(),
        ),
      ),
    );
    if (updated == true) {
      AppSnackbar.show('Schedule updated', schedule.name);
      _load();
    }
  }

  Future<void> _openRecordProgress() async {
    var residents = _residentOptions;
    if (residents.isEmpty ||
        residents.every((item) => (item['residenceId'] ?? '').isEmpty)) {
      residents = await _loadResidentOptions(_residenceFilter);
    }
    if (!mounted) return;
    final recorded = await showDialog<bool>(
      context: context,
      builder: (_) => _RecordProgressDialog(
        residents: residents,
        onSubmit: (clientId, residenceId, note, outcome) =>
            _repository.recordRecurringCheckProgress(
              clientId: clientId,
              residenceId: residenceId,
              note: note,
              checkName: 'Welfare observation',
              outcome: outcome,
            ),
      ),
    );
    if (recorded == true) {
      AppSnackbar.show('Progress recorded', 'Recurring check entry saved.');
      _load();
    }
  }

  Future<void> _complete(RecurringCheckInstance check) async {
    final result = await _repository.updateRecurringCheck(
      instanceId: check.id,
      status: 'requires_review',
      statusNote: 'Completed from Recurring Checks',
    );
    result.when(
      success: (_) {
        AppSnackbar.show('Check updated', check.title);
        _load();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not update check',
      ),
    );
  }

  Future<void> _skip(RecurringCheckInstance check) async {
    final result = await _repository.updateRecurringCheck(
      instanceId: check.id,
      status: 'skipped',
      statusNote: 'Skipped from Recurring Checks',
    );
    result.when(
      success: (_) {
        AppSnackbar.show('Check skipped', check.title);
        _load();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not skip check',
      ),
    );
  }

  Future<void> _toggleSchedule(RecurringCheckSchedule schedule) async {
    final result = await _repository.updateRecurringCheckSchedule(
      scheduleId: schedule.id,
      fields: {'isActive': !schedule.isActive},
    );
    result.when(
      success: (_) {
        AppSnackbar.show(
          schedule.isActive ? 'Schedule paused' : 'Schedule resumed',
          schedule.name,
        );
        _load();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not update schedule',
      ),
    );
  }

  Future<void> _deleteSchedule(RecurringCheckSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text('Delete ${schedule.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _repository.deleteRecurringCheckSchedule(schedule.id);
    result.when(
      success: (_) {
        AppSnackbar.show('Schedule deleted', schedule.name);
        _load();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not delete schedule',
      ),
    );
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _day = picked);
    _load();
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'pending' => AppColors.urgentAmber,
      'missed' => AppColors.criticalRed,
      'in_progress' || 'in progress' => AppColors.infoBlue,
      'requires_review' || 'requires review' => AppColors.secondaryTeal,
      'normal' || 'recorded' || 'completed' => AppColors.secondaryTeal,
      'needs_attention' || 'urgent' => AppColors.urgentAmber,
      'skipped' => AppColors.textMuted,
      _ => AppColors.textSecondary,
    };
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      '' => 'Pending',
      'in_progress' => 'In progress',
      'requires_review' => 'Requires review',
      _ =>
        normalized
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' '),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('staff-recurring-checks-page'),
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Recurring Checks'),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.secondaryTeal,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondaryTeal,
          tabs: const [
            Tab(text: 'Schedules'),
            Tab(text: 'Due'),
            Tab(text: 'Checks'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            )
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: _load,
              child: Column(
                children: [
                  _ActionsBar(
                    onRecordProgress: _openRecordProgress,
                    onNewSchedule: _openNewSchedule,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _SchedulesTab(
                          schedules: _schedules,
                          onEdit: _openEditSchedule,
                          onToggle: _toggleSchedule,
                          onDelete: _deleteSchedule,
                        ),
                        _InstancesTab(
                          filters: _filters(),
                          items: _dueItems,
                          emptyText: 'No recurring checks are due.',
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          onComplete: _complete,
                          onSkip: _skip,
                        ),
                        _InstancesTab(
                          filters: _filters(),
                          items: _checks,
                          emptyText:
                              'No checks were recorded for these filters.',
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          onComplete: _complete,
                          onSkip: _skip,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _filters() {
    return _FiltersBar(
      residences: _residences,
      residenceFilter: _residenceFilter,
      day: _day,
      statusFilter: _statusFilter,
      onlyMine: _onlyMine,
      onResidenceChanged: (value) {
        setState(() => _residenceFilter = value);
        _load();
      },
      onPickDay: _pickDay,
      onStatusChanged: (value) {
        setState(() => _statusFilter = value);
        _load();
      },
      onOnlyMineChanged: (value) {
        setState(() => _onlyMine = value);
        _load();
      },
    );
  }
}

class _ActionsBar extends StatelessWidget {
  final VoidCallback onRecordProgress;
  final VoidCallback onNewSchedule;

  const _ActionsBar({
    required this.onRecordProgress,
    required this.onNewSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: onRecordProgress,
            icon: const Icon(Icons.playlist_add_check_outlined),
            label: const Text('Record Progress'),
          ),
          FilledButton.icon(
            onPressed: onNewSchedule,
            icon: const Icon(Icons.add),
            label: const Text('+ New Schedule'),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final List<StaffResidence> residences;
  final String residenceFilter;
  final DateTime day;
  final String statusFilter;
  final bool onlyMine;
  final ValueChanged<String> onResidenceChanged;
  final VoidCallback onPickDay;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onOnlyMineChanged;

  const _FiltersBar({
    required this.residences,
    required this.residenceFilter,
    required this.day,
    required this.statusFilter,
    required this.onlyMine,
    required this.onResidenceChanged,
    required this.onPickDay,
    required this.onStatusChanged,
    required this.onOnlyMineChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                key: const Key('staff-recurring-residence-filter'),
                initialValue: residenceFilter,
                decoration: const InputDecoration(
                  labelText: 'All my residences',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All my residences'),
                  ),
                  ...residences.map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  ),
                ],
                onChanged: (value) => onResidenceChanged(value ?? 'all'),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('staff-recurring-day-filter'),
              onPressed: onPickDay,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(IsoDateRange.formatShortDate(day)),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                key: const Key('staff-recurring-status-filter'),
                initialValue: statusFilter,
                decoration: const InputDecoration(labelText: 'Any status'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Any status')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'missed', child: Text('Missed')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In progress'),
                  ),
                  DropdownMenuItem(
                    value: 'requires_review',
                    child: Text('Requires review'),
                  ),
                  DropdownMenuItem(value: 'skipped', child: Text('Skipped')),
                ],
                onChanged: (value) => onStatusChanged(value ?? 'all'),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Only mine'),
                    Text(
                      'Checks assigned to me',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Switch(
                  key: const Key('staff-recurring-only-mine'),
                  value: onlyMine,
                  activeThumbColor: AppColors.secondaryTeal,
                  onChanged: onOnlyMineChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulesTab extends StatelessWidget {
  final List<RecurringCheckSchedule> schedules;
  final ValueChanged<RecurringCheckSchedule> onEdit;
  final ValueChanged<RecurringCheckSchedule> onToggle;
  final ValueChanged<RecurringCheckSchedule> onDelete;

  const _SchedulesTab({
    required this.schedules,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return const _EmptyList(text: 'No recurring check schedules yet.');
    }
    return ListView.separated(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      itemCount: schedules.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      schedule.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  _Pill(
                    label: schedule.isActive ? 'Active' : 'Paused',
                    color: schedule.isActive
                        ? AppColors.secondaryTeal
                        : AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                schedule.clientResidenceLabel,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _MetaText(
                    icon: Icons.repeat_outlined,
                    text: schedule.frequencyLabel,
                  ),
                  _MetaText(
                    icon: Icons.person_outline,
                    text: schedule.assigneeLabel,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => onEdit(schedule),
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    onPressed: () => onToggle(schedule),
                    child: Text(schedule.isActive ? 'Pause' : 'Resume'),
                  ),
                  TextButton(
                    onPressed: () => onDelete(schedule),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InstancesTab extends StatelessWidget {
  final Widget filters;
  final List<RecurringCheckInstance> items;
  final String emptyText;
  final Color Function(String status) statusColor;
  final String Function(String status) statusLabel;
  final ValueChanged<RecurringCheckInstance> onComplete;
  final ValueChanged<RecurringCheckInstance> onSkip;

  const _InstancesTab({
    required this.filters,
    required this.items,
    required this.emptyText,
    required this.statusColor,
    required this.statusLabel,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
        children: [
          filters,
          const SizedBox(height: 80),
          Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) return filters;
        final check = items[index - 1];
        final color = statusColor(check.statusRaw);
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      check.title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  _Pill(label: statusLabel(check.statusRaw), color: color),
                ],
              ),
              const SizedBox(height: 8),
              if (check.clientRoomDueLabel.isNotEmpty)
                _MetaText(
                  icon: Icons.schedule_outlined,
                  text: check.clientRoomDueLabel,
                ),
              if (check.location.isNotEmpty) ...[
                const SizedBox(height: 6),
                _MetaText(icon: Icons.home_outlined, text: check.location),
              ],
              const SizedBox(height: 6),
              _MetaText(
                icon: Icons.assignment_ind_outlined,
                text: check.assignmentLabel,
              ),
              if (check.isOpen) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onSkip(check),
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => onComplete(check),
                        child: const Text('Complete'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NewScheduleDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final RecurringCheckSchedule? initialSchedule;
  final List<StaffResidence> residences;
  final List<Map<String, String>> residents;
  final Future<List<Map<String, String>>> Function(String residenceId)
  onResidenceChanged;
  final Future<List<Map<String, String>>> Function(String residenceId)
  onStaffChanged;
  final Future<Result<void>> Function(_ScheduleInput input) onSubmit;

  const _NewScheduleDialog({
    this.title = 'New recurring check',
    this.submitLabel = 'Create check',
    this.initialSchedule,
    required this.residences,
    required this.residents,
    required this.onResidenceChanged,
    required this.onStaffChanged,
    required this.onSubmit,
  });

  @override
  State<_NewScheduleDialog> createState() => _NewScheduleDialogState();
}

class _NewScheduleDialogState extends State<_NewScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _everyController = TextEditingController(text: '30');
  String? _residenceId;
  String? _clientId;
  String _checkType = 'other';
  String _frequency = 'interval';
  TimeOfDay? _fromTime;
  TimeOfDay? _untilTime;
  DateTime? _startsAt;
  DateTime? _stopsAt;
  bool _alertEnabled = false;
  String _assignedRole = '';
  String _assignedStaffId = '';
  late List<Map<String, String>> _residents;
  List<Map<String, String>> _staff = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final schedule = widget.initialSchedule;
    _residents = [
      ...widget.residents,
      if (schedule != null &&
          schedule.clientId.isNotEmpty &&
          !widget.residents.any((item) => item['id'] == schedule.clientId))
        {
          'id': schedule.clientId,
          'title': schedule.clientName.isEmpty
              ? 'Resident'
              : schedule.clientName,
          'subtitle': schedule.residenceName,
          'residenceId': schedule.residenceId,
        },
    ];
    _residenceId =
        schedule?.residenceId.isNotEmpty == true
        ? schedule!.residenceId
        : (widget.residences.isNotEmpty ? widget.residences.first.id : null);
    _clientId = schedule?.clientId;
    if (_clientId == null && _residents.isNotEmpty) {
      _clientId = _residents.first['id'];
    }
    if (schedule != null) {
      _nameController.text = schedule.name;
      _checkType = schedule.checkType.isEmpty ? 'other' : schedule.checkType;
      _instructionsController.text = schedule.instructions;
      _frequency = schedule.frequency.isEmpty ? 'interval' : schedule.frequency;
      _everyController.text = (schedule.intervalMinutes ?? 30).toString();
      _alertEnabled = schedule.alertEnabled;
      _assignedRole = schedule.assignedRole;
      _assignedStaffId = schedule.assignedStaffId;
    }
    if (_residenceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final residents = await widget.onResidenceChanged(_residenceId!);
        final staff = await widget.onStaffChanged(_residenceId!);
        if (!mounted) return;
        setState(() {
          _residents = residents;
          _staff = staff;
          if (_clientId == null && _residents.isNotEmpty) {
            _clientId = _residents.first['id'];
          }
          if (_assignedStaffId.isNotEmpty &&
              !_staff.any((item) => item['id'] == _assignedStaffId) &&
              schedule != null &&
              schedule.assignedStaffName.isNotEmpty) {
            _staff = [
              ..._staff,
              {
                'id': _assignedStaffId,
                'title': schedule.assignedStaffName,
                'subtitle': '',
              },
            ];
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _everyController.dispose();
    super.dispose();
  }

  Future<void> _changeResidence(String? value) async {
    if (value == null) return;
    setState(() {
      _residenceId = value;
      _clientId = null;
      _assignedStaffId = '';
      _staff = const [];
    });
    final residents = await widget.onResidenceChanged(value);
    final staff = await widget.onStaffChanged(value);
    if (!mounted) return;
    setState(() {
      _residents = residents;
      _staff = staff;
      if (_residents.isNotEmpty) _clientId = _residents.first['id'];
    });
  }

  Future<void> _pickTime({required bool from}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: from
          ? (_fromTime ?? const TimeOfDay(hour: 8, minute: 0))
          : (_untilTime ?? const TimeOfDay(hour: 20, minute: 0)),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _fromTime = picked;
      } else {
        _untilTime = picked;
      }
    });
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startsAt = picked;
      } else {
        _stopsAt = picked;
      }
    });
  }

  String _timeLabel(TimeOfDay? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String? _minutePayload(TimeOfDay? time) {
    if (time == null) return null;
    return '${(time.hour * 60) + time.minute}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await widget.onSubmit(
      _ScheduleInput(
        residenceId: _residenceId!,
        clientId: _clientId!,
        name: _nameController.text.trim(),
        checkType: _checkType,
        instructions: _instructionsController.text.trim(),
        frequency: _frequency,
        intervalMinutes: int.tryParse(_everyController.text.trim()) ?? 30,
        activeFromMinute: _minutePayload(_fromTime) ?? '',
        activeToMinute: _minutePayload(_untilTime) ?? '',
        startsAt: _startsAt,
        stopsAt: _stopsAt,
        alertEnabled: _alertEnabled,
        assignedRole: _assignedRole,
        assignedStaffId: _assignedStaffId,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => Navigator.of(context).pop(true),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not create check',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'What is checked, how often, and who is expected to do it.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SectionLabel('Resident'),
                DropdownButtonFormField<String>(
                  key: const Key('staff-recurring-new-residence'),
                  initialValue: _residenceId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Residence *',
                    hintText: 'Choose a residence',
                  ),
                  items: widget.residences
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  validator: (value) => value == null ? 'Required' : null,
                  onChanged: _changeResidence,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const Key('staff-recurring-new-resident'),
                  initialValue: _clientId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Resident *',
                    hintText: 'Any resident',
                  ),
                  items: _residents
                      .map(
                        (item) => DropdownMenuItem(
                          value: item['id'],
                          child: Text(
                            item['title'] ?? 'Resident',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  validator: (value) => value == null ? 'Required' : null,
                  onChanged: (value) => setState(() => _clientId = value),
                ),
                const SizedBox(height: 16),
                const _SectionLabel('The check'),
                TextFormField(
                  key: const Key('staff-recurring-new-name'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g. Blood pressure check',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _checkType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                    DropdownMenuItem(value: 'welfare', child: Text('Welfare')),
                    DropdownMenuItem(value: 'vitals', child: Text('Vitals')),
                    DropdownMenuItem(
                      value: 'medication',
                      child: Text('Medication'),
                    ),
                    DropdownMenuItem(
                      value: 'reposition',
                      child: Text('Reposition'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _checkType = value ?? 'other'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _instructionsController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    hintText:
                        'What the person carrying it out needs to know...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionLabel('How often'),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(
                      value: 'interval',
                      child: Text('Every N minutes'),
                    ),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) =>
                      setState(() => _frequency = value ?? 'interval'),
                ),
                if (_frequency == 'interval') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _everyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Every (minutes)',
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(from: true),
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text('Only from ${_timeLabel(_fromTime)}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(from: false),
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text('Only until ${_timeLabel(_untilTime)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Leave both empty for all day',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(start: true),
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _startsAt == null
                              ? 'Starts dd/mm/yyyy'
                              : '${_startsAt!.day.toString().padLeft(2, '0')}/'
                                    '${_startsAt!.month.toString().padLeft(2, '0')}/'
                                    '${_startsAt!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(start: false),
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _stopsAt == null
                              ? 'Stops dd/mm/yyyy'
                              : '${_stopsAt!.day.toString().padLeft(2, '0')}/'
                                    '${_stopsAt!.month.toString().padLeft(2, '0')}/'
                                    '${_stopsAt!.year}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Leave empty to keep it running',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionLabel('Tell somebody when it reads wrong'),
                Material(
                  key: const Key('staff-recurring-alert-card'),
                  color: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: SwitchListTile(
                      key: const Key('staff-recurring-alert-toggle'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Alert on an abnormal reading',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Raises it on the Priority Notes board and notifies the shift.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _alertEnabled,
                      onChanged: (value) =>
                          setState(() => _alertEnabled = value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionLabel('Who does it'),
                DropdownButtonFormField<String>(
                  key: const Key('staff-recurring-assigned-role'),
                  initialValue: _assignedRole,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Whoever is on shift'),
                    ),
                    DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                    DropdownMenuItem(
                      value: 'caregiver',
                      child: Text('Caregiver'),
                    ),
                    DropdownMenuItem(
                      value: 'residence_manager',
                      child: Text('Residence manager'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _assignedRole = value ?? ''),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const Key('staff-recurring-assigned-staff'),
                  initialValue: _assignedStaffId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Specific person',
                    hintText: 'Optional',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Optional'),
                    ),
                    ..._staff.map(
                      (item) => DropdownMenuItem(
                        value: item['id'] ?? '',
                        child: Text(
                          item['title'] ?? 'Staff',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _assignedStaffId = value ?? ''),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Leave empty unless one named person owns this check',
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
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('staff-recurring-create-check'),
          onPressed: _saving ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _RecordProgressDialog extends StatefulWidget {
  final List<Map<String, String>> residents;
  final Future<Result<void>> Function(
    String clientId,
    String residenceId,
    String note,
    String outcome,
  )
  onSubmit;

  const _RecordProgressDialog({
    required this.residents,
    required this.onSubmit,
  });

  @override
  State<_RecordProgressDialog> createState() => _RecordProgressDialogState();
}

class _RecordProgressDialogState extends State<_RecordProgressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  String? _clientId;
  String _outcome = 'normal';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.residents.isNotEmpty) _clientId = widget.residents.first['id'];
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String? get _selectedResidenceId {
    for (final item in widget.residents) {
      if (item['id'] == _clientId) {
        final residenceId = item['residenceId']?.trim() ?? '';
        return residenceId.isEmpty ? null : residenceId;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final residenceId = _selectedResidenceId;
    if (residenceId == null) {
      AppErrorDialog.showResultError(
        const ApiError(
          message:
              'Select a resident with a known residence before recording progress.',
        ),
        fallbackTitle: 'Could not record progress',
      );
      return;
    }
    setState(() => _saving = true);
    final result = await widget.onSubmit(
      _clientId!,
      residenceId,
      _noteController.text.trim(),
      _outcome,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => Navigator.of(context).pop(true),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not record progress',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Record Progress',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Record a resident welfare observation, vital check, or care progress',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('staff-recurring-progress-resident'),
                initialValue: _clientId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Resident *',
                  hintText: 'Select resident',
                ),
                items: widget.residents
                    .map(
                      (item) => DropdownMenuItem(
                        value: item['id'],
                        child: Text(
                          item['title'] ?? 'Resident',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                validator: (value) => value == null ? 'Required' : null,
                onChanged: (value) => setState(() => _clientId = value),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('staff-recurring-progress-note'),
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'What you saw *',
                  hintText: 'Sleeping, settled, no concerns...',
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _outcome,
                decoration: const InputDecoration(labelText: 'Outcome'),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(
                    value: 'needs_attention',
                    child: Text('Needs attention'),
                  ),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (value) =>
                    setState(() => _outcome = value ?? 'normal'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: const Text('Record progress'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          color: AppColors.textHeading,
        ),
      ),
    );
  }
}

class _ScheduleInput {
  final String residenceId;
  final String clientId;
  final String name;
  final String checkType;
  final String instructions;
  final String frequency;
  final int intervalMinutes;
  final String activeFromMinute;
  final String activeToMinute;
  final DateTime? startsAt;
  final DateTime? stopsAt;
  final bool alertEnabled;
  final String assignedRole;
  final String assignedStaffId;

  const _ScheduleInput({
    required this.residenceId,
    required this.clientId,
    required this.name,
    required this.checkType,
    required this.instructions,
    required this.frequency,
    required this.intervalMinutes,
    required this.activeFromMinute,
    required this.activeToMinute,
    required this.startsAt,
    required this.stopsAt,
    this.alertEnabled = false,
    this.assignedRole = '',
    this.assignedStaffId = '',
  });

  Map<String, dynamic> toApiFields() {
    final fromMinute = int.tryParse(activeFromMinute);
    final toMinute = int.tryParse(activeToMinute);
    final role = assignedRole.trim();
    final staffId = assignedStaffId.trim();
    return {
      'clientId': clientId,
      'residenceId': residenceId,
      'name': name,
      'checkType': checkType.isEmpty ? 'other' : checkType,
      if (instructions.isNotEmpty) 'instructions': instructions,
      'frequency': frequency,
      'intervalMinutes': intervalMinutes,
      if (fromMinute != null) 'activeFromMinute': fromMinute,
      if (toMinute != null) 'activeToMinute': toMinute,
      if (startsAt != null)
        'effectiveFrom': startsAt!.toUtc().toIso8601String(),
      if (stopsAt != null) 'expiresAt': stopsAt!.toUtc().toIso8601String(),
      'alertEnabled': alertEnabled,
      if (alertEnabled)
        'alertRules': {
          'rules': [
            {
              'field': 'outcome',
              'operator': 'ne',
              'value': 'normal',
            },
          ],
          'notifyRoles': [role.isEmpty ? 'nurse' : role],
        },
      if (role.isNotEmpty) 'assignedRole': role,
      if (staffId.isNotEmpty) 'assignedStaffId': staffId,
    };
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _EmptyList extends StatelessWidget {
  final String text;

  const _EmptyList({required this.text});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
