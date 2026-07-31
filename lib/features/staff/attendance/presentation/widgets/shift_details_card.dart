import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/surface_card.dart';

/// "Sunrise Home" card with a trailing "View Schedule" link and a
/// "7:00 AM – 3:00 PM" subtitle.
class ShiftDetailsCard extends StatelessWidget {
  final String locationName;
  final String timeRange;
  final VoidCallback? onViewScheduleTap;

  const ShiftDetailsCard({
    super.key,
    required this.locationName,
    required this.timeRange,
    this.onViewScheduleTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locationName,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: onViewScheduleTap,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'View Schedule',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            timeRange,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
