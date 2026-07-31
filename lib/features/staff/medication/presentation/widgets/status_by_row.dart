import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';

/// The colored "🟢 Administered by Dana L." / "🔴 Missed by Dana L." / "🟠
/// Refused by Priya K." row shown at the bottom of a dose card, backed by a
/// tinted pill so the status reads clearly against the white card.
class StatusByRow extends StatelessWidget {
  final String label;
  final String byName;
  final Color background;
  final Color foreground;
  final String? svgAsset;
  final IconData? materialIcon;

  const StatusByRow({
    super.key,
    required this.label,
    required this.byName,
    required this.background,
    required this.foreground,
    this.svgAsset,
    this.materialIcon,
  }) : assert(svgAsset != null || materialIcon != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
      ),
      child: Row(
        children: [
          svgAsset != null
              ? AppSvgIcon(svgAsset!, size: 14, color: foreground)
              : Icon(materialIcon, size: ResponsiveHelper.getResponsiveSize(context, 14), color: foreground),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: foreground,
                    ),
                  ),
                  TextSpan(
                    text: '  by $byName',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
