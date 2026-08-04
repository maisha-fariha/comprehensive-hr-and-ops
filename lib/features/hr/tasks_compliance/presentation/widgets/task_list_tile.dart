import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

class _CategoryStyle {
  final String svgAsset;
  final Color color;
  final Color background;
  final String label;

  const _CategoryStyle({
    required this.svgAsset,
    required this.color,
    required this.background,
    required this.label,
  });
}

const Map<TaskCategory, _CategoryStyle> _categoryStyles = {
  TaskCategory.safety: _CategoryStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_fire.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    label: 'Safety',
  ),
  TaskCategory.facilities: _CategoryStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_kitchen.svg',
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
    label: 'Facilities',
  ),
  TaskCategory.medication: _CategoryStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_cart_check.svg',
    color: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
    label: 'Medication',
  ),
  TaskCategory.audit: _CategoryStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_shield.svg',
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
    label: 'Audit',
  ),
};

class _StatusStyle {
  final Color color;
  final Color background;
  final String label;

  const _StatusStyle({
    required this.color,
    required this.background,
    required this.label,
  });
}

const Map<TaskStatus, _StatusStyle> _statusStyles = {
  TaskStatus.overdue: _StatusStyle(
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    label: 'Overdue',
  ),
  TaskStatus.due: _StatusStyle(
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
    label: 'Due',
  ),
  TaskStatus.upcoming: _StatusStyle(
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
    label: 'Upcoming',
  ),
};

/// A single "Tasks Due" card — matched to the Tasks tab reference.
class TaskListTile extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onTap;

  static const Color _overdueBorder = Color(0xFFF3DADA);

  const TaskListTile({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final categoryStyle = _categoryStyles[task.category]!;
    final statusStyle = _statusStyles[task.status]!;
    final isOverdue = task.status == TaskStatus.overdue;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isOverdue ? _overdueBorder : AppColors.cardBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: categoryStyle.background,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(
                categoryStyle.svgAsset,
                size: 19,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textHeading,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Row(
                    children: [
                      AppSvgIcon(
                        task.isToday
                            ? 'assets/icons/tasks_compliance/tasks_clock.svg'
                            : 'assets/icons/tasks_compliance/tasks_calendar.svg',
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                      Flexible(
                        child: Text(
                          task.timeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                  Container(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      categoryStyle.label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                        color: AppColors.textBody,
                        height: 1.1,
                      ),
                    ),
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
                color: statusStyle.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusStyle.label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                  color: statusStyle.color,
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
