import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Small rounded numeric pill used everywhere a section shows a count next
/// to its title (tab bar labels, "Due Today", "Missed / Refused Alerts",
/// "Missed Medications", "Refused Medications").
class MedicationCountBadge extends StatelessWidget {
  final int count;
  final Color background;
  final Color foreground;

  const MedicationCountBadge({
    super.key,
    required this.count,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: ResponsiveHelper.getResponsiveSize(context, 19)),
      height: ResponsiveHelper.getResponsiveSize(context, 19),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6.4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: foreground,
        ),
      ),
    );
  }
}
