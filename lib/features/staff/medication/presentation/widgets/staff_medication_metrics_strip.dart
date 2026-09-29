import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_medication_overview.dart';

/// Web-parity metric strip: Scheduled / Administered / Missed-Overdue / Compliance.
///
/// Note: **Administered** comes from today's round `summary.administered`
/// (scheduled doses given today). The **Given** tab badge comes from
/// `GET /mar/administrations` history and can be higher — same as web.
class StaffMedicationMetricsStrip extends StatelessWidget {
  final StaffMedicationOverview overview;

  const StaffMedicationMetricsStrip({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final missedLabel = overview.overdueCount > 0
        ? '${overview.missedOrOverdueCount}'
        : '${overview.missedCount}';
    final compliance = overview.complianceRate;
    final complianceLabel = compliance == null
        ? '—'
        : '${compliance % 1 == 0 ? compliance.toInt() : compliance.toStringAsFixed(1)}%';

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        top: 4,
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricChip(
              label: 'Scheduled Today',
              value: '${overview.scheduledCount}',
              color: AppColors.infoBlue,
              background: AppColors.infoBackground,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Expanded(
            child: _MetricChip(
              label: 'Administered',
              value: '${overview.administeredCount}',
              color: AppColors.activeGreen,
              background: AppColors.activeBackground,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Expanded(
            child: _MetricChip(
              label: 'Missed / Overdue',
              value: missedLabel,
              color: AppColors.criticalRed,
              background: AppColors.criticalBackgroundSoft,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Expanded(
            child: _MetricChip(
              label: 'Compliance',
              value: complianceLabel,
              color: AppColors.secondaryTeal,
              background: AppColors.quickActionCreateShiftBg,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color background;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lite side-panel cards: Due Now + Missed/Overdue counts.
class StaffMedicationSideCards extends StatelessWidget {
  final StaffMedicationOverview overview;

  const StaffMedicationSideCards({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SideCard(
              title: 'Due Now',
              count: overview.dueNowDoses.length,
              icon: Icons.schedule_rounded,
              color: AppColors.urgentAmber,
              background: AppColors.urgentBackgroundSoft,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: _SideCard(
              title: 'Missed / Overdue',
              count: overview.missedOrOverdueCount,
              icon: Icons.warning_amber_rounded,
              color: AppColors.criticalRed,
              background: AppColors.criticalBackgroundSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final Color background;

  const _SideCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textMuted,
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

/// Action row: Record Administration + Add medicine.
class StaffMedicationActionRow extends StatelessWidget {
  final VoidCallback onRecordAdministration;
  final VoidCallback onAddMedicine;
  final bool canWrite;

  const StaffMedicationActionRow({
    super.key,
    required this.onRecordAdministration,
    required this.onAddMedicine,
    this.canWrite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              key: const Key('staff-mar-record-admin'),
              onPressed: canWrite ? onRecordAdministration : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.medication_liquid_outlined, size: 18),
              label: const Text(
                'Record Administration',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          OutlinedButton.icon(
            key: const Key('staff-mar-add-medicine'),
            onPressed: canWrite ? onAddMedicine : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondaryTeal,
              side: const BorderSide(color: AppColors.secondaryTeal),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Add medicine',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
