import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/medication_stat_tile_data.dart';
import '../../domain/entities/missed_medication.dart';
import 'medication_count_badge.dart';
import 'medication_stat_tile.dart';
import 'missed_medication_card.dart';

/// Content of the "Missed" tab: the 2-tile stat row, then the "Missed
/// Medications" list.
class MissedTabView extends StatelessWidget {
  final List<MedicationStatTileData> stats;
  final List<MissedMedication> medications;

  const MissedTabView({super.key, required this.stats, required this.medications});

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
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 10),
            crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 10),
            mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 74),
          ),
          itemBuilder: (context, index) => MedicationStatTile(stat: stats[index]),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
        SectionHeaderRow(
          title: 'Missed Medications',
          trailing: MedicationCountBadge(
            count: medications.length,
            background: AppColors.criticalBackground,
            foreground: AppColors.criticalRed,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < medications.length; i++) ...[
          MissedMedicationCard(medication: medications[i]),
          if (i != medications.length - 1)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        ],
      ],
    );
  }
}
