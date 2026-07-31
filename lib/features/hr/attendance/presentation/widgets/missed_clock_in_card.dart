import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../attendance_assets.dart';
import '../../domain/entities/missed_clock_in_entry.dart';
import 'attendance_avatar.dart';

/// A single card in the "Missed" tab's "Missed Clock-Ins" list.
class MissedClockInCard extends StatelessWidget {
  final MissedClockInEntry entry;
  final VoidCallback? onReview;
  final VoidCallback? onContact;

  const MissedClockInCard({super.key, required this.entry, this.onReview, this.onContact});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AttendanceAvatar(initials: initialsFromName(entry.name), paletteIndex: entry.avatarPaletteIndex),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      entry.roleShiftLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              Container(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.criticalBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AttendanceMaterialIconFallback.noClockIn,
                      size: ResponsiveHelper.getResponsiveSize(context, 11),
                      color: AppColors.criticalRed,
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 3)),
                    Text(
                      'No Clock-In',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                        color: AppColors.criticalRed,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 11)),
          Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.criticalBackgroundSoft,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusChip),
              ),
            ),
            child: Row(
              children: [
                AppSvgIcon(AttendanceAssets.critical, size: 14, color: AppColors.criticalRed),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                Expanded(
                  child: Text(
                    'Reason: ${entry.reasonLabel}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.criticalRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 11)),
          Row(
            children: [
              Expanded(
                child: _FilledButton(label: 'Review', onTap: onReview),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: _OutlinedButton(label: 'Contact', onTap: onContact),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FilledButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: ResponsiveHelper.getResponsiveHeight(context, 38),
        decoration: BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 11),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OutlinedButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: ResponsiveHelper.getResponsiveHeight(context, 38),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 11),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
