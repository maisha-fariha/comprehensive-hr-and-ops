import 'package:comprehensive_hr_and_ops/features/staff/daily_logs/presentation/widgets/staff_daily_log_stats_row.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import 'client_log_card.dart';

/// Content of the "In Progress" tab: section header with active count pill
/// and individually elevated client cards (matches the In Progress reference).
class InProgressTabView extends StatelessWidget {
  /// Kept for call-site compatibility; the In Progress reference crop does
  /// not include the top summary stats row.
  final List<StaffDailyLogSummaryStat> stats;
  final List<StaffClientLogEntry> inProgressClients;
  final ValueChanged<StaffClientLogEntry> onClientTap;

  static const Color _activePillBg = Color(0xFFE6F4F1);
  static const Color _activePillFg = Color(0xFF0E7C7B);

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
                'In Progress',
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
                color: _activePillBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${inProgressClients.length} active',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: _activePillFg,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < inProgressClients.length; i++)
          ClientLogCard(
            entry: inProgressClients[i],
            avatarPaletteIndex: i + 1,
            onTap: () => onClientTap(inProgressClients[i]),
          ),
      ],
    );
  }
}
