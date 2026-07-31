import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/staff_medication_enums.dart';
import 'medication_route_row.dart';
import 'staff_medication_avatar.dart';
import 'status_by_row.dart';

/// A single dose card in the "Due" tab: avatar/name/medication header row,
/// route caption, trailing scheduled time, then either an
/// "Administer"/"Not Given" action row ([DueDoseStatus.pending]), a
/// confirmation status row (after a staff member taps a button), or a
/// muted "Upcoming" state for doses further out in the day.
class DueDoseCard extends StatelessWidget {
  final DueDose dose;
  final VoidCallback onAdminister;
  final VoidCallback onNotGiven;

  const DueDoseCard({
    super.key,
    required this.dose,
    required this.onAdminister,
    required this.onNotGiven,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = dose.status == DueDoseStatus.upcoming;

    return Opacity(
      opacity: isUpcoming ? 0.55 : 1,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaffMedicationAvatar(initials: dose.residentInitials, palette: dose.avatarColor),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dose.residentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      Text(
                        '${dose.medicationName} ${dose.dose}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: AppColors.textBody,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      MedicationRouteRow(route: dose.route),
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(AppAssets.clock, size: 12, color: AppColors.textFaint),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                    Text(
                      dose.timeLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            _buildActionArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(BuildContext context) {
    switch (dose.status) {
      case DueDoseStatus.upcoming:
        return Row(
          children: [
            Icon(Icons.schedule_rounded, size: ResponsiveHelper.getResponsiveSize(context, 14), color: AppColors.textFaint),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Text(
              'Upcoming',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.textFaint,
              ),
            ),
          ],
        );
      case DueDoseStatus.administered:
        return const StatusByRow(
          label: 'Administered',
          byName: 'you',
          background: AppColors.activeBackground,
          foreground: AppColors.activeGreen,
          svgAsset: AppAssets.checkCircle,
        );
      case DueDoseStatus.notGiven:
        return const StatusByRow(
          label: 'Not Given',
          byName: 'you',
          background: AppColors.criticalBackground,
          foreground: AppColors.criticalRed,
          materialIcon: Icons.cancel_rounded,
        );
      case DueDoseStatus.pending:
        return Row(
          children: [
            Expanded(
              child: _AdministerButton(onTap: onAdminister),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: _NotGivenButton(onTap: onNotGiven),
            ),
          ],
        );
    }
  }
}

class _AdministerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AdministerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.activeGreen,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: ResponsiveHelper.getResponsiveSize(context, 15), color: Colors.white),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
            Text(
              'Administer',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotGivenButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NotGivenButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
        ),
        alignment: Alignment.center,
        child: Text(
          'Not Given',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: AppColors.textBody,
          ),
        ),
      ),
    );
  }
}
