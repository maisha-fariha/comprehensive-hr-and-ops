import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/medication_alert.dart';
import 'medication_alert_tile.dart';
import 'medication_count_badge.dart';

/// The Overview tab's "Missed / Refused Alerts" card.
class MissedRefusedAlertsSection extends StatelessWidget {
  final List<MedicationAlert> alerts;
  final int totalCount;
  final ValueChanged<MedicationAlert>? onAlertTap;

  const MissedRefusedAlertsSection({
    super.key,
    required this.alerts,
    required this.totalCount,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, left: 17, right: 17, top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderRow(
            title: 'Missed / Refused Alerts',
            trailing: MedicationCountBadge(
              count: totalCount,
              background: AppColors.criticalBackground,
              foreground: AppColors.criticalRed,
            ),
          ),
          for (var i = 0; i < alerts.length; i++)
            MedicationAlertTile(
              alert: alerts[i],
              showDivider: i != alerts.length - 1,
              onTap: onAlertTap == null ? null : () => onAlertTap!(alerts[i]),
            ),
        ],
      ),
    );
  }
}
