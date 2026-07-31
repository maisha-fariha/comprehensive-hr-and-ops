import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/staff_daily_log_summary_stat.dart';
import 'staff_daily_log_stat_tile.dart';

/// The row of 3 equal-width summary stat tiles shown at the top of every
/// Staff Daily Logs tab.
class StaffDailyLogStatsRow extends StatelessWidget {
  final List<StaffDailyLogSummaryStat> stats;

  const StaffDailyLogStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i != 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(child: StaffDailyLogStatTile(stat: stats[i])),
        ],
      ],
    );
  }
}
