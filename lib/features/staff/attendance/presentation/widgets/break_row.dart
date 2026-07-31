import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../staff_core_constants.dart';

/// "Break" row: bold title + a muted status subtitle, with a trailing
/// outlined pill button ("☕ Start Break" / "☕ End Break").
///
/// NOTE: the coffee-cup glyph has no matching exported SVG yet, so
/// `StaffMaterialIconFallback.coffeeBreak` stands in for it — see the
/// feature's final report.
class BreakRow extends StatelessWidget {
  final bool isOnBreak;
  final String statusLabel;
  final VoidCallback? onToggleBreak;

  const BreakRow({super.key, required this.isOnBreak, required this.statusLabel, this.onToggleBreak});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Break',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggleBreak,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 15, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusChip),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    StaffMaterialIconFallback.coffeeBreak,
                    size: ResponsiveHelper.getResponsiveSize(context, 15),
                    color: AppColors.textBody,
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                  Text(
                    isOnBreak ? 'End Break' : 'Start Break',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
