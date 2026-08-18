import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';

/// Colored rounded icon container used across Team & Reports tiles.
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
    this.boxSize = 40,
    this.iconSize = 19,
    this.radius = 12,
  }) : assert(asset != null || materialIcon != null);

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
          : Icon(
              materialIcon,
              size: ResponsiveHelper.getResponsiveSize(context, iconSize),
              color: color,
            ),
    );
  }
}
