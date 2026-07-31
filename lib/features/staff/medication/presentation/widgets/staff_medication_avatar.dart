import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/staff_medication_enums.dart';
import '../../staff_medication_constants.dart';

/// Circular initials avatar used for residents/staff across every Staff
/// Medication tab.
class StaffMedicationAvatar extends StatelessWidget {
  final String initials;
  final AvatarPalette palette;
  final double size;

  const StaffMedicationAvatar({
    super.key,
    required this.initials,
    required this.palette,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final style = StaffMedicationConstants.avatarStyle(palette);
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);

    return Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(color: style.background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.34),
          color: style.foreground,
        ),
      ),
    );
  }
}
