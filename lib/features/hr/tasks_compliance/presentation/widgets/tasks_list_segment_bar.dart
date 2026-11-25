import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

const Map<TasksListSegment, String> _segmentLabels = {
  TasksListSegment.tasksDue: 'All tasks',
  TasksListSegment.reviewQueue: 'Review queue',
  TasksListSegment.recurring: 'Recurring',
};

/// Underline tabs: All tasks | Review queue | Recurring — with count badges.
class TasksListSegmentBar extends StatelessWidget {
  final TasksListSegment selected;
  final ValueChanged<TasksListSegment> onSelected;
  final int reviewQueueCount;
  final int recurringCount;

  static const Color _selectedLabel = Color(0xFF0D685E);
  static const Color _unselectedLabel = Color(0xFF718096);
  static const Color _reviewBadge = Color(0xFFF59E0B);

  const TasksListSegmentBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.reviewQueueCount = 0,
    this.recurringCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          for (final segment in TasksListSegment.values)
            Expanded(
              child: _Segment(
                label: _segmentLabels[segment]!,
                isSelected: segment == selected,
                badgeCount: switch (segment) {
                  TasksListSegment.reviewQueue => reviewQueueCount,
                  TasksListSegment.recurring => recurringCount,
                  TasksListSegment.tasksDue => 0,
                },
                onTap: () => onSelected(segment),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              vertical: 10,
              horizontal: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: isSelected
                          ? TasksListSegmentBar._selectedLabel
                          : TasksListSegmentBar._unselectedLabel,
                      height: 1.1,
                    ),
                  ),
                ),
                if (badgeCount > 0) ...[
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 5),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      minWidth: ResponsiveHelper.getResponsiveSize(context, 18),
                      minHeight:
                          ResponsiveHelper.getResponsiveSize(context, 18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: const BoxDecoration(
                      color: TasksListSegmentBar._reviewBadge,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 10),
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 2.5,
            width: double.infinity,
            color: isSelected
                ? TasksListSegmentBar._selectedLabel
                : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
