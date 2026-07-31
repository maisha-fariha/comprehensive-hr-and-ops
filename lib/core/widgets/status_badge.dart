import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Small rounded label used across the dashboard for severity/status tags
/// (e.g. "Critical", "Urgent", "ACTIVE", "DUE"). Two shapes are used in the
/// Figma design: a slightly-rounded "chip" for list-item severity tags and a
/// fully-rounded "pill" for stat-card status tags.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final double radius;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.radius,
    required this.fontSize,
    required this.padding,
  });

  const StatusBadge.chip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  })  : radius = 6,
        fontSize = 10,
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2);

  const StatusBadge.pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  })  : radius = 999,
        fontSize = 10.5,
        padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 3);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: padding.horizontal / 2,
        vertical: padding.vertical / 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, radius),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, fontSize),
          color: foreground,
          letterSpacing: 0.2,
          height: 1,
        ),
      ),
    );
  }
}
