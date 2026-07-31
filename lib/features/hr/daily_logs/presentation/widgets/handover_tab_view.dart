import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/handover_entry.dart';
import 'daily_log_stats_row.dart';
import 'handover_entry_card.dart';

/// Content of the "Handover" segmented tab: 3 summary stat tiles and the
/// "Handover Timeline" list.
class HandoverTabView extends StatelessWidget {
  final List<DailyLogSummaryStat> stats;
  final List<HandoverEntry> handoverEntries;

  const HandoverTabView({super.key, required this.stats, required this.handoverEntries});

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
          title: 'Handover Timeline',
          trailing: Text(
            'Today',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textFaint,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (final entry in handoverEntries) HandoverEntryCard(entry: entry),
      ],
    );
  }
}
