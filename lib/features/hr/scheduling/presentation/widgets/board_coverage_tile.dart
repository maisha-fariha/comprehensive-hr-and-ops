import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/coverage_summary.dart';
import 'coverage_status_style.dart';

/// A single tile in the Board tab's "Today's Coverage" row, e.g.
/// "Morning · 8/10 · Almost Full".
class BoardCoverageTile extends StatelessWidget {
  final CoverageSummary summary;

  const BoardCoverageTile({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final style = coverageStatusStyles[summary.status]!;

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 8),
                height: ResponsiveHelper.getResponsiveSize(context, 8),
                decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Expanded(
                child: Text(
                  summary.periodLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(
            summary.ratioLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 19),
              color: AppColors.textHeading,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            summary.statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
              color: style.accent,
            ),
          ),
        ],
      ),
    );
  }
}
