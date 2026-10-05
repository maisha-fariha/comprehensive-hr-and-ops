import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/due_dose.dart';
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

/// Web-parity side panels: Due Now + Missed / Overdue (console right column).
class StaffMedicationSideCards extends StatelessWidget {
  final StaffMedicationOverview overview;
  final VoidCallback? onReviewAllMissed;
  final ValueChanged<DueDose>? onChartDue;

  const StaffMedicationSideCards({
    super.key,
    required this.overview,
    this.onReviewAllMissed,
    this.onChartDue,
  });

  @override
  Widget build(BuildContext context) {
    final dueNow = overview.dueNowDoses;
    final missedCount = overview.missedOrOverdueCount;
    final previewDue = dueNow.take(6).toList();

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 0,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        children: [
          _DueNowPanel(
            count: dueNow.length,
            preview: previewDue,
            onChart: onChartDue,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          _MissedOverduePanel(
            count: missedCount,
            onReviewAll: onReviewAllMissed,
          ),
        ],
      ),
    );
  }
}

class _DueNowPanel extends StatelessWidget {
  final int count;
  final List<DueDose> preview;
  final ValueChanged<DueDose>? onChart;

  const _DueNowPanel({
    required this.count,
    required this.preview,
    this.onChart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.textHeading,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Due Now',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.urgentBackgroundSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count pending',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: AppColors.urgentAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (preview.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nothing left to give today.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            for (final dose in preview) ...[
              _DueNowRow(dose: dose, onChart: onChart),
              if (dose != preview.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _DueNowRow extends StatelessWidget {
  final DueDose dose;
  final ValueChanged<DueDose>? onChart;

  const _DueNowRow({required this.dose, this.onChart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.residentName.isEmpty ? 'Resident' : dose.residentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    dose.medicationName,
                    if (dose.dose.isNotEmpty) dose.dose,
                    if (dose.timeLabel.isNotEmpty) dose.timeLabel,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onChart != null)
            TextButton(
              onPressed: () => onChart!(dose),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryTeal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Record',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissedOverduePanel extends StatelessWidget {
  final int count;
  final VoidCallback? onReviewAll;

  const _MissedOverduePanel({required this.count, this.onReviewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppColors.criticalRed,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Missed / Overdue',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.criticalBackgroundSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count alerts',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: AppColors.criticalRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                count == 0
                    ? 'No missed or overdue medications.'
                    : '$count missed or overdue — review the registry.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onReviewAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textHeading,
                side: const BorderSide(color: AppColors.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Review All',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
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

