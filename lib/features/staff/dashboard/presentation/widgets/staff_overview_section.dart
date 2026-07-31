import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/section_header_row.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderRow(title: "Today's Overview"),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 12),
            crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 12),
            // Fixed row extent (not `childAspectRatio`) so card height stays
            // independent of the grid's actual column width, matching the
            // HR Dashboard's `TodaysOverviewSection` convention.
            mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 150),
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
