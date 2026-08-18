import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../daily_logs_constants.dart';
import '../../domain/entities/client_status_summary.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/submitted_log_entry.dart';
import 'client_status_overview_section.dart';

/// Content of the "Review" segmented tab — matched to the
/// "Review - Daily-logs" Figma reference: 3 circular-icon stat cards,
/// individual Submitted Log cards, and Client Status Overview.
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
        _ReviewStatsRow(stats: stats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        _SubmittedLogsSection(
          logs: submittedLogs,
          totalCount: submittedLogsTotalCount,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        ClientStatusOverviewSection(summaries: clientStatusSummaries),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary stats
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewStatsRow extends StatelessWidget {
  final List<DailyLogSummaryStat> stats;

  const _ReviewStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(child: _ReviewStatCard(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _ReviewStatCard extends StatelessWidget {
  final DailyLogSummaryStat stat;

  const _ReviewStatCard({required this.stat});

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
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 11)),
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
      case DailyLogStatTag.submittedToday:
        return (
          'assets/icons/daily_logs/submitted.svg',
          AppColors.activeGreen,
          AppColors.activeIconBackground,
        );
      case DailyLogStatTag.pendingReview:
        return (
          AppAssets.clock,
          AppColors.urgentAmber,
          AppColors.urgentIconBackground,
        );
      case DailyLogStatTag.flaggedNotes:
        return (
          'assets/icons/daily_logs/flag.svg',
          AppColors.criticalRed,
          AppColors.criticalIconBackground,
        );
      default:
        return (
          AppAssets.checkCircle,
          AppColors.activeGreen,
          AppColors.activeIconBackground,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submitted Logs
// ─────────────────────────────────────────────────────────────────────────────

class _SubmittedLogsSection extends StatelessWidget {
  final List<SubmittedLogEntry> logs;
  final int totalCount;

  const _SubmittedLogsSection({
    required this.logs,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Submitted Logs',
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
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: ResponsiveHelper.getResponsiveSize(context, 22),
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 7,
              ),
              decoration: BoxDecoration(
                color: AppColors.activeBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '$totalCount',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                  color: AppColors.activeGreen,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < logs.length; i++) ...[
          if (i != 0)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _SubmittedLogCard(entry: logs[i], avatarPaletteIndex: i),
        ],
      ],
    );
  }
}

class _SubmittedLogCard extends StatelessWidget {
  final SubmittedLogEntry entry;
  final int avatarPaletteIndex;

  const _SubmittedLogCard({
    required this.entry,
    required this.avatarPaletteIndex,
  });

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusBg, statusFg, statusDot) = _statusStyle(entry.status);
    final palette = DailyLogsConstants.avatarPalette[
        avatarPaletteIndex % DailyLogsConstants.avatarPalette.length];
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 11);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.initials,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        14,
                      ),
                      color: palette.foreground,
                      height: 1,
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: statusDot,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceWhite,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.shiftLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  entry.staffName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                Row(
                  children: [
                    AppSvgIcon(
                      AppAssets.clock,
                      size: 12,
                      color: AppColors.textFaint,
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                    Flexible(
                      child: Text(
                        entry.submittedTimeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12,
                          ),
                          color: AppColors.textMuted,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 8),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: statusFg,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
              const AppSvgIcon(
                AppAssets.chevronRight,
                size: 16,
                color: AppColors.iconChevron,
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color, Color, Color) _statusStyle(LogReviewStatus status) {
    switch (status) {
      case LogReviewStatus.complete:
        return (
          'Complete',
          AppColors.activeBackground,
          AppColors.activeGreen,
          AppColors.activeGreen,
        );
      case LogReviewStatus.inReview:
        return (
          'In Review',
          AppColors.urgentBackground,
          AppColors.urgentAmber,
          AppColors.urgentAmber,
        );
      case LogReviewStatus.flagged:
        return (
          'Flagged',
          AppColors.criticalIconBackground,
          AppColors.criticalRed,
          AppColors.criticalRed,
        );
    }
  }
}
