import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Small circular/pill count badge used next to Medication MAR tab labels.
class StaffMedicationCountBadge extends StatelessWidget {
  final int count;
  final Color background;
  final Color foreground;

  const StaffMedicationCountBadge({
    super.key,
    required this.count,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 20);

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      height: size,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}
