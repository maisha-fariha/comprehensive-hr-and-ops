import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/medication_stat_tile_data.dart';
import '../../domain/entities/missed_medication.dart';
import 'medication_stat_tile.dart';
import 'missed_medication_card.dart';

/// Content of the "Missed" tab: 2-tile stat row + "Missed Medications" list.
/// Matched to the Missed tab reference.
class MissedTabView extends StatelessWidget {
  final List<MedicationStatTileData> stats;
  final List<MissedMedication> medications;

  static const Color _badgeSoft = Color(0xFFFBEDED);
  static const Color _badgeFg = Color(0xFFD64545);

  const MissedTabView({
    super.key,
    required this.stats,
    required this.medications,
  });

  @override
  Widget build(BuildContext context) {
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);

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
                mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 10),
                crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 10),
                mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 78),
              ),
              itemBuilder: (context, index) => MedicationStatTile(stat: stats[index]),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Missed Medications',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                _SoftCountBadge(count: medications.length),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (var i = 0; i < medications.length; i++) ...[
              if (i > 0) SizedBox(height: cardGap),
              MissedMedicationCard(medication: medications[i]),
            ],
          ],
        );
      },
    );
  }
}

class _SoftCountBadge extends StatelessWidget {
  final int count;

  const _SoftCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 22);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: MissedTabView._badgeSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: MissedTabView._badgeFg,
          height: 1,
        ),
      ),
    );
  }
}
