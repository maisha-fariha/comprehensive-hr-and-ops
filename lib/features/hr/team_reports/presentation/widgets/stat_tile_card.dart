import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import 'team_reports_icon_box.dart';

/// Compact "icon + value + label" stat tile for Team / Reports / Messages.
class StatTileCard extends StatelessWidget {
  final String? asset;
  final IconData? materialIcon;
  final Color color;
  final Color background;
  final String value;
  final String label;
  final Color? valueColor;
  final VoidCallback? onTap;

  const StatTileCard({
    super.key,
    this.asset,
    this.materialIcon,
    required this.color,
    required this.background,
    required this.value,
    required this.label,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 12,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            TeamReportsIconBox(
              asset: asset,
              materialIcon: materialIcon,
              color: color,
              background: background,
              boxSize: 40,
              iconSize: 19,
              radius: 12,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                      color: valueColor ?? AppColors.textHeading,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: AppColors.textSecondary,
                      height: 1.2,
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
