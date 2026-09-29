import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../domain/entities/handover_options.dart';
import '../controllers/handovers_controller.dart';
import '../handover_labels.dart';
import 'handover_common.dart';

Future<void> showRecordHandoverSheet(
  BuildContext context, {
  required HandoversController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecordHandoverSheet(controller: controller),
  );
}

String _describe(HandoverShift s, {bool withResidence = false}) =>
    WebFormat.describeShift(
      shiftType: s.shiftType,
      title: s.title,
      startsAt: s.startsAt,
      endsAt: s.endsAt,
      staffNames: s.rosteredNames,
      residenceName: s.residenceName,
      withResidence: withResidence,
    );

/// The web "Record handover" modal.
class RecordHandoverSheet extends StatefulWidget {
  final HandoversController controller;

  const RecordHandoverSheet({super.key, required this.controller});

  @override
  State<RecordHandoverSheet> createState() => _RecordHandoverSheetState();
}

class _RecordHandoverSheetState extends State<RecordHandoverSheet> {
  final _summary = TextEditingController();
  final _jobTitle = TextEditingController();

  String _residenceId = '';
  String _shiftId = '';
  String _toShiftId = '';
  String _flag = '';
  String _jobPriority = 'normal';
  String? _expandedClientId;
  String? _error;
  bool _saving = false;

  List<HandoverShift> _myShifts = const [];
  List<HandoverShift> _residenceShifts = const [];
  List<HandoverShift> _incoming = const [];
  List<HandoverOption> _clients = const [];
  final List<HandoverJobDraft> _jobs = [];
  final List<HandoverClientDraft> _updates = [];

  String? _incomingKey;
  String? _clientsKey;

  HandoversController get _c => widget.controller;

  List<HandoverShift> get _shifts => _myShifts.isNotEmpty ? _myShifts : _residenceShifts;

  HandoverShift? get _shift => _shifts.where((s) => s.id == _shiftId).firstOrNull;

  String get _effectiveResidence => _shift?.residenceId ?? _residenceId;

  bool get _onBehalf => _myShifts.isEmpty && _residenceShifts.isNotEmpty;

  HandoverShift? get _toShift => _incoming.where((s) => s.id == _toShiftId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _residenceId = _c.residenceId.value ?? '';
    _loadMyShifts();
    _loadResidenceShifts();
  }

  @override
  void dispose() {
    _summary.dispose();
    _jobTitle.dispose();
    super.dispose();
  }

  bool get _canReadShifts => _c.session.can('scheduling:read');

  Future<void> _loadMyShifts() async {
    final staffId = _c.session.staffId;
    if (!_canReadShifts || staffId == null || staffId.isEmpty) return;
    final result = await _c.repository.myRecentShifts(staffId);
    if (!mounted) return;
    result.when(success: (s) => setState(() => _myShifts = s), failure: (_) {});
    _refreshDependents();
  }

  Future<void> _loadResidenceShifts() async {
    final residenceId = _residenceId;
    if (!_canReadShifts || residenceId.isEmpty) {
      setState(() => _residenceShifts = const []);
      _refreshDependents();
      return;
    }
    final result = await _c.repository.residenceRecentShifts(residenceId);
    if (!mounted || residenceId != _residenceId) return;
    result.when(success: (s) => setState(() => _residenceShifts = s), failure: (_) {});
    _refreshDependents();
  }

  /// Incoming shifts and residents follow the effective residence.
  void _refreshDependents() {
    final residence = _effectiveResidence;
    final after = _shift?.endsAt;
    final incomingKey = '$residence|${after?.toIso8601String()}';
    if (incomingKey != _incomingKey) {
      _incomingKey = incomingKey;
      _loadIncoming(residence, after, incomingKey);
    }
    if (residence != _clientsKey) {
      _clientsKey = residence;
      _loadClients(residence);
    }
  }

