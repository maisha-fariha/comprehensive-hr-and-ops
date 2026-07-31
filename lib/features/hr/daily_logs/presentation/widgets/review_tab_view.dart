import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/client_status_summary.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/submitted_log_entry.dart';
import 'client_status_overview_section.dart';
import 'count_badge.dart';
import 'daily_log_stats_row.dart';
import 'submitted_log_tile.dart';

/// Content of the "Review" segmented tab: 3 summary stat tiles, the
/// "Submitted Logs" list and the "Client Status Overview" card.
class ReviewTabView extends StatelessWidget {
  final List<DailyLogSummaryStat> stats;
  final List<SubmittedLogEntry> submittedLogs;
  final int submittedLogsTotalCount;
  final List<ClientStatusSummary> clientStatusSummaries;

  const ReviewTabView({
    super.key,
    required this.stats,
    required this.submittedLogs,
    required this.submittedLogsTotalCount,
    required this.clientStatusSummaries,
  });

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
        SurfaceCard.card(
          padding: ResponsiveHelper.getResponsivePadding(context, left: 17, right: 17, top: 16, bottom: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeaderRow(
                title: 'Submitted Logs',
                trailing: DailyLogCountBadge(count: submittedLogsTotalCount),
              ),
              for (var i = 0; i < submittedLogs.length; i++)
                SubmittedLogTile(
                  entry: submittedLogs[i],
                  avatarPaletteIndex: i,
                  showDivider: i != submittedLogs.length - 1,
                ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        ClientStatusOverviewSection(summaries: clientStatusSummaries),
      ],
    );
  }
}
