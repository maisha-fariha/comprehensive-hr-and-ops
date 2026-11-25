import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../hr/medication/presentation/medication_labels.dart';
import '../../domain/entities/staff_medication_overview.dart';

/// Compact web KPI strip: Scheduled / Administered / Missed / Compliance.
class StaffMarMetricsRow extends StatelessWidget {
  final StaffMedicationOverview overview;

  const StaffMarMetricsRow({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 8);
    final compliance = overview.complianceRate;
    final tiles = [
      _Tile(
        key: const ValueKey('mar-kpi-scheduled'),
        icon: Icons.event_note_rounded,
        tone: MarTone.info,
        value: '${overview.scheduledCount}',
        label: 'Scheduled',
        caption: 'today',
      ),
      _Tile(
        key: const ValueKey('mar-kpi-administered'),
        icon: Icons.check_circle_outline_rounded,
        tone: MarTone.success,
        value: '${overview.administeredCount}',
        label: 'Administered',
        caption: overview.unscheduledCount > 0
            ? '${overview.unscheduledCount} outside a round'
            : 'all on the round',
        captionTone: true,
      ),
      _Tile(
        key: const ValueKey('mar-kpi-missed'),
        icon: Icons.warning_amber_rounded,
        tone: MarTone.danger,
        value: '${overview.missedOrOverdueCount}',
        label: 'Missed',
        caption: 'follow-up',
        captionTone: true,
      ),
      _Tile(
        key: const ValueKey('mar-kpi-compliance'),
        icon: Icons.percent_rounded,
        tone: MarTone.purple,
        value: compliance == null ? '—' : '${compliance.round()}%',
        label: 'Compliance',
        caption: 'today',
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                SizedBox(width: gap),
                Expanded(child: tiles[i + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final MarTone tone;
  final String value;
  final String label;
  final String caption;
  final bool captionTone;

  const _Tile({
    super.key,
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
    required this.caption,
    this.captionTone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: tone.foreground),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textHeading,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight:
                        captionTone ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 10.5,
                    color: captionTone ? tone.foreground : AppColors.textMuted,
                    height: 1.2,
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
