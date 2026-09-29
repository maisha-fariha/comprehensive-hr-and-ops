import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/staff_daily_log_summary_stat.dart';
import 'staff_daily_log_stat_tile.dart';

/// Summary stats row — 2×2 grid when 4 cards (web Entries / Days / Missing / Flags).
class StaffDailyLogStatsRow extends StatelessWidget {
  final List<StaffDailyLogSummaryStat> stats;

  const StaffDailyLogStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    if (stats.length <= 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(child: StaffDailyLogStatTile(stat: stats[i])),
          ],
        ],
      );
    }

    final gap = ResponsiveHelper.getResponsiveWidth(context, 10);
    final vGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: StaffDailyLogStatTile(stat: stats[0])),
            SizedBox(width: gap),
            Expanded(child: StaffDailyLogStatTile(stat: stats[1])),
          ],
        ),
        SizedBox(height: vGap),
        Row(
          children: [
            Expanded(child: StaffDailyLogStatTile(stat: stats[2])),
            SizedBox(width: gap),
            Expanded(child: StaffDailyLogStatTile(stat: stats[3])),
          ],
        ),
      ],
    );
  }
}
