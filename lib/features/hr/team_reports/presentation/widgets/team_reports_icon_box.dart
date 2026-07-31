import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';

/// A colored, rounded icon container used across every stat tile, list row
/// and card on the Team/Reports/Messages tabs.
///
/// Renders [asset] through the shared [AppSvgIcon] when available; falls
/// back to [materialIcon] for the handful of glyphs that have no matching
/// exported SVG (no new icons could be downloaded from Figma this round -
/// see the feature's final report for the full list of placeholders).
class TeamReportsIconBox extends StatelessWidget {
  final String? asset;
  final IconData? materialIcon;
  final Color color;
  final Color background;
  final double boxSize;
  final double iconSize;
  final double radius;

  const TeamReportsIconBox({
    super.key,
    this.asset,
    this.materialIcon,
    required this.color,
    required this.background,
    this.boxSize = 42,
    this.iconSize = 21,
    this.radius = 12,
  }) : assert(asset != null || materialIcon != null, 'Provide an asset or a materialIcon');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ResponsiveHelper.getResponsiveSize(context, boxSize),
      height: ResponsiveHelper.getResponsiveSize(context, boxSize),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, radius),
        ),
      ),
      alignment: Alignment.center,
      child: asset != null
          ? AppSvgIcon(asset!, size: iconSize, color: color)
          : Icon(materialIcon, size: ResponsiveHelper.getResponsiveSize(context, iconSize), color: color),
    );
  }
}
