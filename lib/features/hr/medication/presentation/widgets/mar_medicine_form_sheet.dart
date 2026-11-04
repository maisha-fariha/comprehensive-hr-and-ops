import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/mar_medication.dart';
import '../../domain/entities/mar_options.dart';
import '../medication_labels.dart';
import 'medication_common.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Web "Add a medicine" / "Correct a medicine" (and the PRN variants).
/// [onSubmit] returns the error for the banner, or null once saved.
Future<void> showMarMedicineFormSheet(
  BuildContext context, {
  required bool prn,
  MarMedication? editing,
  required List<MarOption> residences,
  required List<MarClientOption> clients,
  required Future<List<MarOption>> Function(String? clientId) loadChecks,
  required Future<String?> Function(List<MarMedicineDraft> drafts) onSubmit,
}) =>
    showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.94,
        child: MarMedicineForm(
          prn: prn,
          editing: editing,
          residences: residences,
          clients: clients,
          loadChecks: loadChecks,
          onSubmit: onSubmit,
        ),
      ),
    );

class MarMedicineForm extends StatefulWidget {
  final bool prn;
  final MarMedication? editing;
  final List<MarOption> residences;
  final List<MarClientOption> clients;
  final Future<List<MarOption>> Function(String? clientId) loadChecks;
  final Future<String?> Function(List<MarMedicineDraft> drafts) onSubmit;

  const MarMedicineForm({
    super.key,
    required this.prn,
    this.editing,
    required this.residences,
    required this.clients,
    required this.loadChecks,
    required this.onSubmit,
  });

  @override
  State<MarMedicineForm> createState() => _MarMedicineFormState();
}

String _costText(num? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toString();
}

/// Per-kind (Medicine vs PRN) draft so switching the tab does not leak fields.
class _KindBuffer {
  List<MarMedicineDraft> list = [];
  String name = '';
  String dose = '';
  String timeInput = '';
  String route = '';
  String stock = '';
  String cost = '';
  String gap = '';
  String instructions = '';
  String within = '60';
  String frequency = 'daily';
  List<String> times = [];
  Set<int> weekdays = {};
  String starts = '';
  String ends = '';
  bool controlled = false;
  String check = '';
  String? error;
}

class _MarMedicineFormState extends State<MarMedicineForm> {
  late bool _prn = widget.editing?.isPrn ?? widget.prn;
  final List<MarMedicineDraft> _list = [];
  late String _house = widget.editing?.residenceId ?? '';
  late String _resident = widget.editing?.clientId ?? '';

  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _timeInput = TextEditingController();
  final _route = TextEditingController();
  final _stock = TextEditingController();
  final _cost = TextEditingController();
  final _gap = TextEditingController();
  final _instructions = TextEditingController();
  final _within = TextEditingController(text: '60');
  String _frequency = 'daily';
  List<String> _times = [];
  Set<int> _weekdays = {};
  String _starts = '';
  String _ends = '';
  bool _controlled = false;
  String _check = '';
  List<MarOption> _checks = const [];
  String? _error;
  bool _saving = false;

  /// Separate Medicine / PRN working copies while the sheet is open.
  final _KindBuffer _scheduledBuf = _KindBuffer();
  final _KindBuffer _prnBuf = _KindBuffer();

  bool get _editingMode => widget.editing != null;

  void _captureKind(bool prn) {
    final buf = prn ? _prnBuf : _scheduledBuf;
    buf.list = List<MarMedicineDraft>.from(_list);
    buf.name = _name.text;
    buf.dose = _dose.text;
    buf.timeInput = _timeInput.text;
    buf.route = _route.text;
    buf.stock = _stock.text;
    buf.cost = _cost.text;
    buf.gap = _gap.text;
    buf.instructions = _instructions.text;
    buf.within = _within.text;
    buf.frequency = _frequency;
    buf.times = List<String>.from(_times);
    buf.weekdays = Set<int>.from(_weekdays);
    buf.starts = _starts;
    buf.ends = _ends;
    buf.controlled = _controlled;
    buf.check = _check;
    buf.error = _error;
  }

  void _restoreKind(bool prn) {
    final buf = prn ? _prnBuf : _scheduledBuf;
    _list
      ..clear()
      ..addAll(buf.list);
    _name.text = buf.name;
    _dose.text = buf.dose;
    _timeInput.text = buf.timeInput;
    _route.text = buf.route;
    _stock.text = buf.stock;
    _cost.text = buf.cost;
    _gap.text = buf.gap;
    _instructions.text = buf.instructions;
    _within.text = buf.within.isEmpty ? '60' : buf.within;
    _frequency = buf.frequency;
    _times = List<String>.from(buf.times);
    _weekdays = Set<int>.from(buf.weekdays);
    _starts = buf.starts;
    _ends = buf.ends;
    _controlled = buf.controlled;
    _check = buf.check;
    _error = buf.error;
  }

