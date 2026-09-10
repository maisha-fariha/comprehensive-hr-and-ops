import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/expiring_certificate.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'task_list_tile.dart';
import 'task_stats_grid.dart';
import 'tasks_list_segment_bar.dart';

/// Body content of the "Tasks" tab: stats grid, list segment bar
/// (Tasks Due / Review Queue / Recurring), list + expiring certificates.
class TasksTabView extends StatefulWidget {
  final TasksComplianceOverview overview;
  final VoidCallback? onNewTaskTap;
  final void Function(TaskItem task)? onTaskTap;
  final void Function(TaskItem task)? onPauseRecurring;
  final void Function(TaskItem task)? onResumeRecurring;
  final void Function(TaskItem task)? onApproveReview;
  final void Function(TaskItem task)? onRejectReview;

  const TasksTabView({
    super.key,
    required this.overview,
    this.onNewTaskTap,
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
  static const Color _badgeSoft = Color(0xFFEAF0F9);
  static const Color _badgeFg = Color(0xFF2A5DA6);

  TasksListSegment _segment = TasksListSegment.tasksDue;

  String get _sectionTitle => switch (_segment) {
        TasksListSegment.tasksDue => 'Tasks Due',
        TasksListSegment.reviewQueue => 'Review Queue',
        TasksListSegment.recurring => 'Recurring',
      };

  List<TaskItem> get _tasks => switch (_segment) {
        TasksListSegment.tasksDue => widget.overview.taskItems,
        TasksListSegment.reviewQueue => widget.overview.reviewQueueItems,
        TasksListSegment.recurring => widget.overview.recurringItems,
      };

  int get _count => switch (_segment) {
        TasksListSegment.tasksDue => widget.overview.tasksDueCount,
        TasksListSegment.reviewQueue =>
          widget.overview.reviewQueueItems.length,
        TasksListSegment.recurring => widget.overview.recurringItems.length,
      };

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    final tasks = _tasks;
    final moreCount = _segment == TasksListSegment.tasksDue
        ? overview.tasksDueCount - overview.taskItems.length
        : 0;
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _NewTaskButton(onTap: widget.onNewTaskTap),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        TaskStatsGrid(stats: overview.taskStats),
        SizedBox(height: sectionGap),
        TasksListSegmentBar(
          selected: _segment,
          onSelected: (segment) => setState(() => _segment = segment),
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
            _SoftCountBadge(
              count: _count,
              background: _badgeSoft,
              foreground: _badgeFg,
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        if (tasks.isEmpty)
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              vertical: 28,
            ),
            child: Text(
              _segment == TasksListSegment.tasksDue
                  ? 'No tasks due right now.'
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
            if (_segment == TasksListSegment.reviewQueue) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
              _ReviewActionsRow(
                onApprove: widget.onApproveReview == null
                    ? null
                    : () => widget.onApproveReview!(tasks[i]),
                onReject: widget.onRejectReview == null
                    ? null
                    : () => widget.onRejectReview!(tasks[i]),
              ),
            ],
            if (_segment == TasksListSegment.recurring) ...[
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
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                'View all →',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.secondaryTeal,
                ),
              ),
            ],
          ),
        ],
        if (overview.expiringCertificates.isNotEmpty) ...[
          SizedBox(height: sectionGap),
          Text(
            'Expiring Staff Certifications',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (var i = 0; i < overview.expiringCertificates.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            _CertificateTile(certificate: overview.expiringCertificates[i]),
          ],
        ],
      ],
    );
  }
}

class _ReviewActionsRow extends StatelessWidget {
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ReviewActionsRow({this.onApprove, this.onReject});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            label: 'Reject',
            filled: false,
            onTap: onReject,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Expanded(
          child: _ActionChip(
            label: 'Approve',
            filled: true,
            onTap: onApprove,
          ),
        ),
      ],
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

class _CertificateTile extends StatelessWidget {
  final ExpiringCertificate certificate;

  const _CertificateTile({required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            certificate.title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            certificate.staffName,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            certificate.expiryLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.urgentAmber,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewTaskButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _NewTaskButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);
    return Material(
      color: AppColors.secondaryTeal,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 14,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: Colors.white,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                'New Task',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
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