  Future<void> _loadIncoming(String residence, DateTime? after, String key) async {
    if (!_canReadShifts || residence.isEmpty) {
      setState(() => _incoming = const []);
      return;
    }
    final result = await _c.repository.incomingShifts(residence, after);
    if (!mounted || key != _incomingKey) return;
    result.when(success: (s) => setState(() => _incoming = s), failure: (_) {});
  }

  Future<void> _loadClients(String residence) async {
    if (residence.isEmpty) {
      setState(() => _clients = const []);
      return;
    }
    final result = await _c.repository.clients(residence);
    if (!mounted || residence != _clientsKey) return;
    result.when(success: (c) => setState(() => _clients = c), failure: (_) {});
  }

  Future<void> _save({required bool draft}) async {
    setState(() => _error = null);
    final residence = _effectiveResidence;
    final summary = _summary.text.trim();
    if (residence.isEmpty || summary.isEmpty) {
      setState(() => _error =
          'Choose the shift you are handing over — or a residence — and write a summary.');
      return;
    }
    setState(() => _saving = true);
    final result = await _c.repository.create({
      'residenceId': residence,
      'summary': summary,
      'pendingActions': [for (final job in _jobs) job.toJson()],
      if (_updates.isNotEmpty)
        'clientUpdates': [for (final update in _updates) update.toJson()],
      'status': draft ? 'draft' : 'submitted',
      if (_shiftId.isNotEmpty) 'fromShiftId': _shiftId,
      if (_toShiftId.isNotEmpty) 'toShiftId': _toShiftId,
      if (_flag.isNotEmpty) 'flagForAttention': {'category': _flag},
    });
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (announced) {
        if (announced?.mode == 'shift') {
          AppSnackbar.show('Handed to ${announced!.recipients} on the incoming shift', '');
        } else if (_toShiftId.isNotEmpty) {
          AppSnackbar.show(
            'Nobody on that shift has a login, so this went to everyone in the house.',
            '',
          );
        } else {
          AppSnackbar.show('Handover recorded — everyone in the house was told', '');
        }
        Navigator.of(context).pop();
        _c.load();
      },
      failure: (error) => setState(() => _error = error.message),
    );
  }

  void _addJob() {
    final title = _jobTitle.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _jobs.add(HandoverJobDraft(title: title, priority: _jobPriority));
      _jobTitle.clear();
      _jobPriority = 'normal';
    });
  }

  String _appliesHelper() {
    final to = _toShift;
    if (to == null) {
      return 'Without this it is announced to everyone in the house, and the '
          'outstanding jobs belong to nobody.';
    }
    final names = to.rosteredNames;
    final who = names.isEmpty
        ? 'whoever is in the house — nobody is rostered on it'
        : names.length == 1
            ? names.first
            : '${names.first} and ${names.length - 1} other${names.length == 2 ? '' : 's'}';
    return '$who will see it when they clock in, and the outstanding jobs are theirs.';
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    final residence = _effectiveResidence;
    final handedOver = _c.myHandedOverShiftIds;
    final shiftOptions = [
      for (final s in _shifts)
        if (!handedOver.contains(s.id)) (s.id, _describe(s, withResidence: true)),
    ];
    final incomingOptions = [for (final s in _incoming) (s.id, _describe(s))];
    final availableClients = [
      for (final c in _clients)
        if (!_updates.any((u) => u.clientId == c.id)) (c.id, c.label),
    ];
    final shift = _shift;
    String labelOf(List<(String, String)> options, String id) =>
        options.where((o) => o.$1 == id).firstOrNull?.$2 ?? '';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.94,
        decoration: const BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const _SheetHeader(),
            Expanded(
              child: ListView(
                key: const ValueKey('record-handover-list'),
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  14 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                children: [
                  if (_error != null) ...[
                    Container(
                      key: const ValueKey('record-handover-error'),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.criticalBackgroundSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: handoverText(context, 13.5, color: AppColors.criticalRed),
                      ),
                    ),
                    gap,
                  ],
                  if (_myShifts.isEmpty) ...[
                    HandoverSelect(
                      key: const ValueKey('record-handover-residence'),
                      label: 'Residence',
                      required: true,
                      value: _c.residences
                          .where((r) => r.id == _residenceId)
                          .firstOrNull
                          ?.label,
                      placeholder: 'Choose a residence',
                      helper:
                          'You have no shifts of your own in the last day, so name the home.',
                      onTap: () async {
                        final picked = await pickHandoverOption(
                          context,
                          title: 'Residence',
                          options: [for (final r in _c.residences) (r.id, r.label)],
                          selected: _residenceId,
                        );
                        if (picked == null) return;
                        setState(() {
                          _residenceId = picked;
                          _shiftId = '';
                          _toShiftId = '';
                        });
                        _loadResidenceShifts();
                      },
                    ),
                    gap,
                  ],
                  HandoverSelect(
                    key: const ValueKey('record-handover-shift'),
                    label: _onBehalf
                        ? 'Which shift is this handover about?'
                        : 'The shift you are handing over',
                    value: labelOf(shiftOptions, _shiftId),
                    placeholder: shiftOptions.isNotEmpty
                        ? (_onBehalf
                            ? 'Choose the shift that just ended'
                            : 'Choose the shift you just worked')
                        : (_residenceId.isNotEmpty
                            ? 'No shifts at this home in the last day'
                            : 'Choose a residence above'),
                    helper: _onBehalf
                        ? "This home's shifts from the last 24 hours, with who worked "
                            'them — you are recording on their behalf.'
                        : 'Your own shifts from the last 24 hours.',
                    onTap: shiftOptions.isEmpty
                        ? null
                        : () async {
                            final picked = await pickHandoverOption(
                              context,
                              title: 'Shift',
                              options: shiftOptions,
                              selected: _shiftId,
                            );
                            if (picked == null) return;
                            setState(() {
                              _shiftId = picked;
                              _toShiftId = '';
                            });
                            _refreshDependents();
                          },
                  ),
                  if (shift != null) ...[
                    const SizedBox(height: 10),
                    HandoverPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Term(label: 'Residence', value: shift.residenceName),
                          const SizedBox(height: 10),
                          _Term(label: 'Handing over', value: _describe(shift)),
                        ],
                      ),
                    ),
                  ],
                  gap,
                  HandoverSelect(
                    key: const ValueKey('record-handover-applies'),
                    label: 'Applies to shift',
                    value: labelOf(incomingOptions, _toShiftId),
                    placeholder: residence.isEmpty
                        ? 'Choose a shift or a residence first'
                        : (incomingOptions.isNotEmpty
                            ? 'The shift coming on'
                            : 'No shift is rostered after this one'),
                    helper: _appliesHelper(),
                    onTap: residence.isEmpty || incomingOptions.isEmpty
                        ? null
                        : () async {
                            final picked = await pickHandoverOption(
                              context,
                              title: 'Applies to shift',
                              options: incomingOptions,
                              selected: _toShiftId,
                            );
                            if (picked != null) setState(() => _toShiftId = picked);
                          },
                  ),
                  gap,
                  HandoverTextArea(
                    key: const ValueKey('record-handover-summary'),
                    label: 'Summary',
                    required: true,
                    minLines: 3,
                    placeholder: 'How the shift went, what is outstanding…',
                    controller: _summary,
                  ),
                  gap,
                  _jobsSection(context),
                  gap,
                  Text(
                    'Client updates${_updates.isEmpty ? '' : ' (${_updates.length})'}',
                    style: handoverText(context, 13, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  HandoverSelect(
                    key: const ValueKey('record-handover-add-client'),
                    label: '',
                    value: null,
                    placeholder: residence.isEmpty
                        ? 'Choose a shift or residence first'
                        : availableClients.isEmpty
                            ? 'Every resident here is already on this handover'
                            : _updates.isNotEmpty
                                ? 'Add another resident'
                                : 'Add a resident to this handover',
                    onTap: residence.isEmpty || availableClients.isEmpty
                        ? null
                        : () async {
                            final picked = await pickHandoverOption(
                              context,
                              title: 'Resident',
                              options: availableClients,
                            );
                            if (picked == null) return;
                            setState(() {
                              _updates.add(HandoverClientDraft(
                                clientId: picked,
                                clientName: labelOf(availableClients, picked),
                              ));
                              _expandedClientId = picked;
                            });
                          },
                  ),
                  for (final update in _updates) ...[
                    const SizedBox(height: 10),
                    _ClientUpdateCard(
                      key: ValueKey('record-handover-client-${update.clientId}'),
                      update: update,
                      expanded: _expandedClientId == update.clientId,
                      onToggle: () => setState(() => _expandedClientId =
                          _expandedClientId == update.clientId ? null : update.clientId),
                      onChanged: () => setState(() {}),
                      onRemove: () => setState(() => _updates.remove(update)),
                    ),
                  ],
                  gap,
                  HandoverSelect(
                    key: const ValueKey('record-handover-flag'),
                    label: 'Flag for attention',
                    value: labelOf(HandoverLabels.flagCategories, _flag),
                    placeholder: 'Not flagged',
                    onTap: () async {
                      final picked = await pickHandoverOption(
                        context,
                        title: 'Flag for attention',
                        options: HandoverLabels.flagCategories,
                        selected: _flag,
                      );
                      if (picked != null) setState(() => _flag = picked);
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  HandoverButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  HandoverButton(
                    key: const ValueKey('record-handover-draft'),
                    label: 'Save draft',
                    onPressed: _saving ? null : () => _save(draft: true),
                  ),
                  HandoverButton(
                    key: const ValueKey('record-handover-submit'),
                    label: _saving ? 'Saving…' : 'Submit handover',
                    filled: true,
                    onPressed: _saving ? null : () => _save(draft: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Outstanding jobs', style: handoverText(context, 13, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        for (var i = 0; i < _jobs.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                AttendancePill(
                  label: HandoverLabels.jobPriorities
                      .firstWhere((p) => p.$1 == _jobs[i].priority)
                      .$2,
                  tone: HandoverLabels.jobTone(_jobs[i].priority),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _jobs[i].title,
                    overflow: TextOverflow.ellipsis,
                    style: handoverText(context, 13),
                  ),
                ),
                InkWell(
                  key: ValueKey('record-handover-job-remove-$i'),
                  onTap: () => setState(() => _jobs.removeAt(i)),
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        TextField(
          key: const ValueKey('record-handover-job-input'),
          controller: _jobTitle,
          onSubmitted: (_) => _addJob(),
          style: handoverText(context, 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'e.g. Monitor temperature',
            hintStyle: handoverText(context, 13, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (value, label) in HandoverLabels.jobPriorities)
              _PriorityChip(
                key: ValueKey('record-handover-priority-$value'),
                label: label,
                selected: _jobPriority == value,
                onTap: () => setState(() => _jobPriority = value),
              ),
            HandoverButton(
              key: const ValueKey('record-handover-job-add'),
              label: 'Add',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: _addJob,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Each becomes a task at that priority, assigned to the incoming shift if you name one.',
          style: handoverText(context, 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.activeBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_note_rounded, color: AppColors.secondaryTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record handover', style: handoverText(context, 17, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'What the next shift needs to know before it starts.',
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Term extends StatelessWidget {
  final String label;
  final String? value;

  const _Term({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted)
              .copyWith(letterSpacing: 0.6),
        ),
        const SizedBox(height: 2),
        Text(
          (value ?? '').isEmpty ? '—' : value!,
          style: handoverText(context, 13),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.activeBackground : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.secondaryTeal : AppColors.searchBorder,
          ),
        ),
        child: Text(
          label,
          style: handoverText(
            context,
            12,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.secondaryTeal : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _ClientUpdateCard extends StatefulWidget {
  final HandoverClientDraft update;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ClientUpdateCard({
    super.key,
    required this.update,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_ClientUpdateCard> createState() => _ClientUpdateCardState();
}

class _ClientUpdateCardState extends State<_ClientUpdateCard> {
  static const _health = [
    ('generalCondition', 'General condition', null),
    ('mood', 'Mood', null),
    ('behaviourChanges', 'Behaviour changes', null),
    ('painDiscomfort', 'Pain or discomfort', null),
    ('vitalNotes', 'Vital notes', null),
  ];
  static const _medication = [
    ('administered', 'Administered', null),
    ('missed', 'Missed', 'What was not given, and why.'),
    ('prnGiven', 'PRN given', null),
    ('sideEffects', 'Side effects', null),
    ('specialInstructions', 'Special instructions', null),
  ];
  static const _care = [
    ('otherCompleted', 'Anything else completed', null),
    ('pending', 'Still to do', null),
    ('followUpRequired', 'Follow-up required', null),
  ];

  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controller(Map<String, String> target, String key) =>
      _controllers.putIfAbsent('${identityHashCode(target)}-$key', () {
        return TextEditingController(text: target[key] ?? '');
      });

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Widget> _fields(
    BuildContext context,
    Map<String, String> target,
    List<(String, String, String?)> fields,
  ) =>
      [
        for (final (key, label, helper) in fields) ...[
          HandoverTextArea(
            key: ValueKey('client-${widget.update.clientId}-$key'),
            label: label,
            helper: helper,
            minLines: 1,
            controller: _controller(target, key),
            onChanged: (v) {
              target[key] = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),
        ],
      ];

  @override
  Widget build(BuildContext context) {
    final update = widget.update;
    final tone = HandoverLabels.clientTone(update.status);
    final border = switch (tone) {
      AttendanceTone.warning => AppColors.urgentAmber.withValues(alpha: 0.5),
      AttendanceTone.danger => AppColors.criticalRed.withValues(alpha: 0.6),
      _ => AppColors.cardBorder,
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onToggle,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                update.clientName,
                                overflow: TextOverflow.ellipsis,
                                style: handoverText(
                                  context,
                                  14,
                                  weight: FontWeight.w600,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              Text(
                                HandoverLabels.clientStatus(update.status),
                                style: handoverText(context, 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: widget.expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove ${update.clientName}',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (widget.expanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.scaffoldBackground,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HandoverSelect(
                    key: ValueKey('client-${update.clientId}-status'),
                    label: 'How are they?',
                    required: true,
                    value: HandoverLabels.clientStatus(update.status),
                    placeholder: 'Stable',
                    helper: 'Anything but stable is counted on the handover card.',
                    onTap: () async {
                      final picked = await pickHandoverOption(
                        context,
                        title: 'How are they?',
                        options: HandoverLabels.clientStatuses,
                        selected: update.status,
                      );
                      if (picked == null) return;
                      update.status = picked;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: 16),
                  _GroupTitle('Health'),
                  ..._fields(context, update.health, _health),
                  const SizedBox(height: 6),
                  _GroupTitle('Medication'),
                  ..._fields(context, update.medication, _medication),
                  const SizedBox(height: 6),
                  _GroupTitle('Care'),
                  Text(
                    'Completed this shift',
                    style: handoverText(context, 13, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  for (final (value, label) in HandoverLabels.careTasks)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: CheckboxListTile(
                        key: ValueKey('client-${update.clientId}-care-$value'),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.secondaryTeal,
                        value: update.careCompleted.contains(value),
                        title: Text(label, style: handoverText(context, 13)),
                        onChanged: (on) {
                          on == true
                              ? update.careCompleted.add(value)
                              : update.careCompleted.remove(value);
                          widget.onChanged();
                        },
                      ),
                    ),
                  const SizedBox(height: 6),
                  ..._fields(context, update.care, _care),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String text;

  const _GroupTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: handoverText(context, 12.5, weight: FontWeight.w700)),
      );
}
