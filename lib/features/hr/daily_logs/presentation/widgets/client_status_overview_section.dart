import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/client_status_summary.dart';

/// "Client Status Overview" section at the bottom of the Review tab.
/// Header matches the "Submitted Logs" section title style from the
/// Review reference; row content is shown below for scroll continuity
/// (the reference crop cuts off right after the heading).
class ClientStatusOverviewSection extends StatelessWidget {
  final List<ClientStatusSummary> summaries;

  const ClientStatusOverviewSection({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client Status Overview',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: AppColors.textHeading,
          ),
        ),
        if (summaries.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          for (var i = 0; i < summaries.length; i++) ...[
            if (i != 0)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            _ClientStatusCard(summary: summaries[i]),
          ],
        ],
      ],
    );
  }
}

class _ClientStatusCard extends StatelessWidget {
  final ClientStatusSummary summary;

  const _ClientStatusCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final iconColor =
        summary.isOnTrack ? AppColors.activeGreen : AppColors.urgentAmber;
    final iconBackground = summary.isOnTrack
        ? AppColors.activeIconBackground
        : AppColors.urgentIconBackground;
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 40);

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
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(
              summary.isOnTrack ? AppAssets.checkCircle : AppAssets.clock,
              size: 17,
              color: iconColor,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  summary.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  summary.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          const AppSvgIcon(
            AppAssets.chevronRight,
            size: 16,
            color: AppColors.iconChevron,
          ),
        ],
      ),
    );
  }
}
