import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/surface_card.dart';
import 'team_reports_icon_box.dart';

/// Compact "icon + value + label" tile used in the stat rows at the top of
/// the Team, Reports and Messages tabs.
class StatTileCard extends StatelessWidget {
  final String? asset;
  final IconData? materialIcon;
  final Color color;
  final Color background;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const StatTileCard({
    super.key,
    this.asset,
    this.materialIcon,
    required this.color,
    required this.background,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TeamReportsIconBox(
              asset: asset,
              materialIcon: materialIcon,
              color: color,
              background: background,
              boxSize: 40,
              iconSize: 19,
              radius: 11,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 19),
                      color: AppColors.textHeading,
                      letterSpacing: -0.3,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: AppColors.textMuted,
                      height: 14 / 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
