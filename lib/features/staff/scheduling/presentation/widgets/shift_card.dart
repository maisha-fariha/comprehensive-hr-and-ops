import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../staff_core_constants.dart';
import '../../domain/entities/staff_shift.dart';
import 'shift_avatar_circle.dart';

/// A single shift card in "My Schedule"'s "My Shifts" list: title (+ an
/// optional "TODAY" tag), a date/time subtitle, a location row, an
/// avatar-stack + staffing ratio + role tag row, a trailing "Confirmed"
/// pill, and a colored staffing-level progress bar underneath.
///
/// NOTE: the location-pin glyph has no matching exported SVG yet, so
/// `StaffMaterialIconFallback.locationPin` stands in for it — see the
/// feature's final report.
class ShiftCard extends StatelessWidget {
  final StaffShift shift;
  final VoidCallback? onTap;

  const ShiftCard({super.key, required this.shift, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = staffingLevelStyles[shift.staffingLevel]!;

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 14)),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SurfaceCard.card(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            shift.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (shift.isToday) ...[
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                          StatusBadge.chip(
                            label: 'TODAY',
                            background: AppColors.quickActionCreateShiftBg,
                            foreground: AppColors.secondaryTeal,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                  StatusBadge.pill(
                    label: shift.statusLabel,
                    background: AppColors.activeBackground,
                    foreground: AppColors.activeGreen,
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
              Text(
                shift.dateTimeLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
              Row(
                children: [
                  Icon(
                    StaffMaterialIconFallback.locationPin,
                    size: ResponsiveHelper.getResponsiveSize(context, 13),
                    color: AppColors.textFaint,
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                  Text(
                    shift.location,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < shift.avatars.length; i++)
                        ShiftAvatarCircle(avatar: shift.avatars[i], paletteIndex: i, isFirst: i == 0),
                    ],
                  ),
                  if (shift.extraStaffCount > 0) ...[
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                    Text(
                      '+${shift.extraStaffCount} staff',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${shift.filled}/${shift.total}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                  StatusBadge.chip(
                    label: shift.roleTag,
                    background: AppColors.dividerLight,
                    foreground: AppColors.textSecondary,
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, StaffDimens.progressBarHeight),
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
            ],
          ),
        ),
      ),
    );
  }
}
