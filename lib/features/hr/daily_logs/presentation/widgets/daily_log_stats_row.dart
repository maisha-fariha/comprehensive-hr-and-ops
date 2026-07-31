import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/daily_log_summary_stat.dart';
import 'daily_log_stat_tile.dart';

/// The row of 3 equal-width summary stat tiles shown at the top of every
/// Daily Logs tab.
class DailyLogStatsRow extends StatelessWidget {
  final List<DailyLogSummaryStat> stats;

  const DailyLogStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i != 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(child: DailyLogStatTile(stat: stats[i])),
        ],
      ],
    );
  }
}
