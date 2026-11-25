import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_outing.dart';
import '../hr_appointments_labels.dart';
import 'hr_appointments_common.dart';

/// One web "Outing requests" card with Approve / Decline when decidable.
class HrOutingCard extends StatelessWidget {
  final HrOuting outing;
  final bool canDecide;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const HrOutingCard({
    super.key,
    required this.outing,
    required this.canDecide,
    required this.busy,
    this.onApprove,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final o = outing;
    final muted = handoverText(context, 12.5, color: AppColors.textMuted);
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Container(
        key: ValueKey('outing-row-${o.id}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.place_outlined,
                    size: 19,
                    color: AppColors.secondaryTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.title,
                        style: handoverText(
                          context,
                          15,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(o.windowLabel, style: muted),
                    ],
                  ),
                ),
                HrAppointmentPill(
                  label: o.statusLabel,
                  tone: HrAppointmentsLabels.outingStatusTone(o.status),
                ),
              ],
            ),
            if ((o.purpose ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                o.purpose!.trim(),
                style: handoverText(context, 13),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip(context, Icons.person_outline_rounded, o.responsibleAdultName),
                _chip(context, Icons.phone_outlined, o.responsibleAdultPhone),
                if (o.transportLabel.isNotEmpty)
                  _chip(context, Icons.directions_car_outlined, o.transportLabel),
                if (o.needsMedicationPack)
                  _chip(
                    context,
                    Icons.medication_outlined,
                    'Medication pack needed',
                    tone: AppColors.secondaryTeal,
                  ),
                if ((o.requesterName ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Asked by ${o.requesterName}',
                      style: muted,
                    ),
                  ),
              ],
            ),
            if ((o.specialInstructions ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Family notes: ${o.specialInstructions}',
                style: muted,
              ),
            ],
            if ((o.decisionNotes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${o.status == 'declined' ? 'Reason' : 'Conditions'}: '
                  '${o.decisionNotes}'
                  '${(o.decidedByName ?? '').isEmpty ? '' : ' — ${o.decidedByName}'}',
                  style: muted,
                ),
              ),
            ],
            if (o.isPending && canDecide) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HandoverButton(
                    key: ValueKey('outing-decline-${o.id}'),
                    label: 'Decline',
                    onPressed: busy ? null : onDecline,
                  ),
                  const SizedBox(width: 8),
                  HandoverButton(
                    key: ValueKey('outing-approve-${o.id}'),
                    label: 'Approve',
                    filled: true,
                    onPressed: busy ? null : onApprove,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label, {
    Color? tone,
  }) {
    final color = tone ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone == null
            ? AppColors.filterButtonBackground
            : tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: handoverText(
              context,
              12,
              weight: tone == null ? FontWeight.w500 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
