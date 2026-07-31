import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/board_shift.dart';
import '../../scheduling_constants.dart';
import 'coverage_status_style.dart';
import 'staff_avatar_circle.dart';

/// A single detailed shift card in the Board tab's "Coverage Board" list:
/// period + time range, a staff ratio/status, a progress bar, the facepile
/// with role chips, and a "needed" row with a "+ Fill" quick action.
///
/// NOTE: the "+ Fill" button's icon is rendered with `Icons.add_rounded`
/// (Material Icons) as a temporary stand-in for the Figma vector icon — see
/// the feature's final report.
class BoardShiftCard extends StatelessWidget {
  final BoardShift shift;
  final VoidCallback? onFillTap;

  const BoardShiftCard({super.key, required this.shift, this.onFillTap});

  @override
  Widget build(BuildContext context) {
    final style = coverageStatusStyles[shift.status]!;

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 14)),
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shift.periodLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                      Text(
                        shift.timeRange,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${shift.filled} / ${shift.total}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                    Text(
                      shift.statusLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                        color: style.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, SchedulingDimens.progressBarHeight + 1),
                child: Stack(
                  children: [
                    Container(color: AppColors.dividerLight),
                    FractionallySizedBox(
                      widthFactor: (shift.filled / shift.total).clamp(0, 1),
                      child: Container(color: style.accent),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < shift.avatars.length; i++)
                      StaffAvatarCircle(
                        avatar: shift.avatars[i],
                        size: SchedulingDimens.boardAvatarSize,
                        isFirst: i == 0,
                      ),
                    if (shift.extraStaffCount > 0)
                      StaffAvatarOverflowCircle(
                        count: shift.extraStaffCount,
                        size: SchedulingDimens.boardAvatarSize,
                      ),
                  ],
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                Expanded(
                  child: Wrap(
                    spacing: ResponsiveHelper.getResponsiveWidth(context, 6),
                    runSpacing: ResponsiveHelper.getResponsiveHeight(context, 6),
                    children: [
                      for (final role in shift.roleChips)
                        StatusBadge.chip(
                          label: role,
                          background: AppColors.dividerLight,
                          foreground: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            Container(height: 1, color: AppColors.dividerLight),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Row(
              children: [
                Container(
                  width: ResponsiveHelper.getResponsiveSize(context, 7),
                  height: ResponsiveHelper.getResponsiveSize(context, 7),
                  decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                Expanded(
                  child: Text(
                    shift.neededLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textBody,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onFillTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTeal,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusChip),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: ResponsiveHelper.getResponsiveSize(context, 14),
                          color: Colors.white,
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 3)),
                        Text(
                          'Fill',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
