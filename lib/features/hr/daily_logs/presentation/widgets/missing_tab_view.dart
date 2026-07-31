import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/missing_log_entry.dart';
import 'count_badge.dart';
import 'daily_log_stats_row.dart';
import 'missing_log_card.dart';

/// Content of the "Missing" segmented tab: 3 summary stat tiles and the
/// "Missing Logs" list.
class MissingTabView extends StatelessWidget {
  final List<DailyLogSummaryStat> stats;
  final List<MissingLogEntry> missingLogs;

  const MissingTabView({super.key, required this.stats, required this.missingLogs});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
        0,
        ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
        ResponsiveHelper.getResponsiveHeight(context, 32),
      ),
      children: [
        DailyLogStatsRow(stats: stats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        SectionHeaderRow(
          title: 'Missing Logs',
          trailing: DailyLogCountBadge(count: missingLogs.length),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (final entry in missingLogs) MissingLogCard(entry: entry),
      ],
    );
  }
}
