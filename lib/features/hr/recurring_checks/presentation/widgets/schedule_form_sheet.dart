import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/recurring_check.dart';
import '../controllers/recurring_checks_controller.dart';
import '../recurring_checks_labels.dart';
import 'check_common.dart';

/// Web "New recurring check" / "Edit recurring check" modal.
Future<void> showScheduleFormSheet(
  BuildContext context, {
  required RecurringChecksController controller,
  CheckSchedule? editing,
}) =>
    showCheckSheet<void>(
      context,
      (_) => _ScheduleFormSheet(controller: controller, editing: editing),
    );

class _RuleDraft {
  String field;
  String operator;
  final TextEditingController value;
  String severity;
  bool raiseIncident;

  _RuleDraft({
    this.field = '',
    this.operator = 'gt',
    String value = '',
    this.severity = 'needs_attention',
    this.raiseIncident = false,
  }) : value = TextEditingController(text: value);
}

class _ScheduleFormSheet extends StatefulWidget {
  final RecurringChecksController controller;
  final CheckSchedule? editing;

  const _ScheduleFormSheet({required this.controller, this.editing});

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _name = TextEditingController();
  final _instructions = TextEditingController();
  final _interval = TextEditingController(text: '30');
  final _dayOfMonth = TextEditingController(text: '1');

  String? _residenceId;
  String? _clientId;
  List<CheckOption> _clients = const [];
  int _clientSerial = 0;

  String _checkType = 'other';
  String _frequency = 'interval';
  String _activeFrom = '';
  String _activeTo = '';
  List<String> _times = ['08:00'];
  List<int> _weekdays = [1, 3, 5];
  DateTime? _startsOn;
  DateTime? _stopsOn;
  bool _alertEnabled = false;
  final List<_RuleDraft> _rules = [];
  List<String> _notifyRoles = [];
  String _role = '';
  String _staffId = '';

  String? _error;
  bool _saving = false;

  RecurringChecksController get _c => widget.controller;
  CheckSchedule? get _editing => widget.editing;
  bool get _isInterval => _frequency == 'interval';

  @override
  void initState() {
    super.initState();
    final s = _editing;
    if (s == null) {
      _residenceId = _c.residenceId.value;
      _loadClients();
      return;
    }
    _name.text = s.name ?? '';
    _checkType = s.checkType ?? 'other';
    _instructions.text = s.instructions ?? '';
    _frequency = s.frequency ?? 'interval';
    _interval.text = '${s.intervalMinutes ?? 30}';
    _times = s.timesOfDay.map(CheckLabels.clock).toList();
    _weekdays = [...s.weekdays];
    _dayOfMonth.text = '${s.dayOfMonth ?? 1}';
    _role = s.assignedRole ?? '';
    _staffId = s.assignedStaffId ?? '';
    _startsOn = _utcDay(s.effectiveFrom);
    _stopsOn = _utcDay(s.expiresAt);
    _activeFrom = s.activeFromMinute == null ? '' : CheckLabels.clock(s.activeFromMinute!);
    _activeTo = s.activeToMinute == null ? '' : CheckLabels.clock(s.activeToMinute!);
    _alertEnabled = s.alertEnabled;
    _rules.addAll([
      for (final r in s.alertRules)
        _RuleDraft(
          field: r.field,
          operator: r.operator,
          value: '${r.value}',
          severity: r.severity,
          raiseIncident: r.raiseIncident,
        ),
    ]);
    _notifyRoles = [...s.notifyRoles];
  }

  /// The web reads the stored ISO date's first ten characters.
  static DateTime? _utcDay(DateTime? value) {
    if (value == null) return null;
    final utc = value.toUtc();
    return DateTime(utc.year, utc.month, utc.day);
  }

  @override
  void dispose() {
    _name.dispose();
    _instructions.dispose();
    _interval.dispose();
    _dayOfMonth.dispose();
    for (final r in _rules) {
      r.value.dispose();
    }
    super.dispose();
  }

