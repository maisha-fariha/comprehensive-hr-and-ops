import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/client_status_summary.dart';

/// "Client Status Overview" card at the bottom of the Review tab. The
/// reference screenshot cuts this section off right after its heading, so
/// the row content is a reasonable placeholder consistent with the rest of
/// the app.
class ClientStatusOverviewSection extends StatelessWidget {
  final List<ClientStatusSummary> summaries;

  const ClientStatusOverviewSection({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, left: 17, right: 17, top: 16, bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeaderRow(title: 'Client Status Overview'),
          for (var i = 0; i < summaries.length; i++)
            _ClientStatusRow(
              summary: summaries[i],
              showDivider: i != summaries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ClientStatusRow extends StatelessWidget {
  final ClientStatusSummary summary;
  final bool showDivider;

  const _ClientStatusRow({required this.summary, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final iconColor = summary.isOnTrack ? AppColors.activeGreen : AppColors.urgentAmber;
    final iconBackground = summary.isOnTrack ? AppColors.activeIconBackground : AppColors.urgentIconBackground;

    return Container(
      decoration: showDivider
          ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.dividerLight)))
          : null,
      padding: ResponsiveHelper.getResponsivePadding(context, top: 12, bottom: 12),
      child: Row(
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 32),
            height: ResponsiveHelper.getResponsiveSize(context, 32),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(
              summary.isOnTrack ? AppAssets.checkCircle : AppAssets.clock,
              size: 15,
              color: iconColor,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  summary.clientName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textPrimary,
                  ),
                ),
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
          const AppSvgIcon(AppAssets.chevronRight, size: 16, color: AppColors.iconChevron),
        ],
      ),
    );
  }
}
