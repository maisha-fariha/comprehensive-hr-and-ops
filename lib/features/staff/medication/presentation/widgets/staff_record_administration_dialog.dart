import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/staff_client_medication_item.dart';
import '../../domain/entities/staff_med_options.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../domain/repositories/staff_medication_repository.dart';
import '../../../../../core/media/app_file_picker.dart';

/// Web-parity Record Administration — opens the 3-step wizard immediately.
/// Resident + medicine are chosen inside step 1 (not via a pre-picker sheet).
class StaffRecordAdministrationDialog extends StatefulWidget {
  final List<StaffMedClientOption> clients;
  final DueDose? preselectedDose;

  const StaffRecordAdministrationDialog({
    super.key,
    required this.clients,
    this.preselectedDose,
  });

  /// Opens the full Record Administration dialog/sheet directly (web behavior).
  static Future<StaffRecordAdministrationResult?> show(
    BuildContext context, {
    required List<StaffMedClientOption> clients,
    DueDose? preselectedDose,
  }) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final child = StaffRecordAdministrationDialog(
      clients: clients,
      preselectedDose: preselectedDose,
    );
    if (wide) {
      return showDialog<StaffRecordAdministrationResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          backgroundColor: AppColors.surfaceWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 980,
            height: MediaQuery.sizeOf(context).height * 0.92,
            child: child,
          ),
        ),
      );
    }
    return showModalBottomSheet<StaffRecordAdministrationResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.94,
        child: child,
      ),
    );
  }

  @override
  State<StaffRecordAdministrationDialog> createState() =>
      _StaffRecordAdministrationDialogState();
}

class StaffRecordAdministrationResult {
  final DueDose dose;
  final String status;
  final String? doseReason;
  final bool safetyConfirmed;
  final bool identityVerified;
  final bool medicationVerified;
  final bool dosageVerified;
  final bool routeVerified;
  final bool timeVerified;
  final String notes;
  final String clinicalNotes;
  final String bloodPressure;
  final String heartRate;
  final String temperature;
  final String bloodSugar;
  final List<String> evidencePaths;

  const StaffRecordAdministrationResult({
    required this.dose,
    required this.status,
    this.doseReason,
    required this.safetyConfirmed,
    required this.identityVerified,
    required this.medicationVerified,
    required this.dosageVerified,
    required this.routeVerified,
    required this.timeVerified,
    required this.notes,
    required this.clinicalNotes,
    required this.bloodPressure,
    required this.heartRate,
    required this.temperature,
    required this.bloodSugar,
    this.evidencePaths = const [],
  });
}

class _StatusOption {
  final String label;
  final String status;
  final String? doseReason;

  const _StatusOption({
    required this.label,
    required this.status,
    this.doseReason,
  });
}

