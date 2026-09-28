import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/due_dose.dart';

/// Multi-step Record Administration dialog matching web MAR nested wizard
/// (BUG_Report018/019): Medicines → Safety Check → Documentation.
class StaffAdministerDoseDialog extends StatefulWidget {
  final DueDose dose;

  const StaffAdministerDoseDialog({super.key, required this.dose});

  static Future<StaffAdministerDoseResult?> show(
    BuildContext context, {
    required DueDose dose,
  }) {
    return showModalBottomSheet<StaffAdministerDoseResult>(
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
  final bool safetyConfirmed;
  final bool identityVerified;
  final bool medicationVerified;
  final bool dosageVerified;
  final bool routeVerified;
  final bool timeVerified;
  final String notes;
  final String bloodPressure;
  final String heartRate;
  final String temperature;
  final String bloodSugar;

  const StaffAdministerDoseResult({
    required this.safetyConfirmed,
    required this.identityVerified,
    required this.medicationVerified,
    required this.dosageVerified,
    required this.routeVerified,
    required this.timeVerified,
    required this.notes,
    required this.bloodPressure,
    required this.heartRate,
    required this.temperature,
    required this.bloodSugar,
  });
}

class _StaffAdministerDoseDialogState extends State<StaffAdministerDoseDialog> {
  int _step = 0;
  bool _safetyConfirmed = false;
  bool _identityVerified = false;
  bool _medicationVerified = false;
  bool _dosageVerified = false;
  bool _routeVerified = false;
  bool _timeVerified = false;
  final _notes = TextEditingController();
  final _bp = TextEditingController();
  final _hr = TextEditingController();
  final _temp = TextEditingController();
  final _sugar = TextEditingController();

  static const _steps = ['Medicines', 'Safety Check', 'Documentation'];

  @override
  void dispose() {
    _notes.dispose();
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

  void _next() {
    if (_step == 1 && !_safetyOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Confirm pre-administration and all five rights checks.',
          ),
        ),
      );
      return;
    }
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }
    Navigator.of(context).pop(
      StaffAdministerDoseResult(
        safetyConfirmed: _safetyConfirmed,
        identityVerified: _identityVerified,
        medicationVerified: _medicationVerified,
        dosageVerified: _dosageVerified,
        routeVerified: _routeVerified,
        timeVerified: _timeVerified,
        notes: _notes.text.trim(),
        bloodPressure: _bp.text.trim(),
        heartRate: _hr.text.trim(),
        temperature: _temp.text.trim(),
        bloodSugar: _sugar.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Record administration',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textHeading,
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: i == _step
                              ? AppColors.activeBackground
                              : AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _steps[i],
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
                    if (i < _steps.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: switch (_step) {
                  0 => _MedicinesStep(dose: widget.dose),
                  1 => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confirm the point-of-administration checks before recording this round.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Toggle(
                          title: 'Pre-administration verification',
                          subtitle:
                              'I confirm the checks below have been completed.',
                          value: _safetyConfirmed,
                          onChanged: (v) =>
                              setState(() => _safetyConfirmed = v),
                        ),
                        _Toggle(
                          title: 'Patient identity verification',
                          subtitle: 'Resident confirmed by name and record.',
                          value: _identityVerified,
                          onChanged: (v) =>
                              setState(() => _identityVerified = v),
                        ),
                        _Toggle(
                          title: 'Medication verification',
                          subtitle: 'Drug matches the prescribed order.',
                          value: _medicationVerified,
                          onChanged: (v) =>
                              setState(() => _medicationVerified = v),
                        ),
                        _Toggle(
                          title: 'Dosage verification',
                          subtitle:
                              'Dose and strength match the prescription.',
                          value: _dosageVerified,
                          onChanged: (v) =>
                              setState(() => _dosageVerified = v),
                        ),
                        _Toggle(
                          title: 'Route verification',
                          subtitle: 'Given by the route prescribed.',
                          value: _routeVerified,
                          onChanged: (v) => setState(() => _routeVerified = v),
                        ),
                        _Toggle(
                          title: 'Time verification',
                          subtitle: 'Given within the window for this round.',
                          value: _timeVerified,
                          onChanged: (v) => setState(() => _timeVerified = v),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bp,
                          decoration: const InputDecoration(
                            labelText: 'Blood pressure',
                            hintText: '120/80',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _hr,
                          decoration: const InputDecoration(
                            labelText: 'Heart rate',
                            hintText: '72 bpm',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _temp,
                          decoration: const InputDecoration(
                            labelText: 'Temperature',
                            hintText: '36.8 °C',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _sugar,
                          decoration: const InputDecoration(
                            labelText: 'Blood sugar',
                            hintText: '5.4 mmol/L',
                          ),
                        ),
                      ],
                    ),
                  _ => _DocsStep(notes: _notes, safetyOk: _safetyOk),
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: () => setState(() => _step -= 1),
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    FilledButton(
                      key: Key(
                        _step == 2
                            ? 'staff-mar-confirm-administer'
                            : 'staff-mar-admin-next',
                      ),
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal,
                      ),
                      child: Text(_step == 2 ? 'Confirm & Record' : 'Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicinesStep extends StatelessWidget {
  final DueDose dose;

  const _MedicinesStep({required this.dose});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resident & every medicine given',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'The medicine list is scoped to whoever is chosen as the resident, so the two cannot disagree.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        _InfoRow(label: 'Resident', value: dose.residentName),
        _InfoRow(
          label: 'Medication',
          value: '${dose.medicationName} ${dose.dose}',
        ),
        _InfoRow(label: 'When', value: dose.timeLabel),
        if (dose.isPrn) const _InfoRow(label: 'Type', value: 'As needed (PRN)'),
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
            width: ResponsiveHelper.getResponsiveWidth(context, 100),
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

  const _DocsStep({required this.notes, required this.safetyOk});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidence & final notes',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('staff-mar-admin-notes'),
          controller: notes,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Clinical Notes (optional)',
            hintText: 'Any observations at the time of administration…',
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
              const _CheckLine(
                label: 'Resident and medicines confirmed',
                done: true,
              ),
              const _CheckLine(
                label: 'Administration details recorded',
                done: true,
              ),
              _CheckLine(
                label: 'Safety verification passed',
                done: safetyOk,
              ),
              const _CheckLine(
                label: 'Supporting evidence attached',
                done: false,
                trailing: 'Optional',
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
