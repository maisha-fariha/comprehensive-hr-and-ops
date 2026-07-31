import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

class _CategoryStyle {
  final IconData materialIcon;
  final Color color;
  final Color background;
  final String label;

  const _CategoryStyle({
    required this.materialIcon,
    required this.color,
    required this.background,
    required this.label,
  });
}

// Figma export has no exact SVG match for these glyphs (flame, counter/table,
// medication cart, shield-check) in the icon set already used elsewhere in
// this app, so each falls back to the closest Material icon.
const Map<TaskCategory, _CategoryStyle> _categoryStyles = {
  TaskCategory.safety: _CategoryStyle(
    materialIcon: Icons.local_fire_department_rounded,
    color: AppColors.criticalRed,
    background: AppColors.criticalIconBackground,
    label: 'Safety',
  ),
  TaskCategory.facilities: _CategoryStyle(
    materialIcon: Icons.countertops_outlined,
    color: AppColors.urgentAmber,
    background: AppColors.urgentIconBackground,
    label: 'Facilities',
  ),
  TaskCategory.medication: _CategoryStyle(
    materialIcon: Icons.medical_services_outlined,
    color: AppColors.activeGreen,
    background: AppColors.activeIconBackground,
    label: 'Medication',
  ),
  TaskCategory.audit: _CategoryStyle(
    materialIcon: Icons.verified_user_rounded,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
    label: 'Audit',
  ),
};

class _StatusStyle {
  final Color color;
  final Color background;
  final String label;

  const _StatusStyle({required this.color, required this.background, required this.label});
}

const Map<TaskStatus, _StatusStyle> _statusStyles = {
  TaskStatus.overdue: _StatusStyle(
    color: AppColors.criticalRed,
    background: AppColors.criticalBackground,
    label: 'Overdue',
  ),
  TaskStatus.due: _StatusStyle(
    color: AppColors.urgentAmber,
    background: AppColors.urgentBackground,
    label: 'Due',
  ),
  TaskStatus.upcoming: _StatusStyle(
    color: AppColors.infoBlue,
    background: AppColors.infoBackground,
    label: 'Upcoming',
  ),
};

/// A single row in the "Tasks Due" list on the "Tasks" tab.
class TaskListTile extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onTap;

  const TaskListTile({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final categoryStyle = _categoryStyles[task.category]!;
    final statusStyle = _statusStyles[task.status]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 42);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: categoryStyle.background,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 13)),
              ),
              alignment: Alignment.center,
              child: Icon(
                categoryStyle.materialIcon,
                size: ResponsiveHelper.getResponsiveSize(context, 19),
                color: categoryStyle.color,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                      color: AppColors.textHeading,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveHeight(context, 4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          task.isToday ? Icons.access_time_rounded : Icons.calendar_today_outlined,
                          size: ResponsiveHelper.getResponsiveSize(context, 12),
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                        Text(
                          task.timeLabel,
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
                  Container(
                    padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 999)),
                    ),
                    child: Text(
                      categoryStyle.label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            StatusBadge.pill(
              label: statusStyle.label,
              background: statusStyle.background,
              foreground: statusStyle.color,
            ),
          ],
        ),
      ),
    );
  }
}
