import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/team_reports_enums.dart';
import 'team_reports_icon_box.dart';

class _AnnouncementStyle {
  final IconData materialIcon;
  final Color color;
  final Color background;

  const _AnnouncementStyle({
    required this.materialIcon,
    required this.color,
    required this.background,
  });
}

// No matching SVGs for document-with-plus / graduation-cap in team_reports.
const Map<AnnouncementTag, _AnnouncementStyle> _announcementStyles = {
  AnnouncementTag.policy: _AnnouncementStyle(
    materialIcon: Icons.note_add_outlined,
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
  ),
  AnnouncementTag.training: _AnnouncementStyle(
    materialIcon: Icons.school_outlined,
    color: Color(0xFF6A4BC7),
    background: Color(0xFFF0ECFB),
  ),
};

const Map<AnnouncementPriority, ({Color color, Color background, String label})> _priorityStyles = {
  AnnouncementPriority.highPriority: (
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    label: 'High Priority',
  ),
  AnnouncementPriority.upcoming: (
    color: Color(0xFFB4791C),
    background: Color(0xFFFCF5ED),
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
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return GestureDetector(
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
        ),
        child: Row(
          children: [
            TeamReportsIconBox(
              materialIcon: style.materialIcon,
              color: style.color,
              background: style.background,
              boxSize: 42,
              iconSize: 20,
              radius: 12,
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
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textHeading,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Row(
                    children: [
                      const AppSvgIcon(
                        'assets/icons/team_reports/team_calendar.svg',
                        size: 11,
                        color: AppColors.textFaint,
                      ),
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
            Container(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: priorityStyle.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                priorityStyle.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                  color: priorityStyle.color,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
