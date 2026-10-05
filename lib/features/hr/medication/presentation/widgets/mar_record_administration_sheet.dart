import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/mar_administration.dart';
import '../../domain/entities/mar_options.dart';
import '../controllers/medication_controller.dart';
import '../mar_row.dart';
import '../medication_labels.dart';
import 'medication_common.dart';

/// Picks evidence files; returns an empty list when cancelled.
typedef MarEvidencePicker = Future<List<MarEvidenceFile>> Function();

const int _maxEvidenceBytes = 15 * 1024 * 1024;

Future<List<MarEvidenceFile>> _pickEvidence() async {
  final picked = await FilePicker.platform.pickFiles(allowMultiple: true);
  return [
    for (final f in picked?.files ?? const <PlatformFile>[])
      if (f.path != null && f.size <= _maxEvidenceBytes) MarEvidenceFile(path: f.path!, name: f.name),
  ];
}

/// Web "Record Administration": one resident, any number of medicines, in
/// three steps. [entries] lock the first medicine to the row it was opened
/// from (View, the row icon, or Due Now).
Future<void> showMarRecordAdministrationSheet(
  BuildContext context, {
  required MedicationController controller,
  List<MarRow> entries = const [],
  bool prn = false,
  MarEvidencePicker? pickEvidence,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.94,
        child: MarRecordAdministrationForm(
          controller: controller,
          entries: entries,
          prn: prn,
          pickEvidence: pickEvidence ?? _pickEvidence,
        ),
      ),
    );

class _Item {
  String recordType;
  String medicationId = '';
  String medicationName = '';
  String dosage = '';
  String scheduledTime = '';
  bool isControlled = false;
  String status = 'administered';
  String doseReason = '';
  String witness = '';
  final clinical = TextEditingController();
  final notes = TextEditingController();
  List<MarEvidenceFile> evidence = [];

  _Item(this.recordType);

  factory _Item.fromRow(MarRow r) => _Item(r.recordType)
    ..medicationId = r.medicationId
    ..medicationName = r.medication
    ..dosage = r.dosage
    ..scheduledTime = r.isPrn ? '' : r.scheduleTime
    ..isControlled = r.isControlled;

  bool get isPrn => recordType == 'PRN';

  void dispose() {
    clinical.dispose();
    notes.dispose();
  }

  MarRoundItem toDraft() => MarRoundItem(
        recordType: recordType,
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        isControlled: isControlled,
        status: status,
        doseReason: doseReason,
        witnessStaffId: witness,
        clinicalNotes: clinical.text.trim(),
        notes: notes.text.trim(),
        evidence: evidence,
      );
}

class MarRecordAdministrationForm extends StatefulWidget {
  final MedicationController controller;
  final List<MarRow> entries;
  final bool prn;
  final MarEvidencePicker pickEvidence;

  const MarRecordAdministrationForm({
    super.key,
    required this.controller,
    this.entries = const [],
    this.prn = false,
    required this.pickEvidence,
  });

  @override
  State<MarRecordAdministrationForm> createState() => _MarRecordAdministrationFormState();
}

class _MarRecordAdministrationFormState extends State<MarRecordAdministrationForm> {
  MedicationController get _c => widget.controller;
  bool get _locked => widget.entries.isNotEmpty;

