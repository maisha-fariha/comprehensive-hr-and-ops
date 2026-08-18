import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Status footer row: colored dot + label on the left, "by {name}" on the right.
///
/// Matches the Administered / Missed / Refused card footers in the MAR
/// references. [background] is retained for call-site compatibility but is
/// unused in this layout.
class StatusByRow extends StatelessWidget {
  final String label;
  final String byName;
  final Color background;
  final Color foreground;
  final String? svgAsset;
  final IconData? materialIcon;

  static const Color _byColor = Color(0xFF94A3B8);
  static const Color _nameColor = Color(0xFF1A2B48);

  const StatusByRow({
    super.key,
    required this.label,
    required this.byName,
    required this.background,
    required this.foreground,
    this.svgAsset,
    this.materialIcon,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 8);

    return Row(
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: foreground,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: foreground,
            height: 1.2,
          ),
        ),
        Spacer(),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'by ',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: _byColor,
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: byName,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: _nameColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
