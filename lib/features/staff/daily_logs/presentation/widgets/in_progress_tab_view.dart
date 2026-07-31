import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import 'client_log_card.dart';
import 'staff_daily_log_stats_row.dart';

/// Content of the "In Progress" segmented tab: 3 summary stat tiles and a
/// list of individually-bordered "In Progress" client cards.
class InProgressTabView extends StatelessWidget {
  final List<StaffDailyLogSummaryStat> stats;
  final List<StaffClientLogEntry> inProgressClients;
  final ValueChanged<StaffClientLogEntry> onClientTap;

  const InProgressTabView({
    super.key,
    required this.stats,
    required this.inProgressClients,
    required this.onClientTap,
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
        StaffDailyLogStatsRow(stats: stats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        SectionHeaderRow(
          title: 'In Progress',
          trailing: Text(
            '${inProgressClients.length} active',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textFaint,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < inProgressClients.length; i++)
          ClientLogCard(
            entry: inProgressClients[i],
            avatarPaletteIndex: i,
            onTap: () => onClientTap(inProgressClients[i]),
          ),
      ],
    );
  }
}
