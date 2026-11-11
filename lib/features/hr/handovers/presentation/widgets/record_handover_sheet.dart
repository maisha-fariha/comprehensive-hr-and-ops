import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../ai/domain/entities/ai_assist.dart';
import '../../../ai/presentation/widgets/ai_draft_sheet.dart';
import '../../../ai/presentation/widgets/ai_feature_sheets.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../domain/entities/handover_options.dart';
import '../../domain/entities/shift_handover.dart';
import '../controllers/handovers_controller.dart';
import '../handover_labels.dart';
import 'draft_handover_note_sheet.dart';
import 'handover_common.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

Future<void> showRecordHandoverSheet(
  BuildContext context, {
  required HandoversController controller,
  String? initialResidenceId,
  String? initialFromShiftId,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecordHandoverSheet(
      controller: controller,
      initialResidenceId: initialResidenceId,
      initialFromShiftId: initialFromShiftId,
    ),
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

  /// Clock-out `HANDOVER_REQUIRED` opens this form for that shift.
  final String? initialResidenceId;
  final String? initialFromShiftId;

  const RecordHandoverSheet({
    super.key,
    required this.controller,
    this.initialResidenceId,
    this.initialFromShiftId,
  });

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

  /// Web `GET /shift-handovers/prepare` — dynamic notes / tasks / incidents.
  HandoverPrepare? _prepare;
  bool _prepareLoading = false;
  final Set<String> _excludedNoteIds = {};
  final Set<String> _excludedTaskIds = {};
  final Set<String> _excludedIncidentIds = {};

  String? _incomingKey;
  String? _clientsKey;
  String? _prepareKey;
  bool? _aiDraftingEnabled;

  HandoversController get _c => widget.controller;

  String get _pinnedShiftId => widget.initialFromShiftId?.trim() ?? '';

  List<HandoverShift> get _shifts {
    final base = _myShifts.isNotEmpty ? _myShifts : _residenceShifts;
    final pin = _pinnedShiftId;
    if (pin.isEmpty || base.any((s) => s.id == pin)) return base;
    return [
      HandoverShift(
        id: pin,
        residenceId: (widget.initialResidenceId ?? _residenceId).trim(),
        title: 'This shift',
      ),
      ...base,
    ];
  }

  HandoverShift? get _shift => _shifts.where((s) => s.id == _shiftId).firstOrNull;

  String get _effectiveResidence => _shift?.residenceId ?? _residenceId;

  bool get _onBehalf => _myShifts.isEmpty && _residenceShifts.isNotEmpty;

  HandoverShift? get _toShift => _incoming.where((s) => s.id == _toShiftId).firstOrNull;

  @override
  void initState() {
    super.initState();
    final home = widget.initialResidenceId?.trim() ?? '';
    _residenceId = home.isNotEmpty ? home : (_c.residenceId.value ?? '');
    final pin = _pinnedShiftId;
    if (pin.isNotEmpty) _shiftId = pin;
    _loadMyShifts();
    _loadResidenceShifts();
    aiDraftingEnabled().then((enabled) {
      if (!mounted) return;
      setState(() => _aiDraftingEnabled = enabled);
    });
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
    final shiftId = _shiftId;
    if (shiftId != _prepareKey) {
      _prepareKey = shiftId;
      _loadPrepare(shiftId);
    }
  }

  Future<void> _loadPrepare(String shiftId) async {
    if (shiftId.isEmpty) {
      setState(() {
        _prepare = null;
        _prepareLoading = false;
        _excludedNoteIds.clear();
        _excludedTaskIds.clear();
        _excludedIncidentIds.clear();
      });
      return;
    }
    setState(() {
      _prepareLoading = true;
      _excludedNoteIds.clear();
      _excludedTaskIds.clear();
      _excludedIncidentIds.clear();
    });
    final result = await _c.repository.prepare(shiftId);
    if (!mounted || shiftId != _prepareKey) return;
    result.when(
      success: (data) => setState(() {
        _prepare = data;
        _prepareLoading = false;
        // Prefer prepare's incoming list when the API returns it (web).
        if (data.incomingShifts.isNotEmpty) {
          _incoming = [
            for (final s in data.incomingShifts)
              HandoverShift(
                id: s.id,
                residenceId: s.residenceId ?? _effectiveResidence,
                residenceName: s.residenceName,
                title: s.title,
                shiftType: s.shiftType,
                startsAt: s.startsAt,
                endsAt: s.endsAt,
                staff: s.staff,
              ),
          ];
        }
      }),
      failure: (_) => setState(() {
        _prepare = null;
        _prepareLoading = false;
      }),
    );
  }

  List<String> get _selectedEntryIds => [
        for (final n in _prepare?.notesForNextShift ?? const <HandoverNextNote>[])
          if (!_excludedNoteIds.contains(n.id)) n.id,
      ];

  List<String> get _selectedTaskIds => [
        for (final t in _prepare?.unfinishedTasks ?? const <HandoverHandedTask>[])
          if (t.suggested
              ? !_excludedTaskIds.contains(t.id)
              : _excludedTaskIds.contains(t.id))
            t.id,
      ];

  List<String> get _selectedIncidentIds => [
        for (final i in _prepare?.incidents ?? const <HandoverIncident>[])
          if (!_excludedIncidentIds.contains(i.id)) i.id,
      ];

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
    if (_saving) return;
    setState(() => _error = null);
    final residence = _effectiveResidence;
    final summary = _summary.text.trim();
    if (residence.isEmpty || summary.isEmpty) {
      setState(() => _error =
          'Choose the shift you are handing over — or a residence — and write a summary.');
      return;
    }
    setState(() => _saving = true);
    final entryIds = _selectedEntryIds;
    final taskIds = _selectedTaskIds;
    final incidentIds = _selectedIncidentIds;
    final result = await _c.repository.create({
      'residenceId': residence,
      'summary': summary,
      'pendingActions': [for (final job in _jobs) job.toJson()],
      if (_updates.isNotEmpty)
        'clientUpdates': [for (final update in _updates) update.toJson()],
      'status': draft ? 'draft' : 'submitted',
      if (_shiftId.isNotEmpty) 'fromShiftId': _shiftId,
      if (_toShiftId.isNotEmpty) 'toShiftId': _toShiftId,
      if (entryIds.isNotEmpty) 'entryIds': entryIds,
      if (taskIds.isNotEmpty) 'taskIds': taskIds,
      if (incidentIds.isNotEmpty) 'incidentIds': incidentIds,
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

  Future<void> _draftHandoverNote() async {
    final residence = _effectiveResidence;
    if (residence.isEmpty) {
      AppSnackbar.show(
        'Residence required',
        'Choose a shift or residence before drafting.',
        force: true,
      );
      return;
    }
    final draft = await showDraftHandoverNoteSheet(
      context,
      residenceId: residence,
      shiftStartsAt: _shift?.startsAt,
      shiftEndsAt: _shift?.endsAt,
    );
    if (!mounted || draft == null) return;
    _applyAiDraft(draft);
  }

  void _applyAiDraft(AiHandoverDraft draft) {
    const statusRank = ['stable', 'needs_attention', 'urgent'];
    int rank(String status) {
      final i = statusRank.indexOf(status);
      return i < 0 ? 0 : i;
    }

    void fillEmpty(Map<String, String> target, Map<String, String> source) {
      for (final entry in source.entries) {
        final next = entry.value.trim();
        if (next.isEmpty) continue;
        final current = target[entry.key]?.trim() ?? '';
        if (current.isEmpty) target[entry.key] = next;
      }
    }

    setState(() {
      _summary.text = draft.summary;
      for (final action in draft.actions) {
        final title = action.title.trim();
        if (title.isEmpty) continue;
        final exists = _jobs.any(
          (job) => job.title.trim().toLowerCase() == title.toLowerCase(),
        );
        if (!exists) {
          _jobs.add(
            HandoverJobDraft(title: title, priority: action.priority),
          );
        }
      }
      if (_toShiftId.isEmpty && _incoming.isNotEmpty) {
        _toShiftId = _incoming.first.id;
      }
      final flag = draft.flagCategory?.trim() ?? '';
      if (flag.isNotEmpty && _flag.isEmpty) {
        final known = HandoverLabels.flagCategories.any((o) => o.$1 == flag);
        if (known) _flag = flag;
      }
      for (final incoming in draft.clientUpdates) {
        final existingIndex = _updates.indexWhere(
          (u) => u.clientId == incoming.clientId,
        );
        if (existingIndex >= 0) {
          final current = _updates[existingIndex];
          if (rank(incoming.status) > rank(current.status)) {
            current.status = incoming.status;
          }
          fillEmpty(current.health, incoming.health);
          fillEmpty(current.medication, incoming.medication);
          fillEmpty(current.care, incoming.care);
          for (final item in incoming.careCompleted) {
            if (!current.careCompleted.contains(item)) {
              current.careCompleted.add(item);
            }
          }
        } else {
          final created = HandoverClientDraft(
            clientId: incoming.clientId,
            clientName: incoming.clientName,
          )..status = incoming.status;
          created.health.addAll(incoming.health);
          created.medication.addAll(incoming.medication);
          created.care.addAll(incoming.care);
          created.careCompleted.addAll(incoming.careCompleted);
          _updates.add(created);
        }
      }
      if (draft.clientUpdates.isNotEmpty) {
        _expandedClientId = draft.clientUpdates.first.clientId;
      }
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
        if (!handedOver.contains(s.id) || s.id == _pinnedShiftId)
          (s.id, _describe(s, withResidence: true)),
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
                  if (_prepareLoading) ...[
                    gap,
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    ),
                  ],
                  if (_prepare != null) ...[
                    if (_prepare!.incidents.isNotEmpty) ...[
                      gap,
                      _SelectableBundle(
                        key: const ValueKey('record-handover-incidents'),
                        title: 'Incidents on this shift',
                        helper:
                            'Linked to the handover so the incoming shift sees them. Untick any that do not need handing over.',
                        borderColor: AppColors.urgentAmber.withValues(alpha: 0.45),
                        background: AppColors.urgentBackground,
                        children: [
                          for (final incident in _prepare!.incidents)
                            _BundleCheck(
                              key: ValueKey('record-handover-incident-${incident.id}'),
                              selected: !_excludedIncidentIds.contains(incident.id),
                              label: [
                                if ((incident.reference ?? '').isNotEmpty)
                                  '${incident.reference} · ',
                                incident.title ?? 'Untitled incident',
                              ].join(),
                              badge: incident.severity,
                              onToggle: () => setState(() {
                                if (!_excludedIncidentIds.remove(incident.id)) {
                                  _excludedIncidentIds.add(incident.id);
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
                    if (_prepare!.notesForNextShift.isNotEmpty) ...[
                      gap,
                      _SelectableBundle(
                        key: const ValueKey('record-handover-next-notes'),
                        title: 'Notes for the next shift',
                        helper:
                            'Marked by the carers who wrote them. They go with this handover as written; untick one only if you say it yourself above.',
                        borderColor: AppColors.secondaryTeal.withValues(alpha: 0.35),
                        background: AppColors.secondaryTeal.withValues(alpha: 0.06),
                        children: [
                          for (final note in _prepare!.notesForNextShift)
                            _BundleCheck(
                              key: ValueKey('record-handover-note-${note.id}'),
                              selected: !_excludedNoteIds.contains(note.id),
                              label: [
                                if ((note.clientName ?? '').isNotEmpty)
                                  '${note.clientName}: ',
                                note.body,
                              ].join(),
                              onToggle: () => setState(() {
                                if (!_excludedNoteIds.remove(note.id)) {
                                  _excludedNoteIds.add(note.id);
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
                    if (_prepare!.unfinishedTasks.isNotEmpty) ...[
                      gap,
                      _SelectableBundle(
                        key: const ValueKey('record-handover-unfinished'),
                        title: 'Unfinished tasks',
                        helper:
                            "Handed on with this handover — whoever takes it becomes their assignee. Untick any that are not the next shift's to do.",
                        borderColor: AppColors.infoBlue.withValues(alpha: 0.4),
                        background: AppColors.infoBackground,
                        children: [
                          for (final task in _prepare!.unfinishedTasks)
                            _BundleCheck(
                              key: ValueKey('record-handover-task-${task.id}'),
                              selected: task.suggested
                                  ? !_excludedTaskIds.contains(task.id)
                                  : _excludedTaskIds.contains(task.id),
                              label: task.title,
                              badge: task.overdue ? 'Overdue' : null,
                              onToggle: () => setState(() {
                                if (!_excludedTaskIds.remove(task.id)) {
                                  _excludedTaskIds.add(task.id);
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
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
                  if (_aiDraftingEnabled == true) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AiAssistButton(
                        buttonKey: const ValueKey('record-handover-draft-ai'),
                        label: 'Draft handover note',
                        onPressed: _effectiveResidence.isEmpty
                            ? null
                            : _draftHandoverNote,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
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

/// Web prepare bundle (notes / tasks / incidents) with opt-out checkboxes.
class _SelectableBundle extends StatelessWidget {
  final String title;
  final String helper;
  final Color borderColor;
  final Color background;
  final List<Widget> children;

  const _SelectableBundle({
    super.key,
    required this.title,
    required this.helper,
    required this.borderColor,
    required this.background,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: handoverText(context, 12.5, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(helper, style: handoverText(context, 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _BundleCheck extends StatelessWidget {
  final bool selected;
  final String label;
  final String? badge;
  final VoidCallback onToggle;

  const _BundleCheck({
    super.key,
    required this.selected,
    required this.label,
    required this.onToggle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.secondaryTeal,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: handoverText(context, 13)),
            ),
            if ((badge ?? '').isNotEmpty) ...[
              const SizedBox(width: 6),
              AttendancePill(
                label: badge!,
                tone: AttendanceTone.danger,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
