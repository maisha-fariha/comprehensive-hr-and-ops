import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/due_dose.dart';
import '../../../../../core/media/app_file_picker.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Multi-step Record Administration dialog matching web MAR nested wizard:
/// Medicines → Safety Check → Documentation (left stepper + live preview).
class StaffAdministerDoseDialog extends StatefulWidget {
  final DueDose dose;

  const StaffAdministerDoseDialog({super.key, required this.dose});

  static Future<StaffAdministerDoseResult?> show(
    BuildContext context, {
    required DueDose dose,
  }) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return showAppPopup<StaffAdministerDoseResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AppSheetPanel(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 1100,
            height: MediaQuery.sizeOf(context).height * 0.9,
            child: StaffAdministerDoseDialog(dose: dose),
          ),
        ),
      );
    }
    return showAppBottomSheet<StaffAdministerDoseResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StaffAdministerDoseDialog(dose: dose),
    );
  }

  @override
  State<StaffAdministerDoseDialog> createState() =>
      _StaffAdministerDoseDialogState();
}

class StaffAdministerDoseResult {
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

  const StaffAdministerDoseResult({
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

class _AdminStatusOption {
  final String label;
  final String status;
  final String? doseReason;

  const _AdminStatusOption({
    required this.label,
    required this.status,
    this.doseReason,
  });
}

class _StaffAdministerDoseDialogState extends State<StaffAdministerDoseDialog> {
  int _step = 0;
  String? _banner;
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

  static const _statusOptions = <_AdminStatusOption>[
    _AdminStatusOption(label: 'Administered', status: 'administered'),
    _AdminStatusOption(
      label: 'Refused',
      status: 'refused',
      doseReason: 'patient_refused',
    ),
    _AdminStatusOption(
      label: 'Withheld',
      status: 'withheld',
      doseReason: 'clinical_hold',
    ),
    _AdminStatusOption(
      label: 'Not available',
      status: 'not_available',
      doseReason: 'drug_unavailable',
    ),
    _AdminStatusOption(
      label: 'Missed',
      status: 'missed',
      doseReason: 'other',
    ),
  ];

  _AdminStatusOption _status = _statusOptions.first;

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

  bool get _safetyOk =>
      _safetyConfirmed &&
      _identityVerified &&
      _medicationVerified &&
      _dosageVerified &&
      _routeVerified &&
      _timeVerified;

  bool get _isAdministered => _status.status == 'administered';

  /// Steps fully completed (prior to current). Matches web footer wording.
  int get _stepsComplete => _step;

  double get _progressPct => ((_step + 1) / _steps.length) * 100;

  String get _nextLabel {
    if (_step == 0) return 'Next: Safety Check';
    if (_step == 1) return 'Next: Documentation';
    return 'Complete Administration';
  }

  String? _validateStep() {
    if (_step == 0) {
      if (!_isAdministered && _why.text.trim().isEmpty) {
        return 'Please explain why this dose was not administered.';
      }
      return null;
    }
    if (_step == 1 && _isAdministered && !_safetyOk) {
      return 'Confirm pre-administration and all five rights checks.';
    }
    return null;
  }

  void _goToStep(int index) {
    if (index < 0 || index > _step) return;
    setState(() {
      _step = index;
      _banner = null;
    });
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
    final why = _why.text.trim();
    Navigator.of(context).pop(
      StaffAdministerDoseResult(
        status: _status.status,
        doseReason: _isAdministered ? null : (_status.doseReason ?? 'other'),
        safetyConfirmed: _safetyConfirmed,
        identityVerified: _identityVerified,
        medicationVerified: _medicationVerified,
        dosageVerified: _dosageVerified,
        routeVerified: _routeVerified,
        timeVerified: _timeVerified,
        notes: [
          if (why.isNotEmpty && !_isAdministered) why,
          _notes.text.trim(),
        ].where((s) => s.isNotEmpty).join('\n'),
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final session = Get.find<UserSession>();
    final administeredBy = session.displayName.trim().isEmpty
        ? 'You'
        : session.displayName;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: wide ? null : MediaQuery.sizeOf(context).height * 0.92,
        child: Column(
          children: [
            if (!wide) ...[
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
            _Header(
              dose: widget.dose,
              onClose: () => Navigator.pop(context),
            ),
            if (_banner != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ValidationBanner(
                  message: _banner!,
                  onClose: () => setState(() => _banner = null),
                ),
              ),
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 220,
                          child: _LeftStepper(
                            step: _step,
                            steps: _steps,
                            progressPct: _progressPct,
                            onStepTap: _goToStep,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _buildStepBody(administeredBy)),
                        const VerticalDivider(width: 1),
                        SizedBox(
                          width: 280,
                          child: _MarLivePreview(
                            dose: widget.dose,
                            administeredBy: administeredBy,
                            statusLabel: _status.label,
                            safetyConfirmed: _safetyConfirmed,
                            identityVerified: _identityVerified,
                            medicationVerified: _medicationVerified,
                            dosageVerified: _dosageVerified,
                            routeVerified: _routeVerified,
                            timeVerified: _timeVerified,
                            safetyOk: _isAdministered ? _safetyOk : true,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _CompactProgress(
                          step: _step,
                          steps: _steps,
                          progressPct: _progressPct,
                          onStepTap: _goToStep,
                        ),
                        Expanded(child: _buildStepBody(administeredBy)),
                      ],
                    ),
            ),
            _Footer(
              stepsComplete: _stepsComplete,
              totalSteps: _steps.length,
              nextLabel: _nextLabel,
              showBack: _step > 0,
              onCancel: () => Navigator.pop(context),
              onBack: () => setState(() {
                _step -= 1;
                _banner = null;
              }),
              onNext: _next,
              isLast: _step == 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(String administeredBy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: switch (_step) {
        0 => _MedicinesStep(
            dose: widget.dose,
            administeredBy: administeredBy,
            status: _status,
            statusOptions: _statusOptions,
            onStatusChanged: (value) {
              if (value == null) return;
              setState(() {
                _status = value;
                _banner = null;
              });
            },
            whyController: _why,
            clinicalNotes: _clinicalNotes,
            showWhy: !_isAdministered,
          ),
        1 => _SafetyStep(
            isAdministered: _isAdministered,
            safetyConfirmed: _safetyConfirmed,
            identityVerified: _identityVerified,
            medicationVerified: _medicationVerified,
            dosageVerified: _dosageVerified,
            routeVerified: _routeVerified,
            timeVerified: _timeVerified,
            onSafety: (v) => setState(() => _safetyConfirmed = v),
            onIdentity: (v) => setState(() => _identityVerified = v),
            onMedication: (v) => setState(() => _medicationVerified = v),
            onDosage: (v) => setState(() => _dosageVerified = v),
            onRoute: (v) => setState(() => _routeVerified = v),
            onTime: (v) => setState(() => _timeVerified = v),
            bp: _bp,
            hr: _hr,
            temp: _temp,
            sugar: _sugar,
          ),
        _ => _DocsStep(
            notes: _notes,
            safetyOk: _isAdministered ? _safetyOk : true,
            medicinesConfirmed: true,
            detailsRecorded: true,
            evidencePaths: _evidencePaths,
            onPickEvidence: _pickEvidence,
            onRemoveEvidence: (path) {
              setState(() => _evidencePaths.remove(path));
            },
          ),
      },
    );
  }
}

class _Header extends StatelessWidget {
  final DueDose dose;
  final VoidCallback onClose;

  const _Header({required this.dose, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: const Icon(
              Icons.link_rounded,
              color: Colors.white,
              size: 20,
            ),
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
                          color: AppColors.textHeading,
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
                      child: const Text(
                        '1 medicine',
                        style: TextStyle(
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
                Text(
                  'Record what was given, who gave it, and the checks made — '
                  '${dose.residentName} · ${dose.medicationName}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}

class _CompactProgress extends StatelessWidget {
  final int step;
  final List<({String title, String subtitle})> steps;
  final double progressPct;
  final ValueChanged<int> onStepTap;

  const _CompactProgress({
    required this.step,
    required this.steps,
    required this.progressPct,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'STEP ${step + 1} OF ${steps.length}',
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
                '${progressPct.round()}% complete',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (step + 1) / steps.length,
              minHeight: 6,
              backgroundColor: AppColors.scaffoldBackground,
              color: AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => onStepTap(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: i == step
                            ? AppColors.activeBackground
                            : AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        steps[i].title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: i == step
                              ? AppColors.secondaryTeal
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LeftStepper extends StatelessWidget {
  final int step;
  final List<({String title, String subtitle})> steps;
  final double progressPct;
  final ValueChanged<int> onStepTap;

  const _LeftStepper({
    required this.step,
    required this.steps,
    required this.progressPct,
    required this.onStepTap,
  });

  static const _icons = [
    Icons.medication_outlined,
    Icons.verified_user_outlined,
    Icons.description_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final tip = switch (step) {
      0 =>
        'The medicine list is scoped to whoever is chosen as the resident, so the two cannot disagree.',
      1 =>
        'The six checks are stored on the administration record for audit.',
      _ =>
        'Evidence is filed against the resident in Documents, where a regulator looks for it.',
    };

    return Container(
      color: AppColors.scaffoldBackground,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            InkWell(
              onTap: () => onStepTap(i),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: i == step ? AppColors.surfaceWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == step
                        ? AppColors.secondaryTeal.withValues(alpha: 0.35)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: i == step
                            ? AppColors.secondaryTeal
                            : (i < step
                                ? AppColors.activeBackground
                                : AppColors.surfaceWhite),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        i < step ? Icons.check_rounded : _icons[i],
                        size: 18,
                        color: i == step
                            ? Colors.white
                            : (i < step
                                ? AppColors.activeGreen
                                : AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].title,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: i == step
                                  ? AppColors.textHeading
                                  : AppColors.textMuted,
                            ),
                          ),
                          Text(
                            steps[i].subtitle,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < steps.length - 1) const SizedBox(height: 6),
          ],
          const Spacer(),
          Text(
            'PROGRESS · STEP ${step + 1} OF ${steps.length}',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (step + 1) / steps.length,
              minHeight: 6,
              backgroundColor: AppColors.cardBorder,
              color: AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${progressPct.round()}% complete',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppColors.secondaryTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarLivePreview extends StatelessWidget {
  final DueDose dose;
  final String administeredBy;
  final String statusLabel;
  final bool safetyConfirmed;
  final bool identityVerified;
  final bool medicationVerified;
  final bool dosageVerified;
  final bool routeVerified;
  final bool timeVerified;
  final bool safetyOk;

  const _MarLivePreview({
    required this.dose,
    required this.administeredBy,
    required this.statusLabel,
    required this.safetyConfirmed,
    required this.identityVerified,
    required this.medicationVerified,
    required this.dosageVerified,
    required this.routeVerified,
    required this.timeVerified,
    required this.safetyOk,
  });

  @override
  Widget build(BuildContext context) {
    final residence = dose.residenceName.trim().isEmpty
        ? (dose.residenceId.isEmpty ? '—' : dose.residenceId)
        : dose.residenceName;
    final now = TimeOfDay.now().format(context);

    return Container(
      color: AppColors.scaffoldBackground,
      padding: const EdgeInsets.all(14),
      child: ListView(
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, size: 16),
              SizedBox(width: 6),
              Text(
                'MAR Summary',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              Text(
                'Live preview',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.residentName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                Text(
                  residence,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Administered By · $administeredBy',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  'When · Now ($now)',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '1 MEDICINE',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dose.medicationName,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        dose.dose.isEmpty ? '—' : dose.dose,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.activeBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: AppColors.activeGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              safetyOk
                  ? 'Compliance — Ready to finalize. Review documentation, then complete.'
                  : 'Compliance — Waiting for confirmation. Complete all required fields to finalize this record.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: AppColors.textBody,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PreviewCheck(label: 'Pre-administration', done: safetyConfirmed),
          _PreviewCheck(label: 'Right Resident', done: identityVerified),
          _PreviewCheck(label: 'Right Medication', done: medicationVerified),
          _PreviewCheck(label: 'Right Dose', done: dosageVerified),
          _PreviewCheck(label: 'Right Route', done: routeVerified),
          _PreviewCheck(label: 'Right Time', done: timeVerified),
        ],
      ),
    );
  }
}

class _PreviewCheck extends StatelessWidget {
  final String label;
  final bool done;

  const _PreviewCheck({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: done ? AppColors.infoBlue : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: done ? AppColors.textHeading : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final int stepsComplete;
  final int totalSteps;
  final String nextLabel;
  final bool showBack;
  final bool isLast;
  final VoidCallback onCancel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _Footer({
    required this.stepsComplete,
    required this.totalSteps,
    required this.nextLabel,
    required this.showBack,
    required this.isLast,
    required this.onCancel,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '* Required fields — $stepsComplete of $totalSteps steps complete',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: stepsComplete == 0
                      ? AppColors.criticalRed
                      : AppColors.textMuted,
                ),
              ),
            ),
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
            if (showBack)
              TextButton(onPressed: onBack, child: const Text('Back')),
            const SizedBox(width: 4),
            FilledButton(
              key: Key(
                isLast ? 'staff-mar-confirm-administer' : 'staff-mar-admin-next',
              ),
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
              ),
              child: Text(nextLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ValidationBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.criticalBackgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.criticalBackground),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.criticalRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.criticalRed,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.criticalRed,
          ),
        ],
      ),
    );
  }
}

class _MedicinesStep extends StatelessWidget {
  final DueDose dose;
  final String administeredBy;
  final _AdminStatusOption status;
  final List<_AdminStatusOption> statusOptions;
  final ValueChanged<_AdminStatusOption?> onStatusChanged;
  final TextEditingController whyController;
  final TextEditingController clinicalNotes;
  final bool showWhy;

  const _MedicinesStep({
    required this.dose,
    required this.administeredBy,
    required this.status,
    required this.statusOptions,
    required this.onStatusChanged,
    required this.whyController,
    required this.clinicalNotes,
    required this.showWhy,
  });

  @override
  Widget build(BuildContext context) {
    final residence = dose.residenceName.trim().isEmpty
        ? (dose.residenceId.isEmpty ? '—' : dose.residenceId)
        : dose.residenceName;
    final nowLabel = TimeOfDay.now().format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medicines',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose who this round is for, then confirm every medicine being given.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        _InfoRow(label: 'Resident', value: dose.residentName),
        _InfoRow(label: 'Residence', value: residence),
        _InfoRow(
          label: 'Medication',
          value: dose.dose.isEmpty
              ? dose.medicationName
              : '${dose.medicationName} · ${dose.dose}',
        ),
        _InfoRow(
          label: 'Dose',
          value: dose.dose.isEmpty ? '—' : dose.dose,
        ),
        _InfoRow(
          label: 'Schedule / time',
          value: dose.timeLabel.isEmpty ? '—' : dose.timeLabel,
        ),
        if (dose.isPrn) const _InfoRow(label: 'Type', value: 'As needed (PRN)'),
        _InfoRow(label: 'Administered By', value: administeredBy),
        _InfoRow(label: 'When', value: 'Now ($nowLabel)'),
        const SizedBox(height: 8),
        DropdownButtonFormField<_AdminStatusOption>(
          key: ValueKey(status.status),
          initialValue: status,
          decoration: const InputDecoration(
            labelText: 'Administration Status',
          ),
          items: [
            for (final option in statusOptions)
              DropdownMenuItem(
                value: option,
                child: Text(option.label),
              ),
          ],
          onChanged: onStatusChanged,
        ),
        if (showWhy) ...[
          const SizedBox(height: 12),
          TextField(
            controller: whyController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Why (required)',
              hintText: 'Reason this dose was not administered…',
              alignLabelWithHint: true,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: clinicalNotes,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Clinical notes (optional)',
            hintText: 'Any observations at the time of this round…',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class _SafetyStep extends StatelessWidget {
  final bool isAdministered;
  final bool safetyConfirmed;
  final bool identityVerified;
  final bool medicationVerified;
  final bool dosageVerified;
  final bool routeVerified;
  final bool timeVerified;
  final ValueChanged<bool> onSafety;
  final ValueChanged<bool> onIdentity;
  final ValueChanged<bool> onMedication;
  final ValueChanged<bool> onDosage;
  final ValueChanged<bool> onRoute;
  final ValueChanged<bool> onTime;
  final TextEditingController bp;
  final TextEditingController hr;
  final TextEditingController temp;
  final TextEditingController sugar;

  const _SafetyStep({
    required this.isAdministered,
    required this.safetyConfirmed,
    required this.identityVerified,
    required this.medicationVerified,
    required this.dosageVerified,
    required this.routeVerified,
    required this.timeVerified,
    required this.onSafety,
    required this.onIdentity,
    required this.onMedication,
    required this.onDosage,
    required this.onRoute,
    required this.onTime,
    required this.bp,
    required this.hr,
    required this.temp,
    required this.sugar,
  });

  @override
  Widget build(BuildContext context) {
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
          isAdministered
              ? 'Confirm the point-of-administration checks before recording this round.'
              : 'Safety checks are optional when the dose was not given. You can still record vitals if taken.',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        _Toggle(
          title: 'Pre-administration verification',
          subtitle: 'I confirm the checks below have been completed.',
          value: safetyConfirmed,
          onChanged: onSafety,
        ),
        _Toggle(
          title: 'Patient identity verification',
          subtitle: 'Resident confirmed by name and record.',
          value: identityVerified,
          onChanged: onIdentity,
        ),
        _Toggle(
          title: 'Medication verification',
          subtitle: 'Drug matches the prescribed order.',
          value: medicationVerified,
          onChanged: onMedication,
        ),
        _Toggle(
          title: 'Dosage verification',
          subtitle: 'Dose and strength match the prescription.',
          value: dosageVerified,
          onChanged: onDosage,
        ),
        _Toggle(
          title: 'Route verification',
          subtitle: 'Given by the route prescribed.',
          value: routeVerified,
          onChanged: onRoute,
        ),
        _Toggle(
          title: 'Time verification',
          subtitle: 'Given within the window for this round.',
          value: timeVerified,
          onChanged: onTime,
        ),
        const SizedBox(height: 8),
        const Text(
          'Vitals (optional)',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: bp,
                decoration: const InputDecoration(
                  labelText: 'Blood pressure',
                  hintText: '120/80',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: hr,
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
                controller: temp,
                decoration: const InputDecoration(
                  labelText: 'Temperature',
                  hintText: '36.8 °C',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: sugar,
                decoration: const InputDecoration(
                  labelText: 'Blood sugar',
                  hintText: '5.4 mmol/L',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveWidth(context, 110),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocsStep extends StatelessWidget {
  final TextEditingController notes;
  final bool safetyOk;
  final bool medicinesConfirmed;
  final bool detailsRecorded;
  final List<String> evidencePaths;
  final VoidCallback onPickEvidence;
  final ValueChanged<String> onRemoveEvidence;

  const _DocsStep({
    required this.notes,
    required this.safetyOk,
    required this.medicinesConfirmed,
    required this.detailsRecorded,
    required this.evidencePaths,
    required this.onPickEvidence,
    required this.onRemoveEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvidence = evidencePaths.isNotEmpty;
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
          onTap: onPickEvidence,
          borderRadius: BorderRadius.circular(14),
          child: CustomPaint(
            painter: _DashedBorderPainter(color: AppColors.cardBorder),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
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
                    'Click to upload or drag & drop. Filed against the resident in Documents — up to 15MB each.',
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
        ),
        if (hasEvidence) ...[
          const SizedBox(height: 10),
          for (final path in evidencePaths)
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
                onPressed: () => onRemoveEvidence(path),
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
        ],
        const SizedBox(height: 12),
        TextField(
          key: const Key('staff-mar-admin-notes'),
          controller: notes,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Anything worth recording about this dose…',
            alignLabelWithHint: true,
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
                'Final Review Checklist',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Confirm everything is complete before submitting.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              _CheckLine(
                label: 'Resident and medicines confirmed',
                done: medicinesConfirmed,
              ),
              _CheckLine(
                label: 'Administration details recorded',
                done: detailsRecorded,
              ),
              _CheckLine(
                label: 'Safety verification passed',
                done: safetyOk,
              ),
              _CheckLine(
                label: 'Supporting evidence attached',
                done: hasEvidence,
                trailing: hasEvidence ? null : 'Optional',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckLine extends StatelessWidget {
  final String label;
  final bool done;
  final String? trailing;

  const _CheckLine({
    required this.label,
    required this.done,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? AppColors.activeGreen : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(14),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
