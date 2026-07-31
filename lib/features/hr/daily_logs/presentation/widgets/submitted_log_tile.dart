import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../daily_logs_constants.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/submitted_log_entry.dart';
import 'initials_avatar.dart';

class _StatusStyle {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusStyle({required this.label, required this.background, required this.foreground});
}

const Map<LogReviewStatus, _StatusStyle> _statusStyles = {
  LogReviewStatus.complete: _StatusStyle(
    label: 'Complete',
    background: AppColors.activeBackground,
    foreground: AppColors.activeGreen,
  ),
  LogReviewStatus.inReview: _StatusStyle(
    label: 'In Review',
    background: AppColors.urgentBackground,
    foreground: AppColors.urgentAmber,
  ),
  LogReviewStatus.flagged: _StatusStyle(
    label: 'Flagged',
    background: AppColors.criticalBackground,
    foreground: AppColors.criticalRed,
  ),
};

/// A single row in the Review tab's "Submitted Logs" list: an initials
/// avatar, a shift-name eyebrow above the staff name, a submitted-time
/// caption, and a trailing status pill + chevron.
class SubmittedLogTile extends StatelessWidget {
  final SubmittedLogEntry entry;
  final int avatarPaletteIndex;
  final bool showDivider;
  final VoidCallback? onTap;

  const SubmittedLogTile({
    super.key,
    required this.entry,
    required this.avatarPaletteIndex,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyles[entry.status]!;
    final avatarColors = DailyLogsConstants.avatarPalette[
        avatarPaletteIndex % DailyLogsConstants.avatarPalette.length];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
              )
            : null,
        padding: ResponsiveHelper.getResponsivePadding(context, top: 13, bottom: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InitialsAvatar(
              initials: entry.initials,
              background: avatarColors.background,
              foreground: avatarColors.foreground,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.shiftLabel.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                      color: AppColors.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    entry.staffName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSvgIcon(AppAssets.clock, size: 11, color: AppColors.textFaint),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                      Text(
                        entry.submittedTimeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
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
              label: statusStyle.label,
              background: statusStyle.background,
              foreground: statusStyle.foreground,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            const AppSvgIcon(AppAssets.chevronRight, size: 16, color: AppColors.iconChevron),
          ],
        ),
      ),
    );
  }
}
