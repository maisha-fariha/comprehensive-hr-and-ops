import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/today_shift_summary.dart';

/// The floating white card overlapping the boundary between the gradient
/// header and the scrollable content below it — the same "floating card
/// overlaps header" pattern as the HR Manager Dashboard's search bar.
class TodayShiftCard extends StatelessWidget {
  final TodayShiftSummary shift;

  const TodayShiftCard({super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Shift",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.activeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 6),
                      height: ResponsiveHelper.getResponsiveSize(context, 6),
                      decoration: const BoxDecoration(color: AppColors.activeGreen, shape: BoxShape.circle),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                    Text(
                      shift.statusLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.activeGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AppSvgIcon(AppAssets.clock, size: 15, color: AppColors.textMuted),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                  Text(
                    shift.dateLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                shift.timeRange,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AppColors.textHeading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
