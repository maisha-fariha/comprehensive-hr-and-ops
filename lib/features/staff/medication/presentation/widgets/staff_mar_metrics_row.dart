import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_medication_overview.dart';

/// Web-parity metric strip: Scheduled / Administered / Missed / Compliance.
class StaffMarMetricsRow extends StatelessWidget {
  final StaffMedicationOverview overview;

  const StaffMarMetricsRow({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 8);
    final compliance = overview.complianceRate;
    final complianceLabel =
        compliance == null ? '—' : '${compliance.round()}%';

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        _MetricCard(
          label: 'Scheduled Today',
          value: '${overview.scheduledCount}',
          subtitle: 'across all residences',
          accent: AppColors.secondaryTeal,
        ),
        _MetricCard(
          label: 'Administered',
          value: '${overview.administeredCount}',
          subtitle: overview.unscheduledCount > 0
              ? '${overview.unscheduledCount} outside a round'
              : 'all on the round',
          accent: const Color(0xFF059669),
        ),
        _MetricCard(
          label: 'Missed / Overdue',
          value: '${overview.missedOrOverdueCount}',
          subtitle: 'requires follow-up',
          accent: AppColors.criticalRed,
        ),
        _MetricCard(
          label: 'Compliance Rate',
          value: complianceLabel,
          subtitle: "of today's scheduled doses",
          accent: AppColors.textMuted,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accent;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width -
            ResponsiveHelper.getResponsiveWidth(context, 40) -
            ResponsiveHelper.getResponsiveWidth(context, 8)) /
        2;

    return Container(
      width: width.clamp(140, 220),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w800,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
              color: AppColors.textHeading,
              height: 1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
