import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Red-tinted alert box shown on the Incident Details screen only when the
/// incident's severity is High or Critical (see
/// `IncidentDetail.requiresUrgentReview`).
class HighSeverityAlertBanner extends StatelessWidget {
  const HighSeverityAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.criticalBackgroundSoft,
        border: Border.all(color: AppColors.criticalBackground),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 18),
            color: AppColors.criticalRed,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Text(
              'High-severity incident — supervisor review required within 24 hours.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.criticalRed,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
