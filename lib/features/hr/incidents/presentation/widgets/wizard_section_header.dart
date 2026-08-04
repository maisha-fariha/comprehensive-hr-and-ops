import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Step section header shown at the top of every wizard step:
/// colored number badge + title + subtitle.
///
/// Matched to the "Incident Details" reference: soft rounded badge,
/// bold navy title, muted subtitle — wrapped for small screens.
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
    final badgeSize = ResponsiveHelper.getResponsiveSize(context, 38);
    final badgeRadius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badgeBackground,
            borderRadius: BorderRadius.circular(badgeRadius),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: badgeForeground,
              height: 1,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                  color: AppColors.textHeading,
                  height: 1.2,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
