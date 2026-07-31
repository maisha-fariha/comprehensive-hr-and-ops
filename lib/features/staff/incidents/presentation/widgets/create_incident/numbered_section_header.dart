import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../staff_incidents_constants.dart';

/// "1  INCIDENT DETAILS" style numbered, all-caps section header shown
/// above each section of the Create Incident form.
class NumberedSectionHeader extends StatelessWidget {
  final int number;
  final String title;

  const NumberedSectionHeader({super.key, required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    final badgeSize = ResponsiveHelper.getResponsiveSize(context, 26);

    return Row(
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            color: StaffIncidentsColors.sectionBadgeBackground,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 8),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.secondaryTeal,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textHeading,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
