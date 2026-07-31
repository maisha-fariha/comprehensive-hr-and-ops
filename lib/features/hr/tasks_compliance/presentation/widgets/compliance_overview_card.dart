import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/compliance_summary.dart';

/// The dark "Overall Compliance" hero card at the top of the "Compliance"
/// tab: a circular progress ring + headline stat, description and a small
/// "vs last month" trend pill.
///
/// The ring has no exported Figma asset, so it is built with Flutter's own
/// [CircularProgressIndicator] (styled with the design's green/track
/// colors) rather than an SVG.
class ComplianceOverviewCard extends StatelessWidget {
  final ComplianceSummary summary;

  const ComplianceOverviewCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final ringSize = ResponsiveHelper.getResponsiveSize(context, 92);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: CircularProgressIndicator(
                    value: summary.percent / 100,
                    strokeWidth: ResponsiveHelper.getResponsiveSize(context, 9),
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.whiteOpacity16,
                    valueColor: const AlwaysStoppedAnimation(AppColors.successGreen),
                  ),
                ),
                Text(
                  '${summary.percent}%',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 19),
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Overall Compliance',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Text(
                  summary.description,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.whiteOpacity70,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.activeGreen.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: ResponsiveHelper.getResponsiveSize(context, 11),
                        color: AppColors.successGreen,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                      Text(
                        summary.trendLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                          color: AppColors.successGreen,
                        ),
                      ),
                      Text(
                        ' vs last month',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                          color: AppColors.successGreen.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
