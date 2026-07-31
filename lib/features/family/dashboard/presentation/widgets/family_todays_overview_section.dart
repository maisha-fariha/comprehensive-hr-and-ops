import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/family_overview_stat.dart';
import 'family_overview_stat_card.dart';

/// "Today's Overview" heading + the 2-column stat grid beneath it.
class FamilyTodaysOverviewSection extends StatelessWidget {
  final List<FamilyOverviewStat> stats;
  final String lastUpdatedLabel;
  final ValueChanged<FamilyOverviewStat>? onStatTap;

  const FamilyTodaysOverviewSection({
    super.key,
    required this.stats,
    required this.lastUpdatedLabel,
    this.onStatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(
          title: "Today's Overview",
          trailing: Text(
            lastUpdatedLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // The reference design uses a fixed 2-column stat grid; keep that
            // exact structure on tablets too (rather than adding more columns)
            // and let `ResponsiveHelper`'s own tablet clamps scale the cards
            // up, so the design isn't altered across breakpoints.
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 12),
            crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 12),
            mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 180),
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return FamilyOverviewStatCard(
              stat: stat,
              onTap: onStatTap == null ? null : () => onStatTap!(stat),
            );
          },
        ),
      ],
    );
  }
}
