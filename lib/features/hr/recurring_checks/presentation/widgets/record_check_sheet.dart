import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/recurring_check.dart';
import '../controllers/recurring_checks_controller.dart';
import '../recurring_checks_labels.dart';
import 'check_common.dart';

/// "Record check" for an occurrence, or "Record Progress" when [instance]
/// is null (resident and schedule picked in the form).
Future<void> showRecordCheckSheet(
  BuildContext context, {
  required RecurringChecksController controller,
  CheckInstance? instance,
}) =>
    showCheckSheet<void>(
      context,
      (_) => _RecordCheckSheet(controller: controller, instance: instance),
    );

class _RecordCheckSheet extends StatefulWidget {
  final RecurringChecksController controller;
  final CheckInstance? instance;

  const _RecordCheckSheet({required this.controller, this.instance});

  @override
  State<_RecordCheckSheet> createState() => _RecordCheckSheetState();
}

class _RecordCheckSheetState extends State<_RecordCheckSheet> {
  final _note = TextEditingController();
  final _takeover = TextEditingController();
  final Map<String, TextEditingController> _numbers = {};
  final Map<String, String> _selects = {};

  String? _clientId;
  String? _scheduleId;
  String? _recordedBy;
  String _outcome = 'normal';
  String? _error;
  bool _saving = false;

  String? _openResidenceId;
  List<CheckSchedule> _clientSchedules = const [];
  bool _schedulesLoading = false;
  int _scheduleSerial = 0;

  RecurringChecksController get _c => widget.controller;
  CheckInstance? get _instance => widget.instance;
  bool get _standalone => _instance == null;

  @override
  void initState() {
    super.initState();
    if (!_standalone) _loadAttendance();
  }

