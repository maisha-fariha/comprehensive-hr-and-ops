import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/missing_log_entry.dart';
import 'initials_avatar.dart';

/// A single card in the Missing tab's "Missing Logs" list: staff header row
/// (avatar, name, location, overdue pill), an expected-shift/assigned-staff
/// meta row, and a "Send Reminder" / "Contact Staff" action row.
///
/// NOTE: no matching pin/phone SVGs exist in `assets/icons/*`, so
/// `Icons.location_on_rounded`, `Icons.person_rounded` and
/// `Icons.call_rounded` are used as temporary stand-ins (flagged in the
/// final report).
class MissingLogCard extends StatelessWidget {
  final MissingLogEntry entry;
  final VoidCallback? onSendReminder;
  final VoidCallback? onContactStaff;

  const MissingLogCard({
    super.key,
    required this.entry,
    this.onSendReminder,
    this.onContactStaff,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 12)),
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: const BoxDecoration(
                    color: AppColors.urgentIconBackground,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 20),
                    color: AppColors.urgentAmber,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.staffName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: ResponsiveHelper.getResponsiveSize(context, 12.5),
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 3)),
                          Text(
                            entry.locationLabel,
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
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                StatusBadge.chip(
                  label: entry.overdueLabel,
                  background: AppColors.criticalBackground,
                  foreground: AppColors.criticalRed,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MetaColumn(
                    label: 'EXPECTED SHIFT',
                    child: Text(
                      entry.expectedShiftLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _MetaColumn(
                    label: 'ASSIGNED STAFF',
                    child: Row(
                      children: [
                        InitialsAvatar(
                          initials: entry.assignedStaffInitials,
                          background: AppColors.infoBackground,
                          foreground: AppColors.infoBlue,
                          size: 20,
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                        Expanded(
                          child: Text(
                            entry.assignedStaffName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            Row(
              children: [
                Expanded(
                  child: _OutlinedActionButton(
                    svgAsset: AppAssets.bell,
                    label: 'Send Reminder',
                    onTap: onSendReminder,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                Expanded(
                  child: _OutlinedActionButton(
                    materialIcon: Icons.call_rounded,
                    label: 'Contact Staff',
                    onTap: onContactStaff,
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

class _MetaColumn extends StatelessWidget {
  final String label;
  final Widget child;

  const _MetaColumn({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9.5),
            color: AppColors.textFaint,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
        child,
      ],
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final String? svgAsset;
  final IconData? materialIcon;
  final String label;
  final VoidCallback? onTap;

  const _OutlinedActionButton({
    this.svgAsset,
    this.materialIcon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusButton)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            svgAsset != null
                ? AppSvgIcon(svgAsset!, size: 15, color: AppColors.secondaryTeal)
                : Icon(
                    materialIcon,
                    size: ResponsiveHelper.getResponsiveSize(context, 15),
                    color: AppColors.secondaryTeal,
                  ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.secondaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
