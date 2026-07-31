import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// "1  Incident Details / Capture what happened and how serious it is"
/// style section header shown at the top of every wizard step, with a
/// step-specific colored number badge.
class WizardSectionHeader extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final Color badgeBackground;
  final Color badgeForeground;

  const WizardSectionHeader({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = ResponsiveHelper.getResponsiveSize(context, 34);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            color: badgeBackground,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 10),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: badgeForeground,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: AppColors.textHeading,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
