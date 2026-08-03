import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/handover_entry.dart';
import 'handover_entry_card.dart';

/// Content of the "Handover" segmented tab — matched to the
/// "Handover - Daily-logs" Figma reference: 3 circular-icon stat cards
/// and the Handover Timeline list.
class HandoverTabView extends StatelessWidget {
  final List<DailyLogSummaryStat> stats;
  final List<HandoverEntry> handoverEntries;

  const HandoverTabView({
    super.key,
    required this.stats,
    required this.handoverEntries,
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
        _HandoverStatsRow(stats: stats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        _HandoverTimelineSection(entries: handoverEntries),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary stats
// ─────────────────────────────────────────────────────────────────────────────

class _HandoverStatsRow extends StatelessWidget {
  final List<DailyLogSummaryStat> stats;

  const _HandoverStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(child: _HandoverStatCard(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _HandoverStatCard extends StatelessWidget {
  final DailyLogSummaryStat stat;

  const _HandoverStatCard({required this.stat});

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
      case DailyLogStatTag.activeHandovers:
        return (
          'assets/icons/scheduling/swap.svg',
          AppColors.secondaryTeal,
          AppColors.quickActionCreateShiftBg,
        );
      case DailyLogStatTag.pendingAcknowledgement:
        return (
          AppAssets.clock,
          AppColors.urgentAmber,
          AppColors.urgentIconBackground,
        );
      case DailyLogStatTag.urgentNotes:
        return (
          AppAssets.alertTriangle,
          AppColors.criticalRed,
          AppColors.criticalIconBackground,
        );
      default:
        return (
          AppAssets.clock,
          AppColors.secondaryTeal,
          AppColors.quickActionCreateShiftBg,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Handover Timeline
// ─────────────────────────────────────────────────────────────────────────────

class _HandoverTimelineSection extends StatelessWidget {
  final List<HandoverEntry> entries;

  const _HandoverTimelineSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Handover Timeline',
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
            Text(
              'Today',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < entries.length; i++) ...[
          if (i != 0)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          HandoverEntryCard(entry: entries[i]),
        ],
      ],
    );
  }
}
