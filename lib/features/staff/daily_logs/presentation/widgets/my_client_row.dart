import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../staff_daily_logs_constants.dart';
import 'client_status_style.dart';
import 'initials_avatar.dart';

/// A single My Clients list card: avatar + status dot, shift eyebrow, name,
/// clock/check caption, trailing status pill and chevron.
class MyClientRow extends StatelessWidget {
  final StaffClientLogEntry entry;
  final int avatarPaletteIndex;

  /// Kept for call-site compatibility; each row is now its own card so
  /// dividers are unused.
  final bool showDivider;
  final VoidCallback? onTap;

  static const String _staffClock = 'assets/icons/staff_daily_logs/clock.svg';
  static const String _staffCheck = 'assets/icons/staff_daily_logs/circle_check.svg';

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
    final avatarColors = StaffDailyLogsConstants
        .avatarPalette[avatarPaletteIndex % StaffDailyLogsConstants.avatarPalette.length];
    final isSubmitted = entry.status == ClientLogStatus.submitted;
    final captionIcon = isSubmitted ? _staffCheck : _staffClock;
    final captionIconColor =
        isSubmitted ? statusStyle.foreground : AppColors.textMuted;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 10),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.05),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InitialsAvatar(
                initials: entry.initials,
                background: avatarColors.background,
                foreground: avatarColors.foreground,
                size: 44,
                statusDotColor: statusStyle.foreground,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.shiftLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                    Text(
                      entry.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                        color: AppColors.textHeading,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                    Row(
                      children: [
                        AppSvgIcon(captionIcon, size: 12, color: captionIconColor),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                        Flexible(
                          child: Text(
                            entry.subtitleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w400,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              color: AppColors.textMuted,
                              height: 1.2,
                            ),
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
                  StatusBadge.pill(
                    label: statusStyle.label,
                    background: statusStyle.background,
                    foreground: statusStyle.foreground,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                  const AppSvgIcon(
                    AppAssets.chevronRight,
                    size: 16,
                    color: AppColors.iconChevron,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