  void _switchKind(bool prn) {
    if (_prn == prn || _editingMode) return;
    _commitTime();
    _captureKind(_prn);
    _prn = prn;
    _restoreKind(prn);
  }

  @override
  void initState() {
    super.initState();
    final m = widget.editing;
    if (m != null) {
      _name.text = m.name;
      _dose.text = m.dose != null && m.dose != '—' ? m.dose! : '';
      _instructions.text = m.instructions;
      _controlled = m.isControlled;
      _weekdays = m.weekdays.toSet();
      _route.text = m.route;
      _starts = m.startsAt;
      _ends = m.endsAt;
      _stock.text = m.stockUnitsPerDose?.toString() ?? '';
      _cost.text = _costText(m.costPerDose);
      _gap.text = m.minIntervalMinutes?.toString() ?? '';
      _check = m.requiresCheckScheduleId ?? '';
      _within.text = '${m.requiresCheckWithinMinutes ?? 60}';
      // Kept from the record so a correction does not wipe the round times.
      if (const ['daily', 'weekly', 'custom'].contains(m.frequency)) _frequency = m.frequency;
      _times = [...m.times];
    }
    widget.loadChecks(m?.clientId).then((list) {
      if (mounted) setState(() => _checks = list);
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _dose, _timeInput, _route, _stock, _cost, _gap, _instructions, _within]) {
      c.dispose();
    }
    super.dispose();
  }

  void _commitTime() {
    final t = _timeInput.text.trim();
    if (t.isNotEmpty && !_times.contains(t)) _times = [..._times, t];
    _timeInput.clear();
  }

  MarMedicineDraft _current() {
    _commitTime();
    return MarMedicineDraft(
      isPrn: _prn,
      clientId: _resident,
      residenceId: _house,
      name: _name.text.trim(),
      dose: _dose.text.trim(),
      frequency: _frequency,
      times: _times,
      weekdays: MedicationLabels.weekdays.map((w) => w.$1).where(_weekdays.contains).toList(),
      route: _route.text,
      startsAt: _starts,
      endsAt: _ends,
      stockUnitsPerDose: _stock.text,
      costPerDose: _cost.text,
      minIntervalMinutes: _gap.text,
      instructions: _instructions.text.trim(),
      isControlled: _controlled,
      requiresCheckScheduleId: _check,
      requiresCheckWithinMinutes: _within.text,
    );
  }

  void _resetMedicine() {
    for (final c in [_name, _dose, _route, _stock, _cost, _gap, _instructions, _timeInput]) {
      c.clear();
    }
    _within.text = '60';
    _frequency = 'daily';
    _times = [];
    _weekdays = {};
    _starts = '';
    _ends = '';
    _controlled = false;
    _check = '';
  }

  void _addAnother() {
    setState(() {
      _error = null;
      if (_name.text.trim().isEmpty) {
        _error = 'What is the medicine called?';
      } else if (_house.isEmpty) {
        _error = 'Which house is this held at?';
      } else if (!_prn && _resident.isEmpty) {
        _error = 'A prescription is for one resident — choose who.';
      } else if (!_prn && _dose.text.trim().isEmpty) {
        _error = 'What dose is prescribed?';
      } else if (_route.text.trim().isEmpty) {
        _error = 'How is it given — the route?';
      } else if (_stock.text.trim().isEmpty) {
        _error = 'How many stock units does one dose use?';
      } else if (!_prn && _times.isEmpty && _timeInput.text.trim().isEmpty) {
        _error = 'A scheduled medication needs at least one time of day';
      } else if (!_prn && _frequency == 'weekly' && _weekdays.isEmpty) {
        _error = 'A weekly medicine has to say which days it falls on.';
      } else {
        _commitTime();
        _list.add(_current());
        _resetMedicine();
      }
    });
  }

  void _syncStockFromDose(String doseText) {
    final match = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(doseText.trim());
    if (match == null) return;
    final next = match.group(1)!;
    if (_stock.text == next) return;
    _stock.text = next;
  }