  int _step = 0;
  String _clientId = '';
  String _residenceId = '';
  String _residentName = '';
  late DateTime _date;
  late TimeOfDay _time;
  late String _staffId = _c.ownStaffId;
  final Map<String, bool> _checks = {
    'safetyConfirmed': false,
    for (final (field, _, _) in MedicationLabels.safetyChecks) field: false,
  };
  final Map<String, TextEditingController> _vitals = {
    for (final (field, _, _) in MedicationLabels.vitals) field: TextEditingController(),
  };
  late List<_Item> _items;
  List<MarOption> _witnesses = const [];
  bool _witnessesLoaded = false;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _time = TimeOfDay(hour: now.hour, minute: now.minute);
    if (_locked) {
      final first = widget.entries.first;
      _clientId = first.clientId;
      _residenceId = first.residenceId;
      _residentName = first.residentName;
      _items = [for (final e in widget.entries) _Item.fromRow(e)];
      _loadWitnesses();
    } else {
      _items = [_Item(widget.prn ? 'PRN' : 'MAR')];
    }
  }

  @override
  void dispose() {
    for (final i in _items) {
      i.dispose();
    }
    for (final v in _vitals.values) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _loadWitnesses() async {
    final residence = _residenceId;
    _witnessesLoaded = false;
    final list = await _c.witnessesFor(residence);
    if (!mounted || residence != _residenceId) return;
    setState(() {
      _witnesses = list;
      _witnessesLoaded = residence.isNotEmpty;
    });
  }

  List<MarChoice> get _residentOptions => [for (final c in _c.clients) (c.id, c.name)];

  List<MarChoice> get _staffOptions => [for (final s in _c.staff) (s.id, s.label)];

  List<MarChoice> get _witnessOptions => [
        for (final w in (_witnessesLoaded ? _witnesses : _c.staff))
          if (w.id != _staffId) (w.id, w.label),
      ];

  List<MarMedicationChoice> get _choices => _clientId.isEmpty
      ? const []
      : _c.medicationChoices
          .where((m) => m.clientId == _clientId || (m.clientId.isEmpty && m.residenceId == _residenceId))
          .toList();

  List<String> get _allergies {
    for (final r in [...widget.entries, ..._c.marRows]) {
      if (r.clientId == _clientId && r.allergies.isNotEmpty) return r.allergies;
    }
    return const [];
  }

  String get _staffName =>
      _c.staff.where((s) => s.id == _staffId).map((s) => s.label).firstOrNull ?? '—';

  void _setResident(String id) {
    final previous = _clientId;
    final client = _c.clients.where((c) => c.id == id).firstOrNull;
    setState(() {
      _clientId = id;
      _residentName = client?.name ?? '';
      _residenceId = client?.residenceId ?? '';
      if (previous.isNotEmpty && previous != id) {
        for (final i in _items) {
          i.dispose();
        }
        _items = [_Item('MAR')];
      }
    });
    _loadWitnesses();
  }

  void _setMedication(_Item item, String id) {
    final choice = _choices.where((m) => m.id == id).firstOrNull;
    setState(() {
      item.medicationId = id;
      if (choice != null) {
        item.recordType = choice.recordType;
        item.medicationName = choice.label;
        item.dosage = choice.dosage;
        item.scheduledTime = choice.scheduledTime;
        item.isControlled = choice.isControlled;
      }
    });
  }

  bool get _medicinesDone => _clientId.isNotEmpty && _items.every((i) => i.medicationId.isNotEmpty);
  bool get _detailsDone => _staffId.isNotEmpty && _items.every((i) => i.status.isNotEmpty);
  bool get _safetyDone => _checks.values.every((v) => v);
  int get _evidenceCount => _items.fold(0, (n, i) => n + i.evidence.length);

  String? _validateStepOne() {
    if (_clientId.isEmpty) return 'Choose the resident this round is for';
    if (_staffId.isEmpty) return 'Say who administered it';
    for (final i in _items) {
      if (i.medicationId.isEmpty) return 'Choose the medicine being given';
      if (i.status != 'administered') {
        final written = i.notes.text.trim().isNotEmpty || i.clinical.text.trim().isNotEmpty;
        if (i.doseReason.isEmpty && !written) return 'Say why this dose was not given';
        if (i.doseReason == 'other' && !written) return 'Write down what happened';
      }
      if (i.isControlled && i.status == 'administered' && i.witness.isEmpty) {
        return 'A controlled drug needs a witness';
      }
      if (i.witness.isNotEmpty && i.witness == _staffId) {
        return 'A witness has to be someone other than the person giving it';
      }
    }
    return null;
  }

  void _next() {
    if (_step == 0) {
      final error = _validateStepOne();
      if (error != null) {
        setState(() => _error = error);
        return;
      }
    }
    setState(() {
      _error = null;
      _step++;
    });
  }

  Future<void> _submit() async {
    final error = _validateStepOne();
    if (error != null) {
      setState(() {
        _error = error;
        _step = 0;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final at = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final result = await _c.recordRound(
      MarRoundDraft(
        clientId: _clientId,
        residenceId: _residenceId,
        staffId: _staffId,
        administeredAt: at.toUtc(),
        safetyChecks: Map.of(_checks),
        vitals: {for (final e in _vitals.entries) e.key: e.value.text.trim()},
        items: [for (final i in _items) i.toDraft()],
      ),
      day: MedicationLabels.day(_date),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _saving = false;
        _error = result;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _addEvidence(_Item item) async {
    final files = await widget.pickEvidence();
    if (files.isEmpty || !mounted) return;
    setState(() => item.evidence = [...item.evidence, ...files]);
  }

  String get _timeLabel =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final steps = MedicationLabels.steps;
    final last = _step == steps.length - 1;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          MarSheetHeader(
            icon: Icons.vaccines_outlined,
            title: 'Record Administration',
            description:
                'Record what was given, who gave it, and the checks made — one resident, any number of medicines.',
            badge: MarPill(
              label: '${_items.length} medicine${_items.length == 1 ? '' : 's'}',
              tone: MarTone.info,
            ),
          ),
          _stepper(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
              children: [
                if (_allergies.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.criticalBackgroundSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_residentName.isEmpty ? 'This resident' : _residentName} has recorded allergies: ${_allergies.join(', ')}',
                      style: handoverText(context, 13, weight: FontWeight.w600, color: AppColors.criticalRed),
                    ),
                  ),
                if (_error != null) MarErrorBox(_error!, key: const ValueKey('mar-wizard-error')),
                ...switch (_step) {
                  0 => _medicinesStep(context),
                  1 => _safetyStep(context),
                  _ => _documentationStep(context),
                },
                const SizedBox(height: 16),
                _summary(context),
                const SizedBox(height: 12),
                Text(
                  MedicationLabels.stepTips[steps[_step].$1] ?? '',
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          MarSheetFooter(
            leading: Text(
              '* Required fields · ${_medicinesDone && _detailsDone ? 1 : 0} of ${steps.length} steps complete',
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
            children: [
              if (_step > 0)
                HandoverButton(label: 'Back', onPressed: () => setState(() => _step--))
              else
                HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).maybePop()),
              if (last)
                HandoverButton(
                  key: const ValueKey('mar-wizard-complete'),
                  label: _saving ? 'Saving…' : 'Complete Administration',
                  filled: true,
                  onPressed: _saving ? null : _submit,
                )
              else
                HandoverButton(
                  key: const ValueKey('mar-wizard-next'),
                  label: 'Next: ${steps[_step + 1].$2}',
                  filled: true,
                  onPressed: _next,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepper(BuildContext context) {
    final steps = MedicationLabels.steps;
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: InkWell(
                key: ValueKey('mar-wizard-step-$i'),
                onTap: i < _step ? () => setState(() => _step = i) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: i <= _step ? AppColors.secondaryTeal : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i].$2,
                      style: handoverText(
                        context,
                        12,
                        weight: i == _step ? FontWeight.w700 : FontWeight.w500,
                        color: i == _step ? AppColors.primaryNavy : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      steps[i].$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: handoverText(context, 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            if (i < steps.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _readOnly(BuildContext context, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '—' : value,
            style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
          ),
        ],
      );

  Widget _pickerField(BuildContext context, {required String key, required String label, required String value, String? helper, required VoidCallback onTap, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarLabel(label, required: true),
        InkWell(
          key: ValueKey(key),
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: Row(
              children: [
                Expanded(child: Text(value, style: handoverText(context, 13.5))),
                Icon(icon, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 5),
          Text(helper, style: handoverText(context, 12, color: AppColors.textMuted)),
        ],
      ],
    );
  }

  List<Widget> _medicinesStep(BuildContext context) {
    const gap = SizedBox(height: 14);
    return [
      const MarStepTitle(
        title: 'Medicines',
        description: 'Choose who this round is for, then add every medicine being given.',
      ),
      MarSelectField(
        key: const ValueKey('mar-wizard-resident'),
        label: 'Resident',
        required: true,
        value: _clientId,
        options: _locked && _residentOptions.every((o) => o.$1 != _clientId)
            ? [..._residentOptions, (_clientId, _residentName)]
            : _residentOptions,
        placeholder: 'Search residents',
        enabled: !_locked,
        helper: _locked
            ? 'Fixed to the dose this was opened on.'
            : 'The medicine list below is scoped to whoever is chosen here.',
        onChanged: _setResident,
      ),
      if (_clientId.isNotEmpty) ...[
        gap,
        _pickerField(
          context,
          key: 'mar-wizard-date',
          label: 'Administration Date',
          value: MedicationLabels.dateTime(_date).split(' ').first,
          icon: Icons.calendar_today_outlined,
          onTap: _pickDate,
        ),
        gap,
        _pickerField(
          context,
          key: 'mar-wizard-time',
          label: 'Actual Administration Time',
          value: _timeLabel,
          helper: 'Shared by every medicine in this round',
          icon: Icons.schedule_rounded,
          onTap: _pickTime,
        ),
        gap,
        MarSelectField(
          key: const ValueKey('mar-wizard-staff'),
          label: 'Administered By',
          required: true,
          value: _staffId,
          options: _staffOptions,
          placeholder: 'Select a staff member',
          enabled: _c.canManage,
          helper: _c.canManage
              ? 'Recording on behalf of somebody else.'
              : 'A round is charted by the person who gave it.',
          onChanged: (v) => setState(() => _staffId = v),
        ),
        gap,
        for (var i = 0; i < _items.length; i++) ...[
          _itemCard(context, i),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: HandoverButton(
            key: const ValueKey('mar-wizard-add-med'),
            label: 'Add another medicine',
            icon: Icons.add_rounded,
            onPressed: () => setState(() => _items.add(_Item('MAR'))),
          ),
        ),
      ],
    ];
  }

  Widget _itemCard(BuildContext context, int index) {
    final item = _items[index];
    final lockedItem = _locked && index == 0;
    final notGiven = item.status != 'administered';
    return HandoverPanel(
      key: ValueKey('mar-wizard-item-$index'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MEDICINE ${index + 1}',
                  style: handoverText(context, 12, weight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ),
              if (!lockedItem && _items.length > 1)
                IconButton(
                  key: ValueKey('mar-wizard-remove-$index'),
                  tooltip: 'Remove this medicine',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _items.removeAt(index).dispose()),
                  icon: const Icon(Icons.close_rounded, size: 15, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (lockedItem)
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _readOnly(context, 'Medication', item.medicationName),
                _readOnly(context, 'Dosage', item.dosage),
                _readOnly(context, 'Scheduled', item.scheduledTime.isEmpty ? 'On request' : item.scheduledTime),
                _readOnly(context, 'Controlled drug', item.isControlled ? 'Yes — witness required' : 'No'),
              ],
            )
          else ...[
            MarSelectField(
              key: ValueKey('mar-wizard-med-$index'),
              label: 'Medication',
              required: true,
              value: item.medicationId,
              options: [for (final m in _choices) (m.id, m.label)],
              placeholder: _clientId.isNotEmpty
                  ? "Search this resident's prescriptions and PRN medicines"
                  : 'Choose a resident first',
              onChanged: (v) => _setMedication(item, v),
            ),
            if (item.medicationId.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _readOnly(context, 'Dosage', item.dosage.isEmpty ? 'As prescribed' : item.dosage),
                    _readOnly(
                      context,
                      'Schedule',
                      item.isPrn ? 'On request (PRN)' : (item.scheduledTime.isEmpty ? 'Scheduled' : item.scheduledTime),
                    ),
                    _readOnly(context, 'Type', item.isPrn ? 'PRN Medicine' : 'Prescription'),
                    if (item.isControlled) const MarPill(label: 'CONTROLLED', tone: MarTone.purple),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          const MarLabel('Administration Status', required: true),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (value, label) in MedicationLabels.outcomes)
                ChoiceChip(
                  key: ValueKey('mar-wizard-status-$index-$value'),
                  label: Text(label, style: handoverText(context, 12, weight: FontWeight.w600)),
                  selected: item.status == value,
                  selectedColor: AppColors.activeBackground,
                  onSelected: (_) => setState(() => item.status = value),
                ),
            ],
          ),
          if (notGiven) ...[
            const SizedBox(height: 14),
            MarSelectField(
              key: ValueKey('mar-wizard-reason-$index'),
              label: 'Why was it not given?',
              value: item.doseReason,
              options: MedicationLabels.doseReasons,
              placeholder: 'Choose a reason',
              onChanged: (v) => setState(() => item.doseReason = v),
            ),
          ],
          const SizedBox(height: 14),
          MarSelectField(
            key: ValueKey('mar-wizard-witness-$index'),
            label: item.isControlled ? 'Witness' : 'Witness (optional)',
            required: item.isControlled,
            value: item.witness,
            options: _witnessOptions,
            allowClear: !item.isControlled,
            placeholder: item.isControlled ? 'Required for a controlled drug' : 'No witness',
            helper: _witnessesLoaded && _witnesses.isEmpty
                ? 'Nobody approved to give medicine is clocked in at this home right now.'
                : 'Colleagues on duty here who are approved to give medicine.',
            onChanged: (v) => setState(() => item.witness = v),
          ),
          const SizedBox(height: 14),
          HandoverTextArea(
            key: ValueKey('mar-wizard-clinical-$index'),
            label: 'Clinical Notes (optional)',
            controller: item.clinical,
            placeholder: 'Observation about the resident or the dose…',
          ),
        ],
      ),
    );
  }

  List<Widget> _safetyStep(BuildContext context) {
    Widget check(String field, String label, String description) => CheckboxListTile(
          key: ValueKey(field == 'safetyConfirmed' ? 'mar-wizard-safety-confirmed' : 'mar-wizard-check-$field'),
          value: _checks[field],
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.secondaryTeal,
          title: Text(label, style: handoverText(context, 13.5, weight: FontWeight.w600)),
          subtitle: Text(description, style: handoverText(context, 12, color: AppColors.textMuted)),
          onChanged: (v) => setState(() => _checks[field] = v == true),
        );
    return [
      const MarStepTitle(
        title: 'Safety Check',
        description: 'Confirm the point-of-administration checks before recording this round.',
      ),
      HandoverPanel(
        child: check(
          'safetyConfirmed',
          'Pre-administration verification',
          'I confirm the checks below have been completed.',
        ),
      ),
      const SizedBox(height: 12),
      HandoverPanel(
        child: Column(
          children: [
            for (final (field, label, description) in MedicationLabels.safetyChecks)
              check(field, label, description),
          ],
        ),
      ),
      const SizedBox(height: 12),
      for (final (field, label, placeholder) in MedicationLabels.vitals) ...[
        MarTextField(
          key: ValueKey('mar-wizard-vital-$field'),
          label: label,
          controller: _vitals[field]!,
          placeholder: placeholder,
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _documentationStep(BuildContext context) {
    final count = _evidenceCount;
    Widget review(String label, bool done, {String? trailing}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: done ? AppColors.activeGreen : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: handoverText(context, 13))),
              if (trailing != null)
                Text(trailing, style: handoverText(context, 12, color: AppColors.textMuted)),
            ],
          ),
        );
    return [
      const MarStepTitle(
        title: 'Documentation',
        description: 'Attach supporting evidence and any final notes, per medicine.',
      ),
      for (var i = 0; i < _items.length; i++) ...[
        HandoverPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _items[i].medicationName.isEmpty ? 'Medicine ${i + 1}' : _items[i].medicationName,
                style: handoverText(context, 13, weight: FontWeight.w700, color: AppColors.primaryNavy),
              ),
              const SizedBox(height: 12),
              const MarLabel('Upload Supporting Evidence'),
              InkWell(
                key: ValueKey('mar-wizard-evidence-$i'),
                onTap: () => _addEvidence(_items[i]),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.searchBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Filed against the resident in Documents · up to 15MB each',
                          style: handoverText(context, 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final f in _items[i].evidence)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(f.name, style: handoverText(context, 12))),
                      GestureDetector(
                        onTap: () => setState(
                          () => _items[i].evidence = _items[i].evidence.where((e) => e != f).toList(),
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              HandoverTextArea(
                key: ValueKey('mar-wizard-notes-$i'),
                label: 'Notes',
                controller: _items[i].notes,
                placeholder: 'Anything worth recording about this dose…',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      HandoverPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Final Review Checklist', style: handoverText(context, 13.5, weight: FontWeight.w700)),
            Text(
              'Confirm everything is complete before submitting.',
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            review('Resident and medicines confirmed', _medicinesDone),
            review('Administration details recorded', _detailsDone),
            review('Safety verification passed', _safetyDone),
            review(
              'Supporting evidence attached',
              count > 0,
              trailing: count > 0 ? '$count file${count == 1 ? '' : 's'}' : 'Optional',
            ),
          ],
        ),
      ),
    ];
  }

  Widget _summary(BuildContext context) {
    final ready = _safetyDone && _medicinesDone && _detailsDone;
    return HandoverPanel(
      key: const ValueKey('mar-wizard-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('MAR Summary', style: handoverText(context, 14, weight: FontWeight.w700))),
              Text('Live preview', style: handoverText(context, 11.5, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _readOnly(context, 'Administered By', _staffName),
              _readOnly(context, 'When', '${MedicationLabels.dateTime(_date).split(' ').first} $_timeLabel'),
            ],
          ),
          const SizedBox(height: 10),
          for (final i in _items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      i.medicationName.isEmpty ? '—' : i.medicationName,
                      style: handoverText(context, 12.5, weight: FontWeight.w600),
                    ),
                  ),
                  MarPill(
                    label: MedicationLabels.label(MedicationLabels.outcomes, i.status),
                    tone: i.status == 'administered' ? MarTone.success : MarTone.warning,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ready ? AppColors.activeBackground : AppColors.urgentBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliance',
                  style: handoverText(context, 12, weight: FontWeight.w700, color: AppColors.primaryNavy),
                ),
                Text(
                  ready
                      ? 'All safety checks confirmed. Ready to submit.'
                      : 'Waiting for confirmation. Complete all required fields to finalize this record.',
                  style: handoverText(context, 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final (field, label) in MedicationLabels.rights)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _checks[field] == true ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: _checks[field] == true ? AppColors.activeGreen : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(label, style: handoverText(context, 11.5)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
