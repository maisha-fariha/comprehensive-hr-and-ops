import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../staff_daily_logs_constants.dart';
import 'client_status_style.dart';
import 'initials_avatar.dart';

/// A single card in the "In Progress" / "Submitted" tabs' client list: an
/// initials avatar, a shift-name eyebrow above the client name, a small
/// status-colored dot next to the caption, and a trailing status pill with
/// a chevron to open the client's "Daily Note".
class ClientLogCard extends StatelessWidget {
  final StaffClientLogEntry entry;
  final int avatarPaletteIndex;
  final VoidCallback? onTap;

  const ClientLogCard({
    super.key,
    required this.entry,
    required this.avatarPaletteIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = clientStatusStyles[entry.status]!;
    final avatarColors =
        StaffDailyLogsConstants.avatarPalette[avatarPaletteIndex % StaffDailyLogsConstants.avatarPalette.length];

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 12)),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SurfaceCard.card(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
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
                        Container(
                          width: ResponsiveHelper.getResponsiveSize(context, 6),
                          height: ResponsiveHelper.getResponsiveSize(context, 6),
                          decoration: BoxDecoration(color: statusStyle.foreground, shape: BoxShape.circle),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge.chip(
                    label: statusStyle.label,
                    background: statusStyle.background,
                    foreground: statusStyle.foreground,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                  const AppSvgIcon(AppAssets.chevronRight, size: 16, color: AppColors.iconChevron),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
