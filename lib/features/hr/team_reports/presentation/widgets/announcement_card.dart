import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../team_reports_assets.dart';
import 'team_reports_icon_box.dart';

class _AnnouncementStyle {
  final IconData materialIcon;
  final Color color;
  final Color background;

  const _AnnouncementStyle({required this.materialIcon, required this.color, required this.background});
}

// No matching exported SVGs for a document/policy glyph or a graduation-cap
// glyph; both fall back to Material icons (see the feature's final report).
const Map<AnnouncementTag, _AnnouncementStyle> _announcementStyles = {
  AnnouncementTag.policy: _AnnouncementStyle(
    materialIcon: Icons.description_outlined,
    color: AppColors.criticalRed,
    background: AppColors.criticalIconBackground,
  ),
  AnnouncementTag.training: _AnnouncementStyle(
    materialIcon: Icons.school_outlined,
    color: AppColors.nightPurple,
    background: AppColors.nightBackground,
  ),
};

const Map<AnnouncementPriority, ({Color color, Color background, String label})> _priorityStyles = {
  AnnouncementPriority.highPriority: (
    color: AppColors.criticalRed,
    background: AppColors.criticalBackground,
    label: 'High Priority',
  ),
  AnnouncementPriority.upcoming: (
    color: AppColors.infoBlue,
    background: AppColors.infoBackground,
    label: 'Upcoming',
  ),
};

/// A single card in the Messages tab's "Important Announcements" list.
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onTap;

  const AnnouncementCard({super.key, required this.announcement, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _announcementStyles[announcement.tag]!;
    final priorityStyle = _priorityStyles[announcement.priority]!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TeamReportsIconBox(
              materialIcon: style.materialIcon,
              color: style.color,
              background: style.background,
              boxSize: 42,
              iconSize: 20,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    announcement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Row(
                    children: [
                      const AppSvgIcon(TeamReportsAssets.dateCaptionCalendar, size: 11, color: AppColors.textFaint),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                      Flexible(
                        child: Text(
                          announcement.dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            StatusBadge.chip(
              label: priorityStyle.label,
              background: priorityStyle.background,
              foreground: priorityStyle.color,
            ),
          ],
        ),
      ),
    );
  }
}
