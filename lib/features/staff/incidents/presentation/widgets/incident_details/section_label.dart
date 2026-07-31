import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Small all-caps, letter-spaced section label, e.g. "INCIDENT INFORMATION"
/// / "PEOPLE", shown above each section of the Incident Details screen.
class IncidentDetailsSectionLabel extends StatelessWidget {
  final String text;

  const IncidentDetailsSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
        color: AppColors.textFaint,
        letterSpacing: 0.6,
      ),
    );
  }
}
