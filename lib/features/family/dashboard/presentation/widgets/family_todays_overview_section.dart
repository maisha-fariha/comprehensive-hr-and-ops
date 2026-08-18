import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/family_overview_stat.dart';
import 'family_overview_stat_card.dart';

/// "Today's Overview" heading + the 2×2 stat grid beneath it.
class FamilyTodaysOverviewSection extends StatelessWidget {
  final List<FamilyOverviewStat> stats;
  final String lastUpdatedLabel;
  final ValueChanged<FamilyOverviewStat>? onStatTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _updatedColor = Color(0xFF98A2B3);

  const FamilyTodaysOverviewSection({
    super.key,
    required this.stats,
    required this.lastUpdatedLabel,
    this.onStatTap,
  });

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    final rowGap = ResponsiveHelper.getResponsiveHeight(context, 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's Overview",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: _titleColor,
                height: 1.2,
              ),
            ),
            Spacer(),
            Text(
              lastUpdatedLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: _updatedColor,
                height: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
        ..._buildRows(context, gap, rowGap),
      ],
    );
  }

  List<Widget> _buildRows(BuildContext context, double gap, double rowGap) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += 2) {
      if (i > 0) {
        rows.add(SizedBox(height: rowGap));
      }
      final left = stats[i];
      final hasRight = i + 1 < stats.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FamilyOverviewStatCard(
                  stat: left,
                  onTap: onStatTap == null ? null : () => onStatTap!(left),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: hasRight
                    ? FamilyOverviewStatCard(
                        stat: stats[i + 1],
                        onTap: onStatTap == null ? null : () => onStatTap!(stats[i + 1]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}
