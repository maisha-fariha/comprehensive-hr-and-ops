import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import '../admissions_labels.dart';
import 'admissions_common.dart';

/// One web referrals table row laid out as a card: Referral, Stage,
/// Preferred, Waiting, Priority, Received and the write actions.
class ReferralCard extends StatelessWidget {
  final Referral referral;

  /// Null when the preferred residence is not in the caller's options.
  final String? preferredName;
  final bool canWrite;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onAdmit;
  final VoidCallback onDecline;
  final VoidCallback onDelete;

  const ReferralCard({
    super.key,
    required this.referral,
    required this.preferredName,
    required this.canWrite,
    required this.onOpen,
    required this.onEdit,
    required this.onAdmit,
    required this.onDecline,
    required this.onDelete,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = referral;
    final preferred = r.preferredResidenceId == null
        ? 'Not stated'
        : preferredName ?? 'Outside your access';
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        child: InkWell(
          key: ValueKey('referral-open-${r.id}'),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 10),
          ),
          onTap: onOpen,
          child: Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 10),
              ),
              border: Border.all(color: AppColors.cardBorder),
            ),
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
                            r.fullName,
                            style: handoverText(
                              context,
                              14.5,
                              weight: FontWeight.w600,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.source == null
                                ? 'No source recorded'
                                : 'via ${r.source}',
                            style: handoverText(
                              context,
                              12,
                              color: AppColors.infoBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdmissionPill(
                      label: WebFormat.humanise(r.status),
                      tone: AdmissionsLabels.stageTone(r.status),
                      dot: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _Cell('Preferred', preferred),
                    _Cell(
                      'Waiting',
                      r.waitlistedAt == null
                          ? '—'
                          : AdmissionsLabels.waiting(r.waitlistedAt),
                      color: r.waitlistedAt == null
                          ? AppColors.infoBlue
                          : AppColors.urgentAmber,
                      weight: r.waitlistedAt == null
                          ? FontWeight.w400
                          : FontWeight.w500,
                    ),
                    _Cell('Priority', '${r.priority ?? 0}'),
                    _Cell('Received', WebFormat.date(r.createdAt)),
                  ],
                ),
                if (canWrite) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!r.isClosed) ...[
                        Semantics(
                          label: 'Edit referral',
                          child: HandoverButton(
                            key: ValueKey('referral-edit-${r.id}'),
                            label: '',
                            icon: Icons.edit_outlined,
                            compact: true,
                            onPressed: busy ? null : onEdit,
                          ),
                        ),
                        HandoverButton(
                          key: ValueKey('referral-admit-${r.id}'),
                          label: 'Admit',
                          icon: Icons.assignment_turned_in_outlined,
                          compact: true,
                          onPressed: busy ? null : onAdmit,
                        ),
                        HandoverButton(
                          key: ValueKey('referral-decline-${r.id}'),
                          label: 'Decline',
                          icon: Icons.cancel_outlined,
                          foreground: AppColors.criticalRed,
                          compact: true,
                          onPressed: busy ? null : onDecline,
                        ),
                      ],
                      Semantics(
                        label: 'Delete referral',
                        child: HandoverButton(
                          key: ValueKey('referral-delete-${r.id}'),
                          label: '',
                          icon: Icons.delete_outline_rounded,
                          foreground: AppColors.criticalRed,
                          compact: true,
                          onPressed: busy ? null : onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final FontWeight weight;

  const _Cell(
    this.label,
    this.value, {
    this.color = AppColors.textHeading,
    this.weight = FontWeight.w400,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: handoverText(
            context,
            10.5,
            weight: FontWeight.w600,
            color: AppColors.textMuted,
          ).copyWith(letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(value, style: handoverText(context, 13, weight: weight, color: color)),
      ],
    );
  }
}
