import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/missing_log_entry.dart';
import 'missing_log_card.dart';

/// Content of the "Missing" segmented tab — matched to the
/// "Missing - Daily-logs" Figma reference: 3 circular-icon stat cards
/// and the Missing Logs list.
class MissingTabView extends StatelessWidget {
  final List<DailyLogSummaryStat> stats;
  final List<MissingLogEntry> missingLogs;

  const MissingTabView({
    super.key,
    required this.stats,
    required this.missingLogs,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPad = ResponsiveHelper.getResponsiveWidth(
      context,
      AppDimens.screenPaddingHorizontal,
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        ResponsiveHelper.getResponsiveHeight(context, 16),
        horizontalPad,
        ResponsiveHelper.getResponsiveHeight(context, 32),
      ),
      children: [
        _MissingStatsRow(stats: stats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        _MissingLogsSection(logs: missingLogs),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary stats
// ─────────────────────────────────────────────────────────────────────────────

class _MissingStatsRow extends StatelessWidget {
  final List<DailyLogSummaryStat> stats;

  const _MissingStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(child: _MissingStatCard(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _MissingStatCard extends StatelessWidget {
  final DailyLogSummaryStat stat;

  const _MissingStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final (iconAsset, iconColor, iconBg) = _styleFor(stat.tag);
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 36);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        vertical: 14,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.03),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,

            height: iconSize,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(iconAsset, size: 17, color: iconColor),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
              color: iconColor,
              letterSpacing: -0.4,
              height: 1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _styleFor(DailyLogStatTag tag) {
    switch (tag) {
      case DailyLogStatTag.missingLogs:
        return (
          'assets/icons/daily_logs/logs.svg',
          AppColors.criticalRed,
          AppColors.criticalIconBackground,
        );
      case DailyLogStatTag.overdue:
        return (
          AppAssets.clock,
          AppColors.urgentAmber,
          AppColors.urgentIconBackground,
        );
      case DailyLogStatTag.followUpRequired:
        return (
          AppAssets.alertTriangle,
          const Color(0xFFC7761B),
          const Color(0xFFFBF3E9),
        );
      default:
        return (
          AppAssets.alertCircle,
          AppColors.criticalRed,
          AppColors.criticalIconBackground,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Missing Logs list
// ─────────────────────────────────────────────────────────────────────────────

class _MissingLogsSection extends StatelessWidget {
  final List<MissingLogEntry> logs;

  const _MissingLogsSection({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Missing Logs',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: AppColors.textHeading,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < logs.length; i++) ...[
          if (i != 0)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          MissingLogCard(entry: logs[i]),
        ],
      ],
    );
  }
}
