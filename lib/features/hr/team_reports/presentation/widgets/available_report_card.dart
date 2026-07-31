import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/available_report_item.dart';
import '../../team_reports_assets.dart';
import 'report_type_style.dart';
import 'team_reports_icon_box.dart';

/// A single card in the Reports tab's "Available Reports" list.
class AvailableReportCard extends StatelessWidget {
  final AvailableReportItem item;
  final VoidCallback? onTap;

  const AvailableReportCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = reportTypeStyles[item.tag]!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TeamReportsIconBox(
              asset: style.asset,
              materialIcon: style.materialIcon,
              color: style.color,
              background: style.background,
              boxSize: 42,
              iconSize: 20,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    item.categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: style.color,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Row(
                    children: [
                      const AppSvgIcon(TeamReportsAssets.updatedCaptionClock, size: 11, color: AppColors.textFaint),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                      Flexible(
                        child: Text(
                          item.updatedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            const AppSvgIcon(TeamReportsAssets.chevronRight, size: 16, color: AppColors.iconChevron),
          ],
        ),
      ),
    );
  }
}
