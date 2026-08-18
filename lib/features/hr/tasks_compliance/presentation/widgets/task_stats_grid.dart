import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/task_stat.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

class _TaskStatStyle {
  final String svgAsset;
  final Color color;
  final Color background;

  const _TaskStatStyle({
    required this.svgAsset,
    required this.color,
    required this.background,
  });
}

const Map<TaskStatTag, _TaskStatStyle> _taskStatStyles = {
  TaskStatTag.dueToday: _TaskStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_clock.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
  ),
  TaskStatTag.thisWeek: _TaskStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_calendar.svg',
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
  ),
  TaskStatTag.upcoming: _TaskStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_upcoming.svg',
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
  ),
  TaskStatTag.completed: _TaskStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_completed.svg',
    color: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
  ),
};

/// Tasks tab 2x2 stat grid — matched to the Tasks reference.
class TaskStatsGrid extends StatelessWidget {
  final List<TaskStat> stats;

  const TaskStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 10),
        crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 10),
        mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 78),
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        final style = _taskStatStyles[stat.tag]!;
        return _TaskStatTile(
          svgAsset: style.svgAsset,
          color: style.color,
          background: style.background,
          value: stat.value,
          label: stat.label,
        );
      },
    );
  }
}

class _TaskStatTile extends StatelessWidget {
  final String svgAsset;
  final Color color;
  final Color background;
  final String value;
  final String label;

  const _TaskStatTile({
    required this.svgAsset,
    required this.color,
    required this.background,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(svgAsset, size: 19, color: color),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    color: color,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
