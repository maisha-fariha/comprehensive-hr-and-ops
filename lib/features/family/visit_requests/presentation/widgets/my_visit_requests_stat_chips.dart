import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/surface_card.dart';

/// Row of 3 equal-width stat chips at the top of the "My Requests" tab -
/// "N Pending" (amber), "N Approved" (green), "N Rejected" (red). This is
/// a new pattern for this codebase, modeled simply as a `Row` of flexible
/// `SurfaceCard`-based chips.
class MyVisitRequestsStatChips extends StatelessWidget {
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  const MyVisitRequestsStatChips({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: pendingCount,
            label: 'Pending',
            color: AppColors.urgentAmber,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Expanded(
          child: _StatChip(
            value: approvedCount,
            label: 'Approved',
            color: AppColors.activeGreen,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Expanded(
          child: _StatChip(
            value: rejectedCount,
            label: 'Rejected',
            color: AppColors.criticalRed,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              color: color,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