  @override
  void dispose() {
    _note.dispose();
    _takeover.dispose();
    for (final c in _numbers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    final result = await _c.repository.openAttendanceResidenceId();
    if (!mounted) return;
    result.when(success: (id) => setState(() => _openResidenceId = id), failure: (_) {});
  }

  Future<void> _pickClient() async {
    final picked = await pickHandoverOption(
      context,
      title: 'Resident',
      options: [for (final c in _c.allClients) (c.id, c.label)],
      selected: _clientId,
    );
    if (picked == null || picked == _clientId) return;
    setState(() {
      _clientId = picked;
      _scheduleId = null;
      _clientSchedules = const [];
      _schedulesLoading = true;
      _resetReadings();
    });
    final serial = ++_scheduleSerial;
    final result = await _c.repository.clientSchedules(picked);
    if (!mounted || serial != _scheduleSerial) return;
    setState(() {
      _clientSchedules = result.when(success: (s) => s, failure: (_) => const []);
      _schedulesLoading = false;
    });
  }

  void _resetReadings() {
    for (final c in _numbers.values) {
      c.clear();
    }
    _selects.clear();
  }

  /// Picked schedule, or the only one when the resident has just one.
  String? get _effectiveScheduleId =>
      _scheduleId ?? (_clientSchedules.length == 1 ? _clientSchedules.first.id : null);

  CheckSchedule? get _schedule =>
      _clientSchedules.where((s) => s.id == _effectiveScheduleId).firstOrNull;

  String get _checkType =>
      (_standalone ? _schedule?.checkType : _instance!.checkType) ?? '';

  String? get _instructions => _standalone ? _schedule?.instructions : _instance!.instructions;

  static String _scheduleLabel(CheckSchedule s) => s.name != null
      ? '${s.name} (${s.checkType ?? CheckLabels.describeFrequency(s)})'
      : s.checkType ?? 'Routine check';

  String? get _actingStaffId => _recordedBy ?? _c.myStaffId;

  bool get _onBehalf =>
      _instance?.assignedStaffId != null &&
      _actingStaffId != null &&
      _instance!.assignedStaffId != _actingStaffId;

  bool get _blocked => _onBehalf && !_c.canManage;

  bool get _notClockedHere =>
      _instance != null &&
      _instance!.residenceId.isNotEmpty &&
      _openResidenceId != _instance!.residenceId;

  bool get _showRecordedBy => _standalone && _c.myStaffId == null && _c.staff.isNotEmpty;

  String get _assignee => _instance?.assignedStaffName ?? 'somebody else';

  Future<void> _submit() async {
    setState(() => _error = null);
    final clientId = _standalone ? _clientId : _instance!.clientId;
    if (clientId == null || clientId.isEmpty) {
      return setState(() => _error = 'Please select the resident you are recording for.');
    }
    final scheduleId = _standalone ? _effectiveScheduleId : _instance!.scheduleId;
    if (scheduleId == null || scheduleId.isEmpty) {
      return setState(() => _error =
          'A recurring check schedule is required to record progress. Please select a check schedule.');
    }
    final note = _note.text.trim();
    if (note.isEmpty) {
      return setState(
          () => _error = 'Say what you saw — a tick with nothing written is not evidence.');
    }
    if (_blocked) {
      return setState(() =>
          _error = 'This check is assigned to $_assignee. Reassign it first, then record it.');
    }
    final takeover = _takeover.text.trim();
    if (_onBehalf && takeover.isEmpty) {
      return setState(() =>
          _error = 'This check is assigned to $_assignee — say why you are recording it for them.');
    }
    final result = <String, Object>{};
    for (final field in CheckLabels.readingsFor(_checkType)) {
      final raw = field.isSelect ? _selects[field.key] : _numbers[field.key]?.text;
      if (raw == null || raw.isEmpty) continue;
      final Object? value = field.isSelect ? raw : num.tryParse(raw);
      if (value == null) continue;
      result[field.key] = value;
      if (field.unit != null) result['${field.key}Unit'] = field.unit!;
    }
    setState(() => _saving = true);
    try {
      await _c.recordEntry({
        'scheduleId': scheduleId,
        'instanceId': ?_instance?.id,
        'clientId': clientId,
        'staffId': ?_recordedBy,
        'checkedAt': DateTime.now().toUtc().toIso8601String(),
        'note': note,
        if (result.isNotEmpty) 'result': result,
        'outcome': _outcome,
        if (_onBehalf) 'takeoverReason': takeover,
      }, outcome: _outcome);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = _instance;
    final bodyStyle = handoverText(context, 12.5);
    final bold = handoverText(context, 12.5, weight: FontWeight.w600);
    final disabled = _saving || _blocked || (_standalone && (_clientId == null || _effectiveScheduleId == null));
    return CheckSheetScaffold(
      icon: Icons.assignment_turned_in_outlined,
      title: i == null ? 'Record Progress' : (i.checkName ?? 'Record check'),
      description: i == null
          ? 'Record a resident welfare observation, vital check, or care progress'
          : '${i.clientName ?? 'Resident'} · due ${WebFormat.dateTime(i.dueAt.toLocal())}',
      primaryKey: const ValueKey('record-check-submit'),
      primaryLabel: _saving ? 'Recording…' : (_standalone ? 'Record progress' : 'Record check'),
      onPrimary: disabled ? null : _submit,
      children: [
        if (_error != null)
          CheckNotice(
            child: Text(_error!,
                style: handoverText(context, 13.5, color: AppColors.criticalRed)),
          ),
        if (_notClockedHere)
          CheckNotice(
            color: AppColors.urgentAmber,
            bordered: true,
            child: Text(
              'You are not clocked in at this home. A check here can only be recorded on '
              'duty — clock in and try again, or ask a manager to record it for you.',
              style: handoverText(context, 13),
            ),
          ),
        if (_standalone) _standaloneBlock(context),
        if (_instructions != null && _instructions!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INSTRUCTIONS',
                    style: handoverText(context, 11.5,
                        weight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(_instructions!, style: handoverText(context, 13)),
              ],
            ),
          ),
        for (final field in CheckLabels.readingsFor(_checkType))
          field.isSelect
              ? HandoverSelect(
                  key: ValueKey('record-reading-${field.key}'),
                  label: field.label,
                  value: CheckLabels.labelOf(field.options!, _selects[field.key] ?? ''),
                  placeholder: 'Select',
                  onTap: () async {
                    final picked = await pickHandoverOption(
                      context,
                      title: field.label,
                      options: field.options!,
                      selected: _selects[field.key],
                    );
                    if (picked != null) setState(() => _selects[field.key] = picked);
                  },
                )
              : CheckInput(
                  key: ValueKey('record-reading-${field.key}'),
                  label: field.labelWithUnit,
                  number: true,
                  controller: _numbers.putIfAbsent(field.key, TextEditingController.new),
                ),
        if (_blocked)
          CheckNotice(
            bordered: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'This check is assigned to '),
                    TextSpan(text: _assignee, style: bold),
                    const TextSpan(text: '.'),
                  ]),
                  style: bodyStyle,
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(
                        text: 'It has to be reassigned before you can record it. Close this and use '),
                    TextSpan(text: 'Reassign', style: bold),
                    const TextSpan(text: ' on the check.'),
                  ]),
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        if (_onBehalf && !_blocked)
          CheckNotice(
            color: AppColors.urgentAmber,
            bordered: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'This check is assigned to '),
                    TextSpan(text: _assignee, style: bold),
                    const TextSpan(text: '. You are recording it on their behalf.'),
                  ]),
                  style: bodyStyle,
                ),
                const SizedBox(height: 8),
                HandoverTextArea(
                  key: const ValueKey('record-check-takeover'),
                  label: 'Why are you recording it for them?',
                  required: true,
                  controller: _takeover,
                  placeholder: 'They are on their break…',
                ),
              ],
            ),
          ),
        HandoverTextArea(
          key: const ValueKey('record-check-note'),
          label: 'What you saw',
          required: true,
          controller: _note,
          placeholder: 'Sleeping, settled, no concerns…',
        ),
        HandoverSelect(
          key: const ValueKey('record-check-outcome'),
          label: 'Outcome',
          value: CheckLabels.outcome(_outcome),
          placeholder: '',
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: 'Outcome',
              options: CheckLabels.outcomes,
              selected: _outcome,
            );
            if (picked != null) setState(() => _outcome = picked);
          },
        ),
        if (_outcome != 'normal')
          Row(
            children: [
              const AttendancePill(label: 'Stays open', tone: AttendanceTone.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This check will sit in Requires review rather than being closed.',
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _standaloneBlock(BuildContext context) {
    final clientLabel =
        _c.allClients.where((c) => c.id == _clientId).firstOrNull?.label;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HandoverSelect(
            key: const ValueKey('record-check-resident'),
            label: 'Resident',
            required: true,
            value: clientLabel,
            placeholder: 'Select resident you are recording for',
            onTap: _pickClient,
          ),
          if (_clientId != null) ...[
            const SizedBox(height: 12),
            if (_schedulesLoading)
              Text('Loading resident check schedules…',
                  style: handoverText(context, 12, color: AppColors.textMuted))
            else if (_clientSchedules.isNotEmpty)
              HandoverSelect(
                key: const ValueKey('record-check-schedule'),
                label: 'Check / Schedule',
                required: true,
                value: _schedule == null ? null : _scheduleLabel(_schedule!),
                placeholder: 'Select check schedule',
                onTap: () async {
                  final picked = await pickHandoverOption(
                    context,
                    title: 'Check / Schedule',
                    options: [for (final s in _clientSchedules) (s.id, _scheduleLabel(s))],
                    selected: _effectiveScheduleId,
                  );
                  if (picked != null) {
                    setState(() {
                      _scheduleId = picked;
                      _resetReadings();
                    });
                  }
                },
              )
            else
              CheckNotice(
                color: AppColors.urgentAmber,
                bordered: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.urgentAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No active recurring check schedule for this resident',
                              style: handoverText(context, 12,
                                  weight: FontWeight.w600, color: AppColors.urgentAmber)),
                          const SizedBox(height: 2),
                          Text(
                            'The server currently requires an existing recurring check schedule '
                            'to file a check entry. Please create a schedule first or select a '
                            'resident with standing instructions.',
                            style: handoverText(context, 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (_showRecordedBy) ...[
            const SizedBox(height: 12),
            HandoverSelect(
              key: const ValueKey('record-check-recorded-by'),
              label: 'Recorded by Staff',
              value: _c.staff.where((s) => s.id == _recordedBy).firstOrNull?.label,
              placeholder: 'Select staff member',
              helper: 'Your login is an administrator account — specify who carried out the check.',
              onTap: () async {
                final picked = await pickHandoverOption(
                  context,
                  title: 'Recorded by Staff',
                  options: [for (final s in _c.staff) (s.id, s.label)],
                  selected: _recordedBy,
                );
                if (picked != null) setState(() => _recordedBy = picked);
              },
            ),
          ],
        ],
      ),
    );
  }
}
