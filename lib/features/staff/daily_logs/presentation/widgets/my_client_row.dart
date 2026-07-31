import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../staff_daily_logs_constants.dart';
import 'client_status_style.dart';
import 'initials_avatar.dart';

/// A single row in the "My Clients" tab's client list: an initials avatar,
/// a shift-name eyebrow above the client name, a time caption next to a
/// small clock glyph, and a trailing status pill.
class MyClientRow extends StatelessWidget {
  final StaffClientLogEntry entry;
  final int avatarPaletteIndex;
  final bool showDivider;
  final VoidCallback? onTap;

  const MyClientRow({
    super.key,
    required this.entry,
    required this.avatarPaletteIndex,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = clientStatusStyles[entry.status]!;
    final avatarColors =
        StaffDailyLogsConstants.avatarPalette[avatarPaletteIndex % StaffDailyLogsConstants.avatarPalette.length];

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
                    entry.clientName,
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
                        entry.subtitleLabel,
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
          ],
        ),
      ),
    );
  }
}
