import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_messages_enums.dart';

const Map<TaskFilter, String> _filterLabels = {
  TaskFilter.all: 'All',
  TaskFilter.overdue: 'Overdue',
  TaskFilter.dueToday: 'Due Today',
  TaskFilter.done: 'Done',
};

/// Horizontally scrollable filter chips above the task list.
class TaskFilterChips extends StatelessWidget {
  final TaskFilter selected;
  final int Function(TaskFilter filter) countFor;
  final ValueChanged<TaskFilter> onSelected;

  static const Color _selectedBg = Color(0xFF0E7C7B);
  static const Color _unselectedInk = Color(0xFF6B7280);
  static const Color _unselectedBorder = Color(0xFFE5E9EF);

  const TaskFilterChips({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final filter in TaskFilter.values) ...[
            if (filter != TaskFilter.values.first)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            _FilterChip(
              label: '${_filterLabels[filter]} (${countFor(filter)})',
              isSelected: filter == selected,
              onTap: () => onSelected(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
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
        duration: const Duration(milliseconds: 150),
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected ? TaskFilterChips._selectedBg : AppColors.surfaceWhite,
          border: Border.all(
            color: isSelected ? TaskFilterChips._selectedBg : TaskFilterChips._unselectedBorder,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: isSelected ? Colors.white : TaskFilterChips._unselectedInk,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