  Future<void> _pickClockTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) return;
    final t =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (!_times.contains(t)) {
        _times = [..._times, t]..sort();
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    String? error;
    if (_name.text.trim().isEmpty) {
      error = 'What is the medicine called?';
    } else if (_house.isEmpty) {
      error = 'Which house is this held at?';
    } else if (!_prn && _resident.isEmpty) {
      error = 'A prescription is for one resident — choose who.';
    } else if (!_prn && _dose.text.trim().isEmpty) {
      error = 'What dose is prescribed?';
    } else if (_route.text.trim().isEmpty) {
      error = 'How is it given — the route?';
    } else if (_stock.text.trim().isEmpty) {
      error = 'How many stock units does one dose use?';
    } else if (!_prn && _times.isEmpty && _timeInput.text.trim().isEmpty) {
      error = 'A scheduled medication needs at least one time of day';
    } else if (!_prn &&
        _frequency == 'weekly' &&
        _weekdays.isEmpty) {
      error = 'A weekly medicine has to say which days it falls on.';
    } else if (_starts.isNotEmpty && _ends.isNotEmpty && _ends.compareTo(_starts) < 0) {
      error = 'A course cannot end before it starts';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _saving = true);
    final result = await widget.onSubmit([..._list, _current()]);
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

  Future<void> _pickDate(bool start) async {
    final current = DateTime.tryParse(start ? _starts : _ends) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _starts = MedicationLabels.day(picked);
      } else {
        _ends = MedicationLabels.day(picked);
      }
    });
  }

  String get _title => _editingMode
      ? (_prn ? 'Correct a PRN medicine' : 'Correct a medicine')
      : (_prn ? 'Add a PRN medicine' : 'Add a medicine');

  String get _submitLabel {
    if (_saving) return 'Saving…';
    if (_editingMode) return 'Save changes';
    if (_list.isEmpty) return 'Add';
    return _prn ? 'Add ${_list.length + 1} medicines' : 'Prescribe ${_list.length + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final locked = _list.isNotEmpty;
    final residentOptions = [
      for (final c in widget.clients)
        if (_house.isEmpty || c.residenceId == _house) (c.id, c.name),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          MarSheetHeader(
            icon: Icons.medication_outlined,
            title: _title,
            description: _prn
                ? 'Not prescribed by a doctor — given as needed.'
                : 'Charted at set times against one resident.',
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
              children: [
                if (!_editingMode) ...[_kindSwitch(context), const SizedBox(height: 14)],
                if (_error != null) MarErrorBox(_error!, key: const ValueKey('mar-form-error')),
                HandoverPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _prn ? 'Where this is held' : 'Who this is for',
                              style: handoverText(context, 12.5, weight: FontWeight.w700, color: AppColors.primaryNavy),
                            ),
                          ),
                          if (locked)
                            GestureDetector(
                              onTap: () => setState(_list.clear),
                              child: Text(
                                'Clear list to change',
                                style: handoverText(context, 11.5, weight: FontWeight.w600, color: AppColors.textMuted),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MarSelectField(
                        key: const ValueKey('mar-form-house'),
                        label: 'House',
                        required: true,
                        value: _house,
                        options: [for (final r in widget.residences) (r.id, r.label)],
                        placeholder: 'Where it is held',
                        enabled: !_editingMode && !locked,
                        helper: _editingMode ? 'Moving a medicine between houses is not an edit.' : null,
                        onChanged: (v) => setState(() {
                          _house = v;
                          if (!widget.clients.any((c) => c.id == _resident && c.residenceId == v)) {
                            _resident = '';
                          }
                        }),
                      ),
                      const SizedBox(height: 12),
                      MarSelectField(
                        key: const ValueKey('mar-form-resident'),
                        label: _prn ? 'Resident (optional)' : 'Resident',
                        required: !_prn,
                        value: _resident,
                        options: residentOptions,
                        allowClear: _prn,
                        placeholder: _house.isEmpty
                            ? 'Choose a house first'
                            : (_prn ? 'Leave blank for house stock' : 'Who it is prescribed for'),
                        enabled: _house.isNotEmpty && !locked,
                        onChanged: (v) => setState(() => _resident = v),
                      ),
                      if (locked) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Every medicine in this list is held here${_resident.isNotEmpty ? ' for the same resident' : ''}.',
                          style: handoverText(context, 11, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_editingMode) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: HandoverButton(
                      key: const ValueKey('mar-form-add-another'),
                      label: 'Add another medicine',
                      icon: Icons.add_rounded,
                      onPressed: _saving ? null : _addAnother,
                    ),
                  ),
                ],
                if (locked) ...[const SizedBox(height: 12), _addedList(context)],
                const SizedBox(height: 14),
                if (locked) ...[
                  Text('Next medicine', style: handoverText(context, 12.5, weight: FontWeight.w700, color: AppColors.primaryNavy)),
                  const SizedBox(height: 10),
                ],
                ..._medicineFields(context),
              ],
            ),
          ),
          MarSheetFooter(
            children: [
              HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).maybePop()),
              HandoverButton(
                key: const ValueKey('mar-form-submit'),
                label: _submitLabel,
                filled: true,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kindSwitch(BuildContext context) {
    Widget option(bool prn, String label) {
      final active = _prn == prn;
      return Expanded(
        child: InkWell(
          key: ValueKey(prn ? 'mar-form-kind-prn' : 'mar-form-kind-prescribed'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _switchKind(prn)),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.primaryNavy : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: handoverText(
                context,
                12.5,
                weight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppColors.surfaceWhite : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(children: [option(false, 'Medicine'), option(true, 'PRN Medicine')]),
    );
  }

  Widget _addedList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_list.length} medicine${_list.length == 1 ? '' : 's'} added',
            style: handoverText(context, 12.5, weight: FontWeight.w700, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _list.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_list[i].name, style: handoverText(context, 12.5, weight: FontWeight.w600)),
                        Text(
                          [
                            _list[i].dose,
                            _prn
                                ? 'As needed'
                                : (_list[i].times.isNotEmpty ? _list[i].times.join(', ') : _list[i].frequency),
                            _list[i].route,
                          ].where((e) => e.isNotEmpty).join(' · '),
                          style: handoverText(context, 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: ValueKey('mar-form-remove-$i'),
                    tooltip: 'Remove ${_list[i].name}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _list.removeAt(i)),
                    icon: const Icon(Icons.close_rounded, size: 15, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          Text(
            _prn
                ? "Each is added on its own — one failing won't stop the rest."
                : 'All of them are written together, or none is.',
            style: handoverText(context, 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  List<Widget> _medicineFields(BuildContext context) {
    const gap = SizedBox(height: 14);
    return [
      MarTextField(
        key: const ValueKey('mar-form-name'),
        label: 'Medicine',
        required: true,
        controller: _name,
        placeholder: 'Paracetamol 500mg',
      ),
      gap,
      MarTextField(
        key: const ValueKey('mar-form-dose'),
        label: 'Dose',
        required: !_prn,
        controller: _dose,
        placeholder: _prn ? '1 tablet' : '1 tablet',
        onChanged: (v) => setState(() => _syncStockFromDose(v)),
      ),
      gap,
      if (_prn)
        HandoverTextArea(
          key: const ValueKey('mar-form-instructions'),
          label: 'When to give it',
          controller: _instructions,
          placeholder: 'For pain, up to 4 in 24 hours, at least 4 hours apart…',
        )
      else ...[
        MarSelectField(
          key: const ValueKey('mar-form-frequency'),
          label: 'How often',
          value: _frequency,
          options: MedicationLabels.frequencies,
          placeholder: 'Every day',
          onChanged: (v) => setState(() => _frequency = v),
        ),
        gap,
        _timesField(context),
        if (_frequency == 'weekly') ...[gap, _weekdaysField(context)],
      ],
      gap,
      MarTextField(
        key: const ValueKey('mar-form-route'),
        label: 'Route',
        required: true,
        controller: _route,
        placeholder: 'Oral, topical, inhaled…',
      ),
      gap,
      MarTextField(
        key: const ValueKey('mar-form-stock'),
        label: 'Units of stock per dose',
        required: true,
        controller: _stock,
        numeric: true,
        placeholder: 'e.g. 1',
        helper:
            'Units deducted automatically from stock when each dose is given.',
      ),
      gap,
      MarTextField(
        key: const ValueKey('mar-form-cost'),
        label: 'Cost per dose',
        controller: _cost,
        decimal: true,
        placeholder: 'Leave blank if not tracked',
        helper: "Counts toward the resident's cost of care each time a dose is given.",
      ),
      gap,
      _dateField(
        context,
        key: 'mar-form-starts',
        label: 'Starts (optional)',
        value: _starts,
        helper: _prn
            ? 'Leave both blank for standing house stock.'
            : 'Leave both blank for a standing prescription.',
        onTap: () => _pickDate(true),
        onClear: () => setState(() => _starts = ''),
      ),
      gap,
      _dateField(
        context,
        key: 'mar-form-ends',
        label: 'Ends (optional)',
        value: _ends,
        onTap: () => _pickDate(false),
        onClear: () => setState(() => _ends = ''),
      ),
      if (_prn) ...[
        gap,
        MarTextField(
          key: const ValueKey('mar-form-gap'),
          label: 'Shortest gap between doses (minutes)',
          controller: _gap,
          numeric: true,
          placeholder: 'Leave blank for no minimum',
          helper: '240 for a medicine prescribed no more often than four hourly.',
        ),
      ],
      gap,
      CheckboxListTile(
        key: const ValueKey('mar-form-controlled'),
        value: _controlled,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.secondaryTeal,
        title: Text(
          'Controlled drug — a witness is required to chart a dose',
          style: handoverText(context, 13, weight: FontWeight.w500),
        ),
        onChanged: (v) => setState(() => _controlled = v == true),
      ),
      gap,
      MarSelectField(
        key: const ValueKey('mar-form-check'),
        label: 'Requires a check first',
        value: _check,
        options: [for (final c in _checks) (c.id, c.label)],
        allowClear: true,
        placeholder: _checks.isNotEmpty ? 'No check required' : 'This resident has no recurring checks',
        helper: 'A dose cannot be charted until this check has been recorded',
        onChanged: (v) => setState(() => _check = v),
      ),
      if (_check.isNotEmpty) ...[
        gap,
        MarTextField(
          key: const ValueKey('mar-form-within'),
          label: 'Recorded within (minutes)',
          controller: _within,
          numeric: true,
          helper: 'A reading from yesterday is not evidence about a dose due now',
        ),
      ],
    ];
  }

  static const _timePresets = [
    '08:00',
    '12:00',
    '14:00',
    '18:00',
    '20:00',
    '22:00',
  ];

  Widget _timesField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MarLabel('At what times', required: true),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.searchBorder),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final t in _times)
                      Chip(
                        label: Text(
                          t,
                          style: handoverText(context, 12, weight: FontWeight.w600),
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.filterButtonBackground,
                        side: BorderSide.none,
                        deleteIcon: const Icon(Icons.close_rounded, size: 12),
                        onDeleted: () => setState(
                          () => _times = _times.where((x) => x != t).toList(),
                        ),
                      ),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        key: const ValueKey('mar-form-time-input'),
                        controller: _timeInput,
                        style: handoverText(context, 13),
                        onSubmitted: (_) => setState(_commitTime),
                        onTapOutside: (_) {
                          if (_timeInput.text.trim().isNotEmpty) {
                            setState(_commitTime);
                          }
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: _times.isEmpty ? '08:00' : '',
                          hintStyle: handoverText(
                            context,
                            13,
                            color: AppColors.textMuted,
                          ),
                          suffixIcon: IconButton(
                            key: const ValueKey('mar-form-time-clock'),
                            tooltip: 'Pick a time',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: _pickClockTime,
                            icon: const Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            HandoverButton(
              key: const ValueKey('mar-form-add-time'),
              label: 'Add time',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: () {
                if (_timeInput.text.trim().isEmpty) {
                  _pickClockTime();
                } else {
                  setState(_commitTime);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Presets',
          style: handoverText(context, 12, weight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in _timePresets)
              ActionChip(
                key: ValueKey('mar-form-time-preset-$t'),
                label: Text(
                  '+ $t',
                  style: handoverText(context, 12, weight: FontWeight.w600),
                ),
                backgroundColor: AppColors.filterButtonBackground,
                side: BorderSide.none,
                onPressed: () => setState(() {
                  if (!_times.contains(t)) {
                    _times = [..._times, t]..sort();
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _weekdaysField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MarLabel('On which days', required: true),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (value, label) in MedicationLabels.weekdays)
              FilterChip(
                key: ValueKey('mar-form-day-$value'),
                label: Text(label, style: handoverText(context, 12, weight: FontWeight.w600)),
                selected: _weekdays.contains(value),
                selectedColor: AppColors.activeBackground,
                checkmarkColor: AppColors.secondaryTeal,
                onSelected: (on) => setState(() {
                  on ? _weekdays.add(value) : _weekdays.remove(value);
                }),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          _weekdays.isEmpty ? 'Pick the days…' : 'A weekly medicine has to say which days it falls on.',
          style: handoverText(context, 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String key,
    required String label,
    required String value,
    String? helper,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarLabel(label),
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
                Expanded(
                  child: Text(
                    value.isEmpty ? 'dd/mm/yyyy' : value,
                    style: handoverText(
                      context,
                      13.5,
                      color: value.isEmpty ? AppColors.textMuted : AppColors.textHeading,
                    ),
                  ),
                ),
                if (value.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                  )
                else
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
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
}
