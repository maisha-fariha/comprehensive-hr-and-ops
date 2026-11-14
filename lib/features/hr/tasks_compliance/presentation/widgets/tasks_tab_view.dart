import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'task_analytics_section.dart';
import 'task_list_tile.dart';
import 'task_stats_grid.dart';
import 'tasks_list_segment_bar.dart';

/// Body content of Task Management: KPIs, charts, tabs, filters, list.
class TasksTabView extends StatefulWidget {
  final TasksComplianceOverview overview;
  final void Function(TaskItem task)? onTaskTap;
  final void Function(TaskItem task)? onPauseRecurring;
  final void Function(TaskItem task)? onResumeRecurring;
  final Future<void> Function(TaskItem task)? onApproveReview;
  final Future<void> Function(TaskItem task)? onRejectReview;

  const TasksTabView({
    super.key,
    required this.overview,
    this.onTaskTap,
    this.onPauseRecurring,
    this.onResumeRecurring,
    this.onApproveReview,
    this.onRejectReview,
  });

  @override
  State<TasksTabView> createState() => _TasksTabViewState();
}

class _TasksTabViewState extends State<TasksTabView> {
  TasksListSegment _segment = TasksListSegment.tasksDue;
  final _search = TextEditingController();
  String _staff = 'All Staff';
  String _residence = 'All Residences';
  String _status = 'All Status';
  String _priority = 'All Priorities';
  String _type = 'All Types';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _sectionTitle => switch (_segment) {
        TasksListSegment.tasksDue => 'All Tasks',
        TasksListSegment.reviewQueue => 'Review Queue',
        TasksListSegment.recurring => 'Recurring',
      };

  List<TaskItem> get _source => switch (_segment) {
        TasksListSegment.tasksDue => widget.overview.taskItems,
        TasksListSegment.reviewQueue => widget.overview.reviewQueueItems,
        TasksListSegment.recurring => widget.overview.recurringItems,
      };

  List<TaskItem> get _tasks {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final task in _source)
        if (_matches(task, q)) task,
    ];
  }

  bool get _filtersActive =>
      _search.text.trim().isNotEmpty ||
      _staff != 'All Staff' ||
      _residence != 'All Residences' ||
      _status != 'All Status' ||
      _priority != 'All Priorities' ||
      _type != 'All Types';

  bool _matches(TaskItem task, String q) {
    if (q.isNotEmpty) {
      final hay = [
        task.title,
        task.assigneeName,
        task.residenceName,
        task.clientName,
        task.typeLabel,
      ].join(' ').toLowerCase();
      if (!hay.contains(q)) return false;
    }
    if (_staff != 'All Staff' && task.assigneeName != _staff) return false;
    if (_residence != 'All Residences' &&
        _residenceLabel(task) != _residence) {
      return false;
    }
    if (_priority != 'All Priorities' && task.priorityLabel != _priority) {
      return false;
    }
    if (_type != 'All Types' && task.typeLabel != _type) return false;
    if (_status != 'All Status') {
      final label = task.awaitingReview
          ? 'Awaiting review'
          : switch (task.status) {
              TaskStatus.completed => 'Completed',
              TaskStatus.overdue => 'Overdue',
              _ => 'Pending',
            };
      if (label != _status) return false;
    }
    return true;
  }

  String _residenceLabel(TaskItem task) =>
      task.residenceName.trim().isEmpty ? '—' : task.residenceName.trim();

  List<String> _unique(Iterable<String> values, String allLabel) {
    final set = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) set.add(trimmed);
    }
    final sorted = set.toList()..sort();
    return [allLabel, ...sorted];
  }

  void _clearFilters() {
    setState(() {
      _search.clear();
      _staff = 'All Staff';
      _residence = 'All Residences';
      _status = 'All Status';
      _priority = 'All Priorities';
      _type = 'All Types';
    });
  }

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    final tasks = _tasks;
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 16);
    final staffOptions = _unique(
      overview.taskItems.map((t) => t.assigneeName),
      'All Staff',
    );
    final residenceOptions = _unique(
      overview.taskItems.map(_residenceLabel),
      'All Residences',
    );
    final statusOptions = const [
      'All Status',
      'Pending',
      'Completed',
      'Overdue',
      'Awaiting review',
    ];
    final priorityOptions = _unique(
      overview.taskItems.map((t) => t.priorityLabel),
      'All Priorities',
    );
    final typeOptions = _unique(
      overview.taskItems.map((t) => t.typeLabel),
      'All Types',
    );

    final pendingBadge = switch (_segment) {
      TasksListSegment.tasksDue => '${overview.tasksDueCount} pending',
      TasksListSegment.reviewQueue =>
        '${overview.reviewQueueCount} awaiting',
      TasksListSegment.recurring => '${overview.recurringCount} active',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskStatsGrid(stats: overview.taskStats),
        SizedBox(height: sectionGap),
        TaskAnalyticsSection(analytics: overview.taskAnalytics),
        SizedBox(height: sectionGap),
        TasksListSegmentBar(
          selected: _segment,
          reviewQueueCount: overview.reviewQueueCount,
          recurringCount: overview.recurringCount,
          onSelected: (segment) => setState(() => _segment = segment),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        _FilterBar(
          search: _search,
          onSearchChanged: (_) => setState(() {}),
          staff: _staff,
          residence: _residence,
          status: _status,
          priority: _priority,
          type: _type,
          staffOptions: staffOptions,
          residenceOptions: residenceOptions,
          statusOptions: statusOptions,
          priorityOptions: priorityOptions,
          typeOptions: typeOptions,
          onStaff: (v) => setState(() => _staff = v),
          onResidence: (v) => setState(() => _residence = v),
          onStatus: (v) => setState(() => _status = v),
          onPriority: (v) => setState(() => _priority = v),
          onType: (v) => setState(() => _type = v),
          onClear: _filtersActive ? _clearFilters : null,
        ),
        SizedBox(height: sectionGap),
        Row(
          children: [
            Expanded(
              child: Text(
                _sectionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            _PendingBadge(label: pendingBadge),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
        Text(
          'Track progress across residences and staff',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (tasks.isEmpty)
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              vertical: 28,
            ),
            child: Text(
              _segment == TasksListSegment.tasksDue
                  ? 'No tasks yet.'
                  : _segment == TasksListSegment.reviewQueue
                      ? 'No tasks waiting for review.'
                      : 'No recurring tasks yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            TaskListTile(
              task: tasks[i],
              onTap: widget.onTaskTap == null
                  ? null
                  : () => widget.onTaskTap!(tasks[i]),
            ),
            // Review Queue: approve / send-back live in the task detail sheet
            // only (web parity) — not as list-row footer buttons.
            if (_segment == TasksListSegment.recurring &&
                (widget.onPauseRecurring != null ||
                    widget.onResumeRecurring != null)) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
              _RecurringActionsRow(
                isActive: tasks[i].status != TaskStatus.completed,
                onPause: widget.onPauseRecurring == null
                    ? null
                    : () => widget.onPauseRecurring!(tasks[i]),
                onResume: widget.onResumeRecurring == null
                    ? null
                    : () => widget.onResumeRecurring!(tasks[i]),
              ),
            ],
          ],
      ],
    );
  }
}

