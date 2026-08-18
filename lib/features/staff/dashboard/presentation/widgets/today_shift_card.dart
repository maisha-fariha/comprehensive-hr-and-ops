import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/today_shift_summary.dart';

/// Floating white card overlapping the gradient header / body boundary.
class TodayShiftCard extends StatelessWidget {
  final TodayShiftSummary shift;

  const TodayShiftCard({super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);
    final clockBox = ResponsiveHelper.getResponsiveSize(context, 30);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.08),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Shift",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Container(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppSvgIcon(
                      AppAssets.checkCircle,
                      size: 14,
                      color: Color(0xFF2E8C58),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                    Text(
                      shift.statusLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: const Color(0xFF2E8C58),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          Row(
            children: [
              Container(
                width: clockBox,
                height: clockBox,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F0),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 9),
                  ),
                ),
                alignment: Alignment.center,
                child: const AppSvgIcon(
                  AppAssets.clock,
                  size: 15,
                  color: Color(0xFF2E8C58),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: Text(
                  shift.dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  shift.timeRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
