import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import 'my_client_row.dart';
import 'staff_daily_log_stats_row.dart';

/// Content of the "My Clients" segmented tab: 3 summary stat tiles and the
/// "My Clients" list (a single bordered card containing every client row,
/// separated by hairline dividers).
class MyClientsTabView extends StatelessWidget {
  final List<StaffDailyLogSummaryStat> stats;
  final List<StaffClientLogEntry> myClients;
  final int myClientsTotalCount;
  final ValueChanged<StaffClientLogEntry> onClientTap;

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
        0,
        ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
        ResponsiveHelper.getResponsiveHeight(context, 32),
      ),
      children: [
        StaffDailyLogStatsRow(stats: stats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        SurfaceCard.card(
          padding: ResponsiveHelper.getResponsivePadding(context, left: 17, right: 17, top: 16, bottom: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeaderRow(
                title: 'My Clients',
                trailing: Text(
                  '$myClientsTotalCount total',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textFaint,
                  ),
                ),
              ),
              for (var i = 0; i < myClients.length; i++)
                MyClientRow(
                  entry: myClients[i],
                  avatarPaletteIndex: i,
                  showDivider: i != myClients.length - 1,
                  onTap: () => onClientTap(myClients[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
