import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

const Map<TasksListSegment, String> _segmentLabels = {
  TasksListSegment.tasksDue: 'Tasks Due',
  TasksListSegment.reviewQueue: 'Review Queue',
  TasksListSegment.recurring: 'Recurring',
};

/// Pill segmented control under the Tasks stats grid:
/// Tasks Due | Review Queue | Recurring.
class TasksListSegmentBar extends StatelessWidget {
  final TasksListSegment selected;
  final ValueChanged<TasksListSegment> onSelected;

  static const Color _trackBackground = Color(0xFFF1F5F9);
  static const Color _selectedLabel = Color(0xFF0D685E);
  static const Color _unselectedLabel = Color(0xFF718096);

  const TasksListSegmentBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 3.5),
      decoration: BoxDecoration(
        color: _trackBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Row(
        children: [
          for (final segment in TasksListSegment.values)
            Expanded(
              child: _Segment(
                label: _segmentLabels[segment]!,
                isSelected: segment == selected,
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
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 10,
          horizontal: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 8),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A2B3C).withValues(alpha: 0.08),
                    offset: Offset(
                      0,
                      ResponsiveHelper.getResponsiveHeight(context, 1),
                    ),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: isSelected
                ? TasksListSegmentBar._selectedLabel
                : TasksListSegmentBar._unselectedLabel,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
