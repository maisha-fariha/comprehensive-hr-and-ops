import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/mar_administration.dart';
import '../medication_labels.dart';
import 'medication_common.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Web "Given" tab: every charted dose with flags, signer, witness and the
/// Correct action.
class MarGivenTab extends StatelessWidget {
  final List<MarAdministration> rows;
  final bool loading;
  final String? error;
  final bool Function(MarAdministration) canCorrect;
  final ValueChanged<MarAdministration> onCorrect;

  const MarGivenTab({
    super.key,
    required this.rows,
    required this.loading,
    required this.error,
    required this.canCorrect,
    required this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && rows.isEmpty) return const MarEmpty('Loading the chart…');
    if (rows.isEmpty) return MarEmpty(error ?? 'Nothing has been charted yet.');
    return Column(
      children: [
        for (final a in rows) ...[
          _GivenCard(
            key: ValueKey('mar-given-${a.id}'),
            row: a,
            canCorrect: canCorrect(a) && !a.isSuperseded,
            onCorrect: () => onCorrect(a),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _GivenCard extends StatelessWidget {
  final MarAdministration row;
  final bool canCorrect;
  final VoidCallback onCorrect;

  const _GivenCard({super.key, required this.row, required this.canCorrect, required this.onCorrect});

  @override
  Widget build(BuildContext context) {
    final a = row;
    final superseded = a.isSuperseded;
    final state = MedicationLabels.outcomeState[a.status];
    final muted = superseded ? AppColors.textMuted : AppColors.textHeading;
    TextStyle flag(Color c) => handoverText(context, 11, weight: FontWeight.w600, color: c);
    return HandoverPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.medicationName,
                      style: handoverText(context, 14, weight: FontWeight.w600, color: AppColors.primaryNavy),
                    ),
                    Text.rich(
                      TextSpan(
                        text: a.dose ?? '',
                        children: [
                          if (a.isControlled)
                            TextSpan(
                              text: ' · Controlled',
                              style: handoverText(context, 12, color: AppColors.urgentAmber),
                            ),
                        ],
                      ),
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              MarPill(
                label: state != null ? MedicationLabels.states[state]! : a.status,
                tone: state != null ? MedicationLabels.stateTone(state) : MarTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            MedicationLabels.shortStamp(a.administeredAt),
            style: handoverText(context, 13, color: muted, decoration: superseded ? TextDecoration.lineThrough : null),
          ),
          if (!superseded && a.wasLate) Text('After its round', style: flag(AppColors.urgentAmber)),
          if (!superseded && a.administeredOnDuty == false)
            Text('Given off duty', style: flag(AppColors.criticalRed)),
          if (!superseded && a.witnessOnDuty == false)
            Text('Witness off duty', style: flag(AppColors.criticalRed)),
          const SizedBox(height: 6),
          Text('Resident: ${a.clientName}', style: handoverText(context, 13, color: muted)),
          Text('Signed: ${a.administeredByName ?? '—'}', style: handoverText(context, 13, color: muted)),
          if (a.witnessName != null)
            Text('Witnessed by ${a.witnessName}', style: handoverText(context, 11.5, color: AppColors.textMuted)),
          if (a.isControlled && a.witnessName == null)
            Text('No witness recorded', style: flag(AppColors.criticalRed)),
          if (a.amendsAdministrationId != null)
            Text(
              'Correction: ${a.amendmentReason ?? ''}',
              style: handoverText(context, 11.5, color: AppColors.textMuted),
            ),
          if (superseded)
            Text('Superseded by a later correction', style: flag(AppColors.textSecondary)),
          if (canCorrect) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: HandoverButton(
                key: ValueKey('mar-correct-${a.id}'),
                label: 'Correct',
                icon: Icons.edit_note_rounded,
                compact: true,
                onPressed: onCorrect,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Web "Correct this record". [onSubmit] returns an error message or null.
Future<void> showMarCorrectDialog(
  BuildContext context, {
  required MarAdministration administration,
  required Future<String?> Function({required String reason, String? status, String? doseReason})
      onSubmit,
}) =>
    showAppPopup<void>(
      context: context,
      builder: (_) => _CorrectDialog(administration: administration, onSubmit: onSubmit),
    );

class _CorrectDialog extends StatefulWidget {
  final MarAdministration administration;
  final Future<String?> Function({required String reason, String? status, String? doseReason})
      onSubmit;

  const _CorrectDialog({required this.administration, required this.onSubmit});

  @override
  State<_CorrectDialog> createState() => _CorrectDialogState();
}

class _CorrectDialogState extends State<_CorrectDialog> {
  final _reason = TextEditingController();
  String _status = '';
  String _doseReason = '';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _losesDose =>
      widget.administration.status == 'administered' &&
      (_status.isEmpty ? widget.administration.status : _status) != 'administered';

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Say what was wrong — a corrected drug chart needs a reason.');
      return;
    }
    if (_losesDose && _doseReason.isEmpty) {
      setState(() => _error = 'Say why the dose was not given.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final status = _status.isNotEmpty && _status != widget.administration.status ? _status : null;
    final error = await widget.onSubmit(
      reason: _reason.text.trim(),
      status: status,
      doseReason: _losesDose && _doseReason.isNotEmpty ? _doseReason : null,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.administration;
    return AppSheetDialog(
      backgroundColor: AppColors.surfaceWhite,
      title: Text('Correct this record', style: handoverText(context, 17, weight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${a.medicationName} for ${a.clientName}. The original is not deleted — this adds a correction that supersedes it, and both stay on the chart.',
              style: handoverText(context, 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            if (_error != null) MarErrorBox(_error!),
            MarSelectField(
              key: const ValueKey('mar-correct-outcome'),
              label: 'What should it say',
              value: _status.isEmpty ? a.status : _status,
              options: MedicationLabels.outcomes,
              placeholder: 'Leave the outcome as it is',
              onChanged: (v) => setState(() => _status = v),
            ),
            if (_losesDose) ...[
              const SizedBox(height: 14),
              MarSelectField(
                key: const ValueKey('mar-correct-dose-reason'),
                label: 'Why was it not given?',
                required: true,
                value: _doseReason,
                options: MedicationLabels.doseReasons,
                placeholder: 'Choose a reason',
                helper: 'Recorded on the dose itself, separately from why the chart is being corrected.',
                onChanged: (v) => setState(() => _doseReason = v),
              ),
            ],
            const SizedBox(height: 14),
            HandoverTextArea(
              key: const ValueKey('mar-correct-reason'),
              label: 'Why it is being corrected',
              controller: _reason,
              placeholder: 'e.g. charted against the wrong resident',
              helper: 'Required. This is what an audit reads alongside the change.',
            ),
          ],
        ),
      ),
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('mar-correct-submit'),
          label: _busy ? 'Recording…' : 'Record correction',
          filled: true,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
