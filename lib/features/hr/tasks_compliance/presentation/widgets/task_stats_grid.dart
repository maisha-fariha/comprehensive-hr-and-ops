import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_stat.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import 'stat_tile_card.dart';

class _TaskStatStyle {
  final String? svgAsset;
  final IconData? materialIcon;
  final Color color;
  final Color background;

  const _TaskStatStyle({this.svgAsset, this.materialIcon, required this.color, required this.background});
}

const Map<TaskStatTag, _TaskStatStyle> _taskStatStyles = {
  // Figma export has no plain (unmarked) calendar glyph in the icon set
  // already used elsewhere in this app, so "This Week" falls back to the
  // closest Material icon.
  TaskStatTag.dueToday: _TaskStatStyle(
    svgAsset: AppAssets.clock,
    color: AppColors.criticalRed,
    background: AppColors.criticalIconBackground,
  ),
  TaskStatTag.thisWeek: _TaskStatStyle(
    materialIcon: Icons.calendar_today_outlined,
    color: AppColors.urgentAmber,
    background: AppColors.urgentIconBackground,
  ),
  TaskStatTag.upcoming: _TaskStatStyle(
    svgAsset: AppAssets.calendarCheck,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
  ),
  TaskStatTag.completed: _TaskStatStyle(
    svgAsset: AppAssets.checkCircle,
    color: AppColors.activeGreen,
    background: AppColors.activeIconBackground,
  ),
};

/// The "Tasks" tab's 2x2 stat grid (Due Today / This Week / Upcoming /
/// Completed).
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
        mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 12),
        crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 12),
        // Fixed card height independent of width - see
        // TodaysOverviewSection for why mainAxisExtent (not
        // childAspectRatio) is required here.
        mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 82),
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        final style = _taskStatStyles[stat.tag]!;
        return StatTileCard(
          svgAsset: style.svgAsset,
          materialIcon: style.materialIcon,
          iconColor: style.color,
          iconBackground: style.background,
          value: stat.value,
          valueColor: style.color,
          label: stat.label,
        );
      },
    );
  }
}