  Future<void> _loadClients() async {
    final serial = ++_clientSerial;
    final result = await _c.repository.clients(residenceId: _residenceId);
    if (!mounted || serial != _clientSerial) return;
    setState(() => _clients = result.when(success: (c) => c, failure: (_) => const []));
  }

  Future<String?> _pick(String title, List<(String, String)> options, String? selected) =>
      pickHandoverOption(context, title: title, options: options, selected: selected);

  Future<String?> _pickTime(String current) async {
    final minutes = CheckLabels.minutesOf(current);
    final picked = await showTimePicker(
      context: context,
      initialTime: minutes == null
          ? const TimeOfDay(hour: 8, minute: 0)
          : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return CheckLabels.clock(picked.hour * 60 + picked.minute);
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
  }

  static String _iso(DateTime day, {bool endOfDay = false}) => (endOfDay
          ? DateTime(day.year, day.month, day.day, 23, 59, 59)
          : DateTime(day.year, day.month, day.day))
      .toUtc()
      .toIso8601String();

  Future<void> _submit() async {
    setState(() => _error = null);
    final editing = _editing;
    if (editing == null && (_residenceId == null || _clientId == null)) {
      return setState(() => _error = 'Choose a residence and a resident.');
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      return setState(
          () => _error = 'Give the check a name — a nameless schedule is a row of ids.');
    }
    final times = [for (final t in _times) ?CheckLabels.minutesOf(t)];
    if (!_isInterval && times.isEmpty) {
      return setState(() => _error = 'Add at least one time of day.');
    }
    final interval = num.tryParse(_interval.text.trim());
    if (_isInterval && !(interval != null && interval > 0)) {
      return setState(() => _error = 'An interval above zero is required.');
    }
    if (_frequency == 'weekly' && _weekdays.isEmpty) {
      return setState(() => _error = 'Choose at least one day of the week.');
    }
    final rules = [
      for (final r in _rules)
        if (r.field.trim().isNotEmpty && r.value.text.trim().isNotEmpty)
          {
            'field': r.field.trim(),
            'operator': r.operator,
            'value': num.tryParse(r.value.text.trim()) ?? r.value.text.trim(),
            'severity': r.severity,
            'raiseIncident': r.raiseIncident,
          },
    ];
    final instructions = _instructions.text.trim();
    final body = <String, dynamic>{
      if (editing == null) ...{'clientId': _clientId, 'residenceId': _residenceId},
      'name': name,
      'checkType': _checkType,
      if (instructions.isNotEmpty) 'instructions': instructions,
      'frequency': _frequency,
      if (_isInterval) 'intervalMinutes': interval else 'timesOfDay': times,
      if (_frequency == 'weekly') 'weekdays': _weekdays,
      if (_frequency == 'monthly') 'dayOfMonth': num.tryParse(_dayOfMonth.text.trim()),
      if (_role.isNotEmpty) 'assignedRole': _role,
      ...rules.isNotEmpty
          ? {
              'alertEnabled': _alertEnabled,
              'alertRules': {'rules': rules, 'notifyRoles': _notifyRoles},
            }
          : {
              'alertEnabled': false,
              'alertRules': {'rules': <Object>[], 'notifyRoles': <Object>[]},
            },
      if (_staffId.isNotEmpty) 'assignedStaffId': _staffId,
      if (_startsOn != null) 'effectiveFrom': _iso(_startsOn!),
      if (_stopsOn != null) 'expiresAt': _iso(_stopsOn!, endOfDay: true),
      if (_isInterval && _activeFrom.isNotEmpty && _activeTo.isNotEmpty) ...{
        'activeFromMinute': _activeFrom,
        'activeToMinute': _activeTo,
      },
    };
    setState(() => _saving = true);
    try {
      await _c.saveSchedule(body, id: editing?.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editing;
    return CheckSheetScaffold(
      icon: Icons.timer_outlined,
      title: editing == null ? 'New recurring check' : 'Edit recurring check',
      description: 'What is checked, how often, and who is expected to do it.',
      primaryKey: const ValueKey('schedule-form-submit'),
      primaryLabel: _saving ? 'Saving…' : (editing == null ? 'Create check' : 'Save changes'),
      onPrimary: _saving ? null : _submit,
      children: [
        if (_error != null)
          CheckNotice(
            child: Text(_error!,
                style: handoverText(context, 13.5, color: AppColors.criticalRed)),
          ),
        CheckSection(title: 'Resident', children: _residentFields(context)),
        CheckSection(title: 'The check', children: _checkFields(context)),
        CheckSection(title: 'How often', children: _frequencyFields(context)),
        CheckSection(title: 'Tell somebody when it reads wrong', children: _alertFields(context)),
        CheckSection(title: 'Who does it', children: _whoFields(context)),
      ],
    );
  }

  List<Widget> _residentFields(BuildContext context) {
    final editing = _editing;
    if (editing != null) {
      return [
        Text(
          '${editing.clientName ?? 'Resident'} · ${editing.residenceName ?? ''}',
          style: handoverText(context, 13, color: AppColors.textMuted),
        ),
      ];
    }
    final residenceLabel = _c.residences.where((r) => r.id == _residenceId).firstOrNull?.label;
    final clientLabel = _clients.where((c) => c.id == _clientId).firstOrNull?.label;
    return [
      HandoverSelect(
        key: const ValueKey('schedule-form-residence'),
        label: 'Residence',
        required: true,
        value: residenceLabel,
        placeholder: 'Choose a residence',
        onTap: () async {
          final picked = await _pick(
              'Residence', [for (final r in _c.residences) (r.id, r.label)], _residenceId);
          if (picked == null || picked == _residenceId) return;
          setState(() {
            _residenceId = picked;
            _clientId = null;
            _clients = const [];
          });
          _loadClients();
        },
      ),
      HandoverSelect(
        key: const ValueKey('schedule-form-resident'),
        label: 'Resident',
        required: true,
        value: clientLabel,
        placeholder: _clients.isEmpty
            ? 'No residents to choose from'
            : _residenceId != null
                ? 'Choose a resident'
                : 'Any resident — pick a residence to narrow it',
        onTap: _clients.isEmpty
            ? null
            : () async {
                final picked = await _pick(
                    'Resident', [for (final c in _clients) (c.id, c.label)], _clientId);
                if (picked != null) setState(() => _clientId = picked);
              },
      ),
    ];
  }

  List<Widget> _checkFields(BuildContext context) => [
        CheckInput(
          key: const ValueKey('schedule-form-name'),
          label: 'Name',
          required: true,
          controller: _name,
          placeholder: 'e.g. Blood pressure monitoring',
        ),
        HandoverSelect(
          key: const ValueKey('schedule-form-type'),
          label: 'Type',
          value: CheckLabels.labelOf(CheckLabels.checkTypes, _checkType),
          placeholder: '',
          onTap: () async {
            final picked = await _pick('Type', CheckLabels.checkTypes, _checkType);
            if (picked != null) setState(() => _checkType = picked);
          },
        ),
        HandoverTextArea(
          key: const ValueKey('schedule-form-instructions'),
          label: 'Instructions',
          controller: _instructions,
          placeholder: 'What the person carrying it out needs to know…',
        ),
      ];

  List<Widget> _frequencyFields(BuildContext context) => [
        HandoverSelect(
          key: const ValueKey('schedule-form-frequency'),
          label: 'Frequency',
          value: CheckLabels.labelOf(CheckLabels.frequencies, _frequency),
          placeholder: '',
          onTap: () async {
            final picked = await _pick('Frequency', CheckLabels.frequencies, _frequency);
            if (picked != null) setState(() => _frequency = picked);
          },
        ),
        if (_isInterval) ...[
          CheckInput(
            key: const ValueKey('schedule-form-interval'),
            label: 'Every (minutes)',
            number: true,
            controller: _interval,
          ),
          CheckPickerField(
            key: const ValueKey('schedule-form-active-from'),
            label: 'Only from',
            icon: Icons.schedule_rounded,
            value: _activeFrom,
            placeholder: '--:--',
            helper: 'Leave both empty for all day',
            onTap: () async {
              final t = await _pickTime(_activeFrom);
              if (t != null) setState(() => _activeFrom = t);
            },
            onClear: () => setState(() => _activeFrom = ''),
          ),
          CheckPickerField(
            key: const ValueKey('schedule-form-active-to'),
            label: 'Only until',
            icon: Icons.schedule_rounded,
            value: _activeTo,
            placeholder: '--:--',
            onTap: () async {
              final t = await _pickTime(_activeTo);
              if (t != null) setState(() => _activeTo = t);
            },
            onClear: () => setState(() => _activeTo = ''),
          ),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CheckFieldLabel('Times of day'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < _times.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          key: ValueKey('schedule-form-time-$i'),
                          onTap: () async {
                            final t = await _pickTime(_times[i]);
                            if (t != null) setState(() => _times[i] = t);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.searchBorder),
                            ),
                            child: Text(_times[i], style: handoverText(context, 13)),
                          ),
                        ),
                        if (_times.length > 1)
                          IconButton(
                            key: ValueKey('schedule-form-time-remove-$i'),
                            tooltip: 'Remove ${_times[i]}',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _times.removeAt(i)),
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  HandoverButton(
                    key: const ValueKey('schedule-form-add-time'),
                    label: 'Add a time',
                    compact: true,
                    onPressed: () => setState(() => _times.add('12:00')),
                  ),
                ],
              ),
            ],
          ),
          if (_frequency == 'weekly')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CheckFieldLabel('Days'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (day, label) in CheckLabels.weekdays)
                      CheckToggleChip(
                        key: ValueKey('schedule-form-weekday-$day'),
                        label: label,
                        selected: _weekdays.contains(day),
                        onTap: () => setState(() => _weekdays.contains(day)
                            ? _weekdays.remove(day)
                            : _weekdays.add(day)),
                      ),
                  ],
                ),
              ],
            ),
          if (_frequency == 'monthly')
            CheckInput(
              key: const ValueKey('schedule-form-day-of-month'),
              label: 'Day of the month',
              number: true,
              controller: _dayOfMonth,
              helper: '29-31 fall back to the last day of a short month',
            ),
        ],
        CheckPickerField(
          key: const ValueKey('schedule-form-starts'),
          label: 'Starts',
          value: _startsOn == null ? null : WebFormat.date(_startsOn),
          placeholder: 'dd/mm/yyyy',
          onTap: () async {
            final d = await _pickDate(_startsOn);
            if (d != null) setState(() => _startsOn = d);
          },
          onClear: () => setState(() => _startsOn = null),
        ),
        CheckPickerField(
          key: const ValueKey('schedule-form-stops'),
          label: 'Stops',
          value: _stopsOn == null ? null : WebFormat.date(_stopsOn),
          placeholder: 'dd/mm/yyyy',
          helper: 'Leave empty to keep it running',
          onTap: () async {
            final d = await _pickDate(_stopsOn);
            if (d != null) setState(() => _stopsOn = d);
          },
          onClear: () => setState(() => _stopsOn = null),
        ),
      ];

  List<Widget> _alertFields(BuildContext context) {
    final readings = [
      for (final f in CheckLabels.readingsFor(_checkType)) (f.key, f.labelWithUnit),
    ];
    return [
      CheckSwitchTile(
        key: const ValueKey('schedule-form-alert'),
        label: 'Alert on an abnormal reading',
        description: 'Raises it on the Priority Notes board and notifies the shift.',
        value: _alertEnabled,
        activeColor: AppColors.urgentAmber,
        onChanged: (on) => setState(() {
          _alertEnabled = on;
          if (on && _rules.isEmpty) _rules.add(_RuleDraft());
        }),
      ),
      if (_alertEnabled) ...[
        Text(
          'Any one of these is enough to raise it — “systolic above 140 or diastolic '
          'above 90” is what “above 140/90” means.',
          style: handoverText(context, 12.5, color: AppColors.textMuted),
        ),
        for (var i = 0; i < _rules.length; i++) _ruleRow(context, i, readings),
        Align(
          alignment: Alignment.centerLeft,
          child: HandoverButton(
            key: const ValueKey('schedule-form-add-threshold'),
            label: 'Add a threshold',
            compact: true,
            onPressed: () => setState(() => _rules.add(_RuleDraft())),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CheckFieldLabel('Notify'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (role, label) in CheckLabels.notifyRoles)
                  CheckToggleChip(
                    key: ValueKey('schedule-form-notify-$role'),
                    label: label,
                    selected: _notifyRoles.contains(role),
                    onTap: () => setState(() => _notifyRoles.contains(role)
                        ? _notifyRoles.remove(role)
                        : _notifyRoles.add(role)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'None chosen means the home’s clinical roles.',
              style: handoverText(context, 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    ];
  }

  Widget _ruleRow(BuildContext context, int i, List<(String, String)> readings) {
    final rule = _rules[i];
    final first = i == 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: HandoverSelect(
                  key: ValueKey('rule-field-$i'),
                  label: first ? 'Reading' : '',
                  value: CheckLabels.labelOf(readings, rule.field),
                  placeholder: 'Which field',
                  onTap: () async {
                    final picked = await _pick('Reading', readings, rule.field);
                    if (picked != null) setState(() => rule.field = picked);
                  },
                ),
              ),
              IconButton(
                key: ValueKey('rule-remove-$i'),
                tooltip: 'Remove threshold ${i + 1}',
                onPressed: () => setState(() => _rules.removeAt(i).value.dispose()),
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: HandoverSelect(
                  key: ValueKey('rule-op-$i'),
                  label: first ? 'Is' : '',
                  value: CheckLabels.labelOf(CheckLabels.operators, rule.operator),
                  placeholder: '',
                  onTap: () async {
                    final picked = await _pick('Is', CheckLabels.operators, rule.operator);
                    if (picked != null) setState(() => rule.operator = picked);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CheckInput(
                  key: ValueKey('rule-value-$i'),
                  label: first ? 'Value' : null,
                  controller: rule.value,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HandoverSelect(
            key: ValueKey('rule-severity-$i'),
            label: first ? 'Then' : '',
            value: CheckLabels.labelOf(CheckLabels.severities, rule.severity),
            placeholder: '',
            onTap: () async {
              final picked = await _pick('Then', CheckLabels.severities, rule.severity);
              if (picked != null) setState(() => rule.severity = picked);
            },
          ),
          InkWell(
            key: ValueKey('rule-incident-$i'),
            onTap: () => setState(() => rule.raiseIncident = !rule.raiseIncident),
            child: Row(
              children: [
                Checkbox(
                  value: rule.raiseIncident,
                  onChanged: (v) => setState(() => rule.raiseIncident = v ?? false),
                ),
                Expanded(
                  child: Text(
                    'Also file an incident when this trips',
                    style: handoverText(context, 12.5, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _whoFields(BuildContext context) => [
        HandoverSelect(
          key: const ValueKey('schedule-form-role'),
          label: 'Role',
          value: CheckLabels.labelOf(CheckLabels.roles, _role),
          placeholder: 'Whoever is on shift',
          onTap: () async {
            final picked = await _pick(
                'Role', [('', 'Whoever is on shift'), ...CheckLabels.roles], _role);
            if (picked != null) setState(() => _role = picked);
          },
        ),
        HandoverSelect(
          key: const ValueKey('schedule-form-staff'),
          label: 'Specific person',
          value: _c.staff.where((s) => s.id == _staffId).firstOrNull?.label,
          placeholder: 'Optional',
          helper: 'Leave empty unless one named person owns this check',
          onTap: () async {
            final picked = await _pick(
              'Specific person',
              [('', 'Nobody in particular'), for (final s in _c.staff) (s.id, s.label)],
              _staffId,
            );
            if (picked != null) setState(() => _staffId = picked);
          },
        ),
      ];
}
