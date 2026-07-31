import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/medication_alert.dart';
import '../../domain/entities/medication_dose.dart';
import '../../domain/entities/medication_stat_tile_data.dart';
import 'due_today_section.dart';
import 'medication_stat_tile.dart';
import 'missed_refused_alerts_section.dart';

/// Content of the "Overview" tab: the 2x2 compliance/due/missed/refused
/// stat grid, the "Due Today" card and the "Missed / Refused Alerts" card.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // A fixed 2-column grid, matching the source design; keep the
            // exact same structure across breakpoints (see
            // `TodaysOverviewSection` on the Dashboard for precedent) and
            // size the row extent explicitly instead of `childAspectRatio`
            // so cards never starve for height if the rendered column
            // width drifts slightly from the reference.
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 10),
            crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 10),
            mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 74),
          ),
          itemBuilder: (context, index) => MedicationStatTile(stat: stats[index]),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
        DueTodaySection(doses: dueTodayDoses, moreCount: moreDueTodayCount),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
        MissedRefusedAlertsSection(
          alerts: missedRefusedAlerts,
          totalCount: missedRefusedAlertCount,
        ),
      ],
    );
  }
}
