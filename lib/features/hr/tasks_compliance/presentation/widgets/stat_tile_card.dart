import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Whether a [StatTileCard] lays its icon to the left of the value/label
/// (Tasks/Corrective 2x2 grids) or above a centered value/label
/// (legacy vertical callers).
enum StatTileLayout { horizontal, vertical }

/// Shared summary tile for Tasks & Compliance stats grids.
class StatTileCard extends StatelessWidget {
  final String? svgAsset;
  final IconData? materialIcon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final Color valueColor;
  final String label;
  final StatTileLayout layout;

  const StatTileCard({
    super.key,
    this.svgAsset,
    this.materialIcon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.valueColor,
    required this.label,
    this.layout = StatTileLayout.horizontal,
  }) : assert(svgAsset != null || materialIcon != null);

  @override
  Widget build(BuildContext context) {
    final isHorizontal = layout == StatTileLayout.horizontal;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    final iconBox = Container(
      width: iconBoxSize,
      height: iconBoxSize,
      decoration: BoxDecoration(
        color: iconBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      alignment: Alignment.center,
      child: svgAsset != null
          ? AppSvgIcon(svgAsset!, size: 19, color: iconColor)
          : Icon(
              materialIcon,
              size: ResponsiveHelper.getResponsiveSize(context, 19),
              color: iconColor,
            ),
    );

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: isHorizontal ? 12 : 8,
        vertical: isHorizontal ? 14 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: isHorizontal
          ? Row(
              children: [
                iconBox,
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
                          color: valueColor,
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
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconBox,
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    color: valueColor,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
    );
  }
}
