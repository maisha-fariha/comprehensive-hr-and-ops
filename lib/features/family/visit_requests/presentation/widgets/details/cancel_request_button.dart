import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Outlined, secondary "Cancel Request" button fixed at the bottom of the
/// Request Details screen.
///
/// Not directly visible in the source screenshot (which is cropped right
/// after the "Purpose & Notes" card) - added as the one reasonable
/// inference the task allows, consistent with how detail/review pages
/// elsewhere in this app (e.g. `IncidentDetailsPage`'s sibling
/// `CreateIncidentPage`) end with an action button pinned above the safe
/// area.
class CancelRequestButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CancelRequestButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 16),
          ),
          child: Container(
            padding: ResponsiveHelper.getResponsivePadding(context, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.criticalRed.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 16),
              ),
            ),
            child: Text(
              'Cancel Request',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: AppColors.criticalRed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
