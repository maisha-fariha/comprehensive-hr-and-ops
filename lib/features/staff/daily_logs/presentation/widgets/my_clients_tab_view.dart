import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import 'my_client_row.dart';
import 'staff_daily_log_stats_row.dart';

/// Content of the "My Clients" tab: summary stats, section header with
/// teal total pill, and individual elevated client cards.
class MyClientsTabView extends StatelessWidget {
  final List<StaffDailyLogSummaryStat> stats;
  final List<StaffClientLogEntry> myClients;
  final int myClientsTotalCount;
  final ValueChanged<StaffClientLogEntry> onClientTap;

  static const Color _totalPillBg = Color(0xFFE6F4F3);
  static const Color _totalPillFg = Color(0xFF0E7C7B);

  const MyClientsTabView({
    super.key,
    required this.stats,
    required this.myClients,
    required this.myClientsTotalCount,
    required this.onClientTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
        ResponsiveHelper.getResponsiveHeight(context, 4),
        ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
        ResponsiveHelper.getResponsiveHeight(context, 32),
      ),
      children: [
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        StaffDailyLogStatsRow(stats: stats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        Row(
          children: [
            Expanded(
              child: Text(
                'My Clients',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: AppColors.textHeading,
                  height: 1.2,
                ),
              ),
            ),
            Container(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _totalPillBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$myClientsTotalCount total',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: _totalPillFg,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < myClients.length; i++)
          MyClientRow(
            entry: myClients[i],
            avatarPaletteIndex: i,
            showDivider: false,
            onTap: () => onClientTap(myClients[i]),
          ),
      ],
    );
  }
}
