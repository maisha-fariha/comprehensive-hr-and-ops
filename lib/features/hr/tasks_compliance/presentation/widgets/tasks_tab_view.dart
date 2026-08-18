import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'task_list_tile.dart';
import 'task_stats_grid.dart';

/// Body content of the "Tasks" tab: stats grid, Tasks Due list + footer,
/// and Expiring Staff Certifications — matched to the Tasks reference.
class TasksTabView extends StatelessWidget {
  final TasksComplianceOverview overview;

  static const Color _badgeSoft = Color(0xFFEAF0F9);
  static const Color _badgeFg = Color(0xFF2A5DA6);

  const TasksTabView({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final moreCount = overview.tasksDueCount - overview.taskItems.length;
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TaskStatsGrid(stats: overview.taskStats),
            SizedBox(height: sectionGap),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tasks Due',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                _SoftCountBadge(
                  count: overview.tasksDueCount,
                  background: _badgeSoft,
                  foreground: _badgeFg,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (var i = 0; i < overview.taskItems.length; i++) ...[
              if (i > 0) SizedBox(height: cardGap),
              TaskListTile(task: overview.taskItems[i]),
            ],
            if (moreCount > 0) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '+ $moreCount more tasks',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'View all →',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: sectionGap),
            Text(
              'Expiring Staff Certifications',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            const _ExpiringCertificationsCard(),
          ],
        );
      },
    );
  }
}

class _SoftCountBadge extends StatelessWidget {
  final int count;
  final Color background;
  final Color foreground;

  const _SoftCountBadge({
    required this.count,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}

/// UI-only preview of expiring certifications (no domain model yet).
class _ExpiringCertificationsCard extends StatelessWidget {
  const _ExpiringCertificationsCard();

  static const _items = [
    _CertItem(
      initials: 'CPR',
      title: 'CPR Certification',
      subtitle: 'Sarah J. · Sunrise Home',
      badge: 'Expires in 10 days',
      accent: Color(0xFFD64545),
      soft: Color(0xFFFBEDED),
    ),
    _CertItem(
      initials: 'FA',
      title: 'First Aid',
      subtitle: 'Mike T. · Maple Court',
      badge: 'Expires in 22 days',
      accent: Color(0xFFB36B21),
      soft: Color(0xFFFCF5ED),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
            _CertRow(item: _items[i]),
          ],
        ],
      ),
    );
  }
}

class _CertItem {
  final String initials;
  final String title;
  final String subtitle;
  final String badge;
  final Color accent;
  final Color soft;

  const _CertItem({
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accent,
    required this.soft,
  });
}

class _CertRow extends StatelessWidget {
  final _CertItem item;

  const _CertRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: item.soft,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item.initials,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                color: item.accent,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
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
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  item.subtitle,
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
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: item.soft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.badge,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                color: item.accent,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