class _StaffRecordAdministrationDialogState
    extends State<StaffRecordAdministrationDialog> {
  final _repo = GetIt.instance<StaffMedicationRepository>();

  int _step = 0;
  String? _banner;
  bool _loadingMeds = false;
  StaffMedClientOption? _client;
  StaffClientMedicationItem? _medication;
  List<StaffClientMedicationItem> _medications = [];

  bool _safetyConfirmed = false;
  bool _identityVerified = false;
  bool _medicationVerified = false;
  bool _dosageVerified = false;
  bool _routeVerified = false;
  bool _timeVerified = false;

  final _notes = TextEditingController();
  final _clinicalNotes = TextEditingController();
  final _why = TextEditingController();
  final _bp = TextEditingController();
  final _hr = TextEditingController();
  final _temp = TextEditingController();
  final _sugar = TextEditingController();
  final List<String> _evidencePaths = [];

  static const _steps = [
    (title: 'Medicines', subtitle: 'Resident & every medicine given'),
    (title: 'Safety Check', subtitle: 'Confirm the six checks'),
    (title: 'Documentation', subtitle: 'Evidence & final notes'),
  ];

  static const _statusOptions = <_StatusOption>[
    _StatusOption(label: 'Administered', status: 'administered'),
    _StatusOption(
      label: 'Refused by resident',
      status: 'refused',
      doseReason: 'patient_refused',
    ),
    _StatusOption(
      label: 'Withheld — clinical decision',
      status: 'withheld',
      doseReason: 'clinical_hold',
    ),
    _StatusOption(
      label: 'Not available — none in stock',
      status: 'not_available',
      doseReason: 'drug_unavailable',
    ),
    _StatusOption(label: 'Missed', status: 'missed', doseReason: 'other'),
  ];

  String? _whyReason;
  bool _noWitness = true;

  static const _whyReasons = <({String label, String doseReason})>[
    (label: 'Resident refused', doseReason: 'patient_refused'),
    (label: 'Asleep / unavailable', doseReason: 'resident_asleep'),
    (label: 'Away / hospital appointment', doseReason: 'hospitalized'),
    (label: 'Withheld on clinical advice', doseReason: 'clinical_hold'),
    (label: 'Not available — none in stock', doseReason: 'drug_unavailable'),
    (label: 'Other', doseReason: 'other'),
  ];

  _StatusOption _status = _statusOptions.first;

  @override
  void initState() {
    super.initState();
    final pre = widget.preselectedDose;
    if (pre == null) return;
    StaffMedClientOption? match;
    for (final c in widget.clients) {
      if (c.id == pre.clientId) {
        match = c;
        break;
      }
    }
    _client = match ??
        (pre.clientId.isEmpty
            ? null
            : StaffMedClientOption(
                id: pre.clientId,
                name: pre.residentName,
                residenceId: pre.residenceId,
                residenceName: pre.residenceName,
              ));
    _medication = StaffClientMedicationItem(
      id: pre.medicationId,
      name: pre.medicationName,
      dose: pre.dose,
      isPrn: pre.isPrn,
      clientId: pre.clientId,
      clientName: pre.residentName,
      residenceId: pre.residenceId,
      residenceName: pre.residenceName,
      instructions: pre.isPrn ? pre.timeLabel : null,
      scheduleLabel: pre.isPrn ? null : pre.timeLabel,
    );
    _medications = [_medication!];
    if (_client != null) {
      // Refresh chart meds so the dropdown has the full scoped list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onClientChanged(_client);
      });
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _clinicalNotes.dispose();
    _why.dispose();
    _bp.dispose();
    _hr.dispose();
    _temp.dispose();
    _sugar.dispose();
    super.dispose();
  }

  bool get _isAdministered => _status.status == 'administered';

  bool get _safetyOk =>
      _safetyConfirmed &&
      _identityVerified &&
      _medicationVerified &&
      _dosageVerified &&
      _routeVerified &&
      _timeVerified;

  DueDose? get _resolvedDose {
    final med = _medication;
    final client = _client;
    if (med == null || client == null) return null;
    return DueDose(
      id: '${med.isPrn ? 'prn' : 'med'}-${med.id}',
      residentName: client.name,
      residentInitials: client.name
          .trim()
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .take(2)
          .map((p) => p[0].toUpperCase())
          .join(),
      avatarColor: AvatarPalette.blue,
      medicationName: med.name,
      dose: med.dose,
      route: MedicationRoute.tabletOral,
      timeLabel: med.isPrn
          ? (med.instructions ?? 'PRN / as needed')
          : (med.scheduleLabel ?? ''),
      section: DueDoseSection.dueNow,
      clientId: client.id,
      residenceId: (client.residenceId ?? med.residenceId),
      residenceName: client.residenceName ?? med.residenceName,
      medicationId: med.id,
      isPrn: med.isPrn,
    );
  }

  Future<void> _onClientChanged(StaffMedClientOption? client) async {
    final previous = _medication;
    setState(() {
      _client = client;
      _medication = null;
      _medications = [];
      _banner = null;
    });
    if (client == null) return;
    setState(() => _loadingMeds = true);
    final prescribed = await _repo.getClientMedications(client.id);
    final prn = await _repo.getClientPrnMedications(client.id);
    if (!mounted || _client != client) return;
    final list = <StaffClientMedicationItem>[
      ...?prescribed.value?.where((m) => m.isActive),
      ...?prn.value?.where((m) => m.isActive),
    ];
    final keep = previous != null && previous.clientId == client.id
        ? previous
        : null;
    if (keep != null && !list.contains(keep)) list.insert(0, keep);
    setState(() {
      _medications = list;
      _loadingMeds = false;
      if (keep != null) {
        _medication = list.firstWhere((m) => m == keep);
      } else if (list.length == 1) {
        _medication = list.first;
      }
    });
  }

  String? _validateStep() {
    if (_step == 0) {
      if (_client == null) return 'Resident is required.';
      if (_medication == null) {
        return 'Select a medicine from this resident’s chart.';
      }
      if (!_isAdministered && (_whyReason == null || _whyReason!.isEmpty)) {
        return 'Choose why this dose was not given.';
      }
      return null;
    }
    if (_step == 1 && _isAdministered && !_safetyOk) {
      return 'Confirm pre-administration and all five rights checks.';
    }
    return null;
  }

  void _next() {
    final error = _validateStep();
    if (error != null) {
      setState(() => _banner = error);
      return;
    }
    setState(() => _banner = null);
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }
    final dose = _resolvedDose;
    if (dose == null) return;
    final whyDetail = _why.text.trim();
    String? whyLabel;
    for (final r in _whyReasons) {
      if (r.doseReason == _whyReason) {
        whyLabel = r.label;
        break;
      }
    }
    final notes = [
      if (!_isAdministered && whyLabel != null) whyLabel,
      if (!_isAdministered && whyDetail.isNotEmpty) whyDetail,
      _notes.text.trim(),
    ].where((s) => s.isNotEmpty).join('\n');
    Navigator.of(context).pop(
      StaffRecordAdministrationResult(
        dose: dose,
        status: _status.status,
        doseReason: _isAdministered
            ? null
            : (_whyReason ?? _status.doseReason ?? 'other'),
        safetyConfirmed: _safetyConfirmed,
        identityVerified: _identityVerified,
        medicationVerified: _medicationVerified,
        dosageVerified: _dosageVerified,
        routeVerified: _routeVerified,
        timeVerified: _timeVerified,
        notes: notes,
        clinicalNotes: _clinicalNotes.text.trim(),
        bloodPressure: _bp.text.trim(),
        heartRate: _hr.text.trim(),
        temperature: _temp.text.trim(),
        bloodSugar: _sugar.text.trim(),
        evidencePaths: List.unmodifiable(_evidencePaths),
      ),
    );
  }

  Future<void> _pickEvidence() async {
    try {
      final result = await AppFilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result == null) return;
      setState(() {
        for (final file in result.files) {
          final path = file.path;
          if (path != null &&
              path.isNotEmpty &&
              !_evidencePaths.contains(path)) {
            _evidencePaths.add(path);
          }
        }
      });
    } catch (_) {
      setState(() => _banner = 'Could not open the file picker.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();
    final administeredBy = session.displayName.trim().isEmpty
        ? 'You'
        : session.displayName;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Record Administration',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.infoBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _medication == null ? '0 medicines' : '1 medicine',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: AppColors.infoBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Record what was given, who gave it, and the checks made — one resident, any number of medicines.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  'STEP ${_step + 1} OF ${_steps.length}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.4,
                    color: AppColors.secondaryTeal,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(((_step + 1) / _steps.length) * 100).round()}% complete',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (_step + 1) / _steps.length,
                minHeight: 6,
                backgroundColor: AppColors.scaffoldBackground,
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (i <= _step) {
                          setState(() {
                            _step = i;
                            _banner = null;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: i == _step
                              ? AppColors.activeBackground
                              : AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _steps[i].title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: i == _step
                                ? AppColors.secondaryTeal
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (i < _steps.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          if (_banner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.criticalBackgroundSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.criticalBackground),
                ),
                child: Text(
                  _banner!,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.criticalRed,
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: switch (_step) {
                0 => _buildMedicinesStep(administeredBy),
                1 => _buildSafetyStep(),
                _ => _buildDocsStep(),
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '* Required fields — $_step of ${_steps.length} steps complete',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: _step == 0
                          ? AppColors.criticalRed
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      if (_step > 0)
                        TextButton(
                          onPressed: () => setState(() {
                            _step -= 1;
                            _banner = null;
                          }),
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      Flexible(
                        child: FilledButton(
                          key: Key(
                            _step == 2
                                ? 'staff-mar-confirm-administer'
                                : 'staff-mar-admin-next',
                          ),
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.secondaryTeal,
                          ),
                          child: Text(
                            _step == 0
                                ? 'Next: Safety Check'
                                : _step == 1
                                    ? 'Next: Documentation'
                                    : 'Complete Administration',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesStep(String administeredBy) {
    final nowLabel = TimeOfDay.now().format(context);
    final dateLabel =
        '${DateTime.now().day.toString().padLeft(2, '0')}/'
        '${DateTime.now().month.toString().padLeft(2, '0')}/'
        '${DateTime.now().year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medicines',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose who this round is for, then add every medicine being given.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<StaffMedClientOption>(
          key: ValueKey(_client?.id ?? 'resident'),
          initialValue: _client,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Resident *',
            hintText: 'Search residents',
          ),
          items: [
            for (final c in widget.clients)
              DropdownMenuItem(
                value: c,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              ),
            if (_client != null && !widget.clients.contains(_client))
              DropdownMenuItem(
                value: _client,
                child: Text(_client!.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _onClientChanged,
        ),
        const SizedBox(height: 6),
        const Text(
          'The medicine list below is scoped to whoever is chosen here.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  isDense: true,
                ),
                child: Text(
                  dateLabel,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Time *',
                  isDense: true,
                ),
                child: Text(
                  nowLabel,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Administered By',
            isDense: true,
          ),
          child: Text(
            administeredBy,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MEDICINE 1',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              if (_loadingMeds)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                )
              else
                DropdownButtonFormField<StaffClientMedicationItem>(
                  key: ValueKey(
                    '${_client?.id}-${_medication?.id ?? 'none'}-${_medications.length}',
                  ),
                  initialValue: _medication,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Medication *',
                    hintText: 'Search prescriptions & PRN',
                    isDense: true,
                  ),
                  items: [
                    for (final m in _medications)
                      DropdownMenuItem(
                        value: m,
                        child: Text(
                          m.dose.isEmpty
                              ? '${m.name}${m.isPrn ? ' (PRN)' : ''}'
                              : '${m.name} · ${m.dose}${m.isPrn ? ' (PRN)' : ''}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                  onChanged: _client == null
                      ? null
                      : (value) => setState(() {
                            _medication = value;
                            _banner = null;
                          }),
                ),
              if (_client != null &&
                  !_loadingMeds &&
                  _medications.isEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'No medicines on this resident’s chart yet.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.criticalRed,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Administration Status *',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _statusOptions)
                    ChoiceChip(
                      label: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: _status.status == option.status,
                      onSelected: (_) => setState(() {
                        _status = option;
                        _banner = null;
                        if (option.status == 'administered') {
                          _whyReason = null;
                        } else {
                          _whyReason ??= option.doseReason ?? 'other';
                        }
                      }),
                      selectedColor: AppColors.secondaryTeal,
                      labelStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: _status.status == option.status
                            ? Colors.white
                            : AppColors.textBody,
                      ),
                    ),
                ],
              ),
              if (!_isAdministered) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_whyReason ?? 'why'),
                  initialValue: _whyReason,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Why was it not given? *',
                    hintText: 'Choose a reason',
                    isDense: true,
                  ),
                  items: [
                    for (final r in _whyReasons)
                      DropdownMenuItem(
                        value: r.doseReason,
                        child: Text(
                          r.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _whyReason = value;
                    _banner = null;
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _why,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Extra detail (optional)',
                    hintText: 'Anything else about why it was not given…',
                    alignLabelWithHint: true,
                    isDense: true,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<bool>(
                key: ValueKey(_noWitness),
                initialValue: _noWitness,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Witness (optional)',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text('No witness'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _noWitness = value ?? true),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nobody approved to give medicine is clocked in at this home right now.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clinicalNotes,
                maxLines: 4,
                minLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Clinical notes (optional)',
                  hintText: 'Observation about the resident or the dose…',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyStep() {
    Widget toggle({
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.secondaryTeal,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safety Check',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isAdministered
              ? 'Confirm the point-of-administration checks before recording this round.'
              : 'Safety checks are optional when the dose was not given.',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        toggle(
          title: 'Pre-administration verification',
          subtitle: 'I confirm the checks below have been completed.',
          value: _safetyConfirmed,
          onChanged: (v) => setState(() => _safetyConfirmed = v),
        ),
        toggle(
          title: 'Patient identity verification',
          subtitle: 'Resident confirmed by name and record.',
          value: _identityVerified,
          onChanged: (v) => setState(() => _identityVerified = v),
        ),
        toggle(
          title: 'Medication verification',
          subtitle: 'Drug matches the prescribed order.',
          value: _medicationVerified,
          onChanged: (v) => setState(() => _medicationVerified = v),
        ),
        toggle(
          title: 'Dosage verification',
          subtitle: 'Dose and strength match the prescription.',
          value: _dosageVerified,
          onChanged: (v) => setState(() => _dosageVerified = v),
        ),
        toggle(
          title: 'Route verification',
          subtitle: 'Given by the route prescribed.',
          value: _routeVerified,
          onChanged: (v) => setState(() => _routeVerified = v),
        ),
        toggle(
          title: 'Time verification',
          subtitle: 'Given within the window for this round.',
          value: _timeVerified,
          onChanged: (v) => setState(() => _timeVerified = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bp,
                decoration: const InputDecoration(
                  labelText: 'Blood pressure',
                  hintText: '120/80',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _hr,
                decoration: const InputDecoration(
                  labelText: 'Heart rate',
                  hintText: '72 bpm',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _temp,
                decoration: const InputDecoration(
                  labelText: 'Temperature',
                  hintText: '36.8 °C',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _sugar,
                decoration: const InputDecoration(
                  labelText: 'Blood sugar',
                  hintText: '5.4 mmol/L',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocsStep() {
    final hasEvidence = _evidencePaths.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentation',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Attach supporting evidence and any final notes, per medicine.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickEvidence,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cardBorder,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.secondaryTeal,
                  size: ResponsiveHelper.getResponsiveSize(context, 28),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload supporting evidence',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Filed against the resident in Documents — up to 15MB each.',
                  textAlign: TextAlign.center,
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
        if (hasEvidence) ...[
          const SizedBox(height: 10),
          for (final path in _evidencePaths)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file, size: 18),
              title: Text(
                path.split('/').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
              ),
              trailing: IconButton(
                onPressed: () => setState(() => _evidencePaths.remove(path)),
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
        ],
        const SizedBox(height: 12),
        TextField(
          key: const Key('staff-mar-admin-notes'),
          controller: _notes,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Anything worth recording about this dose…',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
