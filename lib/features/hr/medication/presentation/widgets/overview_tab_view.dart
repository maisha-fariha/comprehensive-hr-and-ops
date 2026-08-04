import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/medication_alert.dart';
import '../../domain/entities/medication_dose.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/medication_stat_tile_data.dart';
import 'due_today_section.dart';
import 'missed_refused_alerts_section.dart';

/// Content of the "Overview" tab: the 2x2 compliance/due/missed/refused
/// stat grid, the "Due Today" section and the "Missed / Refused Alerts"
/// section — layout matched to the Medication MAR Overview reference.
class OverviewTabView extends StatelessWidget {
  final List<MedicationStatTileData> stats;
  final List<MedicationDose> dueTodayDoses;
  final int moreDueTodayCount;
  final List<MedicationAlert> missedRefusedAlerts;
  final int missedRefusedAlertCount;

  const OverviewTabView({
    super.key,
    required this.stats,
    required this.dueTodayDoses,
    required this.moreDueTodayCount,
    required this.missedRefusedAlerts,
    required this.missedRefusedAlertCount,
  });

  @override
  Widget build(BuildContext context) {
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);
    final gridGap = ResponsiveHelper.getResponsiveWidth(context, 10);
    final gridRowGap = ResponsiveHelper.getResponsiveHeight(context, 10);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: gridRowGap,
                crossAxisSpacing: gridGap,
                mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 78),
              ),
              itemBuilder: (context, index) => _OverviewStatTile(stat: stats[index]),
            ),
            SizedBox(height: sectionGap),
            DueTodaySection(doses: dueTodayDoses, moreCount: moreDueTodayCount),
            SizedBox(height: sectionGap),
            MissedRefusedAlertsSection(
              alerts: missedRefusedAlerts,
              totalCount: missedRefusedAlertCount,
            ),
          ],
        );
      },
    );
  }
}

class _StatVisual {
  final String svgAsset;
  final Color accent;
  final Color iconBackground;

  const _StatVisual({
    required this.svgAsset,
    required this.accent,
    required this.iconBackground,
  });
}

_StatVisual _visualFor(MedicationStatTag tag) {
  switch (tag) {
    case MedicationStatTag.compliance:
    case MedicationStatTag.needsFollowUp:
      return const _StatVisual(
        svgAsset: 'assets/icons/medication/medication_compliance.svg',
        accent: Color(0xFF2E8C58),
        iconBackground: Color(0xFFEAF6F0),
      );
    case MedicationStatTag.dueToday:
      return const _StatVisual(
        svgAsset: 'assets/icons/medication/medication_clock.svg',
        accent: Color(0xFF2A5DA6),
        iconBackground: Color(0xFFEAF0F9),
      );
    case MedicationStatTag.missedCount:
    case MedicationStatTag.missedToday:
    case MedicationStatTag.criticalMissed:
      return const _StatVisual(
        svgAsset: 'assets/icons/medication/medication_cross_circle.svg',
        accent: Color(0xFFD64545),
        iconBackground: Color(0xFFFBEDED),
      );
    case MedicationStatTag.refusedCount:
    case MedicationStatTag.totalRefused:
      return const _StatVisual(
        svgAsset: 'assets/icons/medication/medication_refused.svg',
        accent: Color(0xFFC7761B),
        iconBackground: Color(0xFFFBF1E6),
      );
  }
}

/// Single overview stat card: circular icon + colored value + muted label.
class _OverviewStatTile extends StatelessWidget {
  final MedicationStatTileData stat;

  const _OverviewStatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(stat.tag);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: visual.iconBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(visual.svgAsset, size: 19, color: visual.accent),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    color: visual.accent,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textSecondary,
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
