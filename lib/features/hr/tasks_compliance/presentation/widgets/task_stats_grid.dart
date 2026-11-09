import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_stat.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

class _TaskStatStyle {
  final IconData icon;
  final Color color;
  final Color background;
  final Color badgeBackground;
  final Color badgeForeground;

  const _TaskStatStyle({
    required this.icon,
    required this.color,
    required this.background,
    required this.badgeBackground,
    required this.badgeForeground,
  });
}

const Map<TaskStatTag, _TaskStatStyle> _taskStatStyles = {
  TaskStatTag.todayCompletion: _TaskStatStyle(
    icon: Icons.check_circle_outline_rounded,
    color: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
    badgeBackground: Color(0xFFF1F5F9),
    badgeForeground: Color(0xFF64748B),
  ),
  TaskStatTag.pending: _TaskStatStyle(
    icon: Icons.playlist_add_check_rounded,
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
    badgeBackground: Color(0xFFFCF5ED),
    badgeForeground: Color(0xFFB36B21),
  ),
  TaskStatTag.overdue: _TaskStatStyle(
    icon: Icons.error_outline_rounded,
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    badgeBackground: Color(0xFFFBEDED),
    badgeForeground: Color(0xFFD64545),
  ),
  TaskStatTag.recurringActive: _TaskStatStyle(
    icon: Icons.autorenew_rounded,
    color: Color(0xFF0D9488),
    background: Color(0xFFE6F7F5),
    badgeBackground: Color(0xFFE6F7F5),
    badgeForeground: Color(0xFF0D9488),
  ),
};

/// Task Management KPI cards — web: Today's Completion / Pending / Overdue /
/// Recurring Active.
class TaskStatsGrid extends StatelessWidget {
  final List<TaskStat> stats;

  const TaskStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Nested under a padded ListView — zero this or MediaQuery.padding
      // (status bar) is applied again and leaves a large gap above the KPIs.
      padding: EdgeInsets.zero,
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 10),
        crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 10),
        mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 108),
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        final style = _taskStatStyles[stat.tag]!;
        return _TaskStatTile(
          icon: style.icon,
          color: style.color,
          background: style.background,
          value: stat.value,
          label: stat.label,
          badge: stat.badge,
          badgeBackground: style.badgeBackground,
          badgeForeground: style.badgeForeground,
        );
      },
    );
  }
}

class _TaskStatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String value;
  final String label;
  final String? badge;
  final Color badgeBackground;
  final Color badgeForeground;

  const _TaskStatTile({
    required this.icon,
    required this.color,
    required this.background,
    required this.value,
    required this.label,
    required this.badge,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 32);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 10),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: color),
              ),
              const Spacer(),
              if (badge != null && badge!.trim().isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          10,
                        ),
                        color: badgeForeground,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 20),
                  color: AppColors.textHeading,
                  height: 1.05,
                ),
              ),
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 2),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11),
                  color: AppColors.textSecondary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
