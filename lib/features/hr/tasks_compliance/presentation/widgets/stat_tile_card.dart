import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';

/// Whether a [StatTileCard] lays its icon to the left of the value/label
/// (used by the Tasks/Corrective 2x2 grids) or above a centered value/label
/// (used by the Compliance 3-column row).
enum StatTileLayout { horizontal, vertical }

/// A single stat tile shared by all 3 "Tasks & Compliance" tabs' summary
/// rows/grids (e.g. "8 Due Today", "94% ...", "42 Completed"). Renders
/// either an existing Figma-exported SVG ([svgAsset]) or, for glyphs with no
/// exported asset available, a Material [materialIcon] fallback.
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
  }) : assert(svgAsset != null || materialIcon != null, 'Provide either svgAsset or materialIcon');

  @override
  Widget build(BuildContext context) {
    final isHorizontal = layout == StatTileLayout.horizontal;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);

    final iconBox = Container(
      width: iconBoxSize,
      height: iconBoxSize,
      decoration: BoxDecoration(
        color: iconBackground,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 12)),
      ),
      alignment: Alignment.center,
      child: svgAsset != null
          ? AppSvgIcon(svgAsset!, size: 19, color: iconColor)
          : Icon(materialIcon, size: ResponsiveHelper.getResponsiveSize(context, 19), color: iconColor),
    );

    final valueText = Text(
      value,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, isHorizontal ? 19 : 21),
        color: valueColor,
        height: 1,
      ),
    );

    final labelText = Text(
      label,
      textAlign: isHorizontal ? TextAlign.start : TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
        color: AppColors.textSecondary,
        height: 15 / 11.5,
      ),
    );

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: isHorizontal ? 12 : 10,
        vertical: isHorizontal ? 12 : 16,
      ),
      child: isHorizontal
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconBox,
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      valueText,
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      labelText,
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconBox,
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                valueText,
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                labelText,
              ],
            ),
    );
  }
}