class _PendingBadge extends StatelessWidget {
  final String label;

  const _PendingBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;
  final String staff;
  final String residence;
  final String status;
  final String priority;
  final String type;
  final List<String> staffOptions;
  final List<String> residenceOptions;
  final List<String> statusOptions;
  final List<String> priorityOptions;
  final List<String> typeOptions;
  final ValueChanged<String> onStaff;
  final ValueChanged<String> onResidence;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onPriority;
  final ValueChanged<String> onType;
  final VoidCallback? onClear;

  const _FilterBar({
    required this.search,
    required this.onSearchChanged,
    required this.staff,
    required this.residence,
    required this.status,
    required this.priority,
    required this.type,
    required this.staffOptions,
    required this.residenceOptions,
    required this.statusOptions,
    required this.priorityOptions,
    required this.typeOptions,
    required this.onStaff,
    required this.onResidence,
    required this.onStatus,
    required this.onPriority,
    required this.onType,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: search,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            hintStyle: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterMenu(
              value: staff,
              options: staffOptions,
              onChanged: onStaff,
            ),
            _FilterMenu(
              value: residence,
              options: residenceOptions,
              onChanged: onResidence,
            ),
            _FilterMenu(
              value: status,
              options: statusOptions,
              onChanged: onStatus,
            ),
            _FilterMenu(
              value: priority,
              options: priorityOptions,
              onChanged: onPriority,
            ),
            _FilterMenu(
              value: type,
              options: typeOptions,
              onChanged: onType,
            ),
            if (onClear != null)
              TextButton(
                onPressed: onClear,
                child: const Text(
                  'Clear Filters',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FilterMenu extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterMenu({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isDense: true,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: AppColors.textHeading,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class _RecurringActionsRow extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const _RecurringActionsRow({
    required this.isActive,
    this.onPause,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: _ActionChip(
        label: isActive ? 'Pause' : 'Resume',
        filled: true,
        onTap: isActive ? onPause : onResume,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.label,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 10);
    return Material(
      color: filled ? AppColors.primaryNavy : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          alignment: Alignment.center,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: filled ? null : Border.all(color: AppColors.searchBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: filled ? Colors.white : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}
