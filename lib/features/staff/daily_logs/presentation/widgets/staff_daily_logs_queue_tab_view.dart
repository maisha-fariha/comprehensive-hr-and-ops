import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import 'my_client_row.dart';
import 'staff_daily_log_stats_row.dart';

/// Shared list for To review / Missing queues.
class StaffDailyLogsQueueTabView extends StatelessWidget {
  final List<StaffDailyLogSummaryStat> stats;
  final List<StaffClientLogEntry> items;
  final int totalCount;
  final String sectionTitle;
  final String emptyMessage;
  final ValueChanged<StaffClientLogEntry> onItemTap;

  const StaffDailyLogsQueueTabView({
    super.key,
    required this.stats,
    required this.items,
    required this.totalCount,
    required this.sectionTitle,
    required this.emptyMessage,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        ),
        ResponsiveHelper.getResponsiveHeight(context, 8),
        ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        ),
        ResponsiveHelper.getResponsiveHeight(context, 32),
      ),
      children: [
        if (stats.isNotEmpty) ...[
          StaffDailyLogStatsRow(stats: stats),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                sectionTitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Text(
              '${items.length} shown · $totalCount total',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.secondaryTeal,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          for (var i = 0; i < items.length; i++)
            MyClientRow(
              entry: items[i],
              avatarPaletteIndex: i,
              showDivider: false,
              onTap: () => onItemTap(items[i]),
            ),
      ],
    );
  }
}
