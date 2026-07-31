import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import 'client_log_card.dart';
import 'staff_daily_log_stats_row.dart';

/// Content of the "Submitted" segmented tab: 3 summary stat tiles and a
/// list of individually-bordered "Submitted" client cards.
class SubmittedTabView extends StatelessWidget {
  final List<StaffDailyLogSummaryStat> stats;
  final List<StaffClientLogEntry> submittedClients;
  final int submittedTotalCount;
  final ValueChanged<StaffClientLogEntry> onClientTap;

  const SubmittedTabView({
    super.key,
    required this.stats,
    required this.submittedClients,
    required this.submittedTotalCount,
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
          title: 'Submitted',
          trailing: Text(
            '$submittedTotalCount complete',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textFaint,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < submittedClients.length; i++)
          ClientLogCard(
            entry: submittedClients[i],
            avatarPaletteIndex: i,
            onTap: () => onClientTap(submittedClients[i]),
          ),
      ],
    );
  }
}
