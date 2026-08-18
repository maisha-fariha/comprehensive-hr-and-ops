import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_overview_stat.dart';
import 'staff_overview_stat_card.dart';

/// "Today's Overview" heading + the 2-column stat grid beneath it.
class StaffOverviewSection extends StatelessWidget {
  final List<StaffOverviewStat> stats;
  final ValueChanged<StaffOverviewStat>? onStatTap;

  const StaffOverviewSection({super.key, required this.stats, this.onStatTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Today's Overview",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 12),
            crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 12),
            mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 142),
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StaffOverviewStatCard(
              stat: stat,
              onTap: onStatTap == null ? null : () => onStatTap!(stat),
            );
          },
        ),
      ],
    );
  }
}
