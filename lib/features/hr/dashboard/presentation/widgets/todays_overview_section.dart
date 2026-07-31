import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/overview_stat.dart';
import 'overview_stat_card.dart';

/// "Today's Overview" heading + the 2-column stat grid beneath it.
class TodaysOverviewSection extends StatelessWidget {
  final List<OverviewStat> stats;
  final String lastUpdatedLabel;
  final ValueChanged<OverviewStat>? onStatTap;

  const TodaysOverviewSection({
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
            // Figma specifies a fixed 2-column stat grid; keep that exact
            // structure on tablets too (rather than adding more columns) and
            // let `ResponsiveHelper`'s own tablet clamps scale the cards up,
            // so the design isn't altered across breakpoints.
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 12),
            crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 12),
            // Figma's card height (163) is a fixed value, independent of card
            // width - using `childAspectRatio` here would tie the two
            // together and starve the card of height whenever the grid's
            // actual column width drifts slightly from Figma's reference
            // width, so size the row extent explicitly instead. A couple of
            // extra px absorb sub-pixel text layout rounding, and the fact
            // that `ResponsiveHelper`'s tablet clamps scale font size (up to
            // 1.6x) slightly more aggressively than height/padding (1.4-1.5x).
            mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 180),
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return OverviewStatCard(
              stat: stat,
              onTap: onStatTap == null ? null : () => onStatTap!(stat),
            );
          },
        ),
      ],
    );
  }
}
