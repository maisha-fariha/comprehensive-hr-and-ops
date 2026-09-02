import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/assignee.dart';
import '../../domain/entities/compliance_checklist_item.dart';
import '../../domain/entities/compliance_stat.dart';
import '../../domain/entities/compliance_summary.dart';
import '../../domain/entities/corrective_action.dart';
import '../../domain/entities/corrective_stat.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/task_stat.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import '../../domain/entities/tasks_compliance_overview.dart';

abstract final class TasksComplianceMapper {
  static TasksComplianceOverview compose({
    required dynamic statsBody,
    required dynamic tasksBody,
    required dynamic scoreBody,
    required dynamic overviewBody,
    required dynamic checksBody,
    required dynamic actionsBody,
    required String? residenceName,
  }) {
    final stats = JsonCodec.unwrapMap(statsBody);
    final tasks = JsonCodec.unwrapList(tasksBody)
        .whereType<Map>()
        .map((item) => _task(JsonCodec.asMap(item)))
        .toList();
    final scoreJson = JsonCodec.unwrapMap(scoreBody);
    final overview = JsonCodec.unwrapMap(overviewBody);
    final checks = JsonCodec.unwrapList(checksBody)
        .whereType<Map>()
        .map((item) => _check(JsonCodec.asMap(item)))
        .toList();
    final actions = JsonCodec.unwrapList(actionsBody)
        .whereType<Map>()
        .map((item) => _action(JsonCodec.asMap(item)))
        .toList();
    final dueToday = JsonCodec.integerOr(
      stats['dueToday'] ?? stats['due'],
      tasks.where((item) => item.isToday).length,
    );
    final thisWeek = JsonCodec.integerOr(stats['thisWeek'], 0);
    final upcoming = JsonCodec.integerOr(
      stats['upcoming'],
      tasks.where((item) => item.status == TaskStatus.upcoming).length,
    );
    final completed = JsonCodec.integerOr(
      stats['completed'],
      tasks.where((item) => item.status == TaskStatus.due && !item.isToday).length,
    );
    final percent = JsonCodec.integer(
          scoreJson['percent'] ??
              scoreJson['score'] ??
              overview['percent'] ??
              overview['score'],
        ) ??
        0;
    final passing = JsonCodec.integer(overview['passing'] ?? overview['completed']);
    final total = JsonCodec.integer(overview['total'] ?? overview['checks']);
    final pending = checks
        .where((item) => item.status == ComplianceItemStatus.pending)
        .length;
    final dueSoon = checks
        .where((item) => item.status == ComplianceItemStatus.dueSoon)
        .length;
    final inProgress = actions
        .where((item) => item.status == CorrectiveActionStatus.inProgress)
        .length;
    final overdueActions =
        actions.where((item) => item.status == CorrectiveActionStatus.overdue).length;

    return TasksComplianceOverview(
      headerSubtitle: [
        ?residenceName,
        'Today',
      ].join(' · '),
      taskStats: [
        TaskStat(id: 'due-today', tag: TaskStatTag.dueToday, value: '$dueToday', label: 'Due Today'),
        TaskStat(id: 'this-week', tag: TaskStatTag.thisWeek, value: '$thisWeek', label: 'This Week'),
        TaskStat(id: 'upcoming', tag: TaskStatTag.upcoming, value: '$upcoming', label: 'Upcoming'),
        TaskStat(id: 'completed', tag: TaskStatTag.completed, value: '$completed', label: 'Completed'),
      ],
      tasksDueCount: dueToday,
      taskItems: tasks,
      complianceSummary: ComplianceSummary(
        percent: percent,
        description: passing != null && total != null
            ? '$passing of $total checks passing this period.'
            : 'Live compliance score from the care home.',
        trendLabel: JsonCodec.stringOr(overview['trendLabel'] ?? scoreJson['trend'], ''),
      ),
      complianceStats: [
        ComplianceStat(
          id: 'completed',
          tag: ComplianceStatTag.completed,
          value: '${passing ?? checks.where((item) => item.status == ComplianceItemStatus.completed).length}',
          label: 'Completed',
        ),
        ComplianceStat(
          id: 'pending-review',
          tag: ComplianceStatTag.pendingReview,
          value: '$pending',
          label: 'Pending Review',
        ),
        ComplianceStat(
          id: 'needs-attention',
          tag: ComplianceStatTag.needsAttention,
          value: '$dueSoon',
          label: 'Needs Attention',
        ),
      ],
      complianceChecklistCount: checks.length,
      complianceChecklistItems: checks,
      correctiveStats: [
        CorrectiveStat(
          id: 'open',
          tag: CorrectiveStatTag.open,
          value: '${actions.length}',
          label: 'Open',
        ),
        CorrectiveStat(
          id: 'in-progress',
          tag: CorrectiveStatTag.inProgress,
          value: '$inProgress',
          label: 'In Progress',
        ),
        CorrectiveStat(
          id: 'overdue',
          tag: CorrectiveStatTag.overdue,
          value: '$overdueActions',
          label: 'Overdue',
        ),
      ],
      correctiveActionsCount: actions.length,
      correctiveActions: actions,
    );
  }

  static TaskItem _task(Map<String, dynamic> json) {
    final due = JsonCodec.dateTime(json['dueAt'] ?? json['scheduledAt'] ?? json['date']);
    final now = DateTime.now();
    final isToday = due != null &&
        due.toLocal().year == now.year &&
        due.toLocal().month == now.month &&
        due.toLocal().day == now.day;
    final statusRaw = (JsonCodec.string(json['status'] ?? json['state']) ?? '')
        .toLowerCase();
    final status = switch (statusRaw) {
      'overdue' || 'late' => TaskStatus.overdue,
      'upcoming' || 'scheduled' => TaskStatus.upcoming,
      _ => isToday ? TaskStatus.due : TaskStatus.upcoming,
    };
    return TaskItem(
      id: JsonCodec.stringOr(json['id'], 'task'),
      title: JsonCodec.stringOr(json['title'] ?? json['name'], 'Task'),
      category: _category(json['category'] ?? json['type']),
      timeLabel: due == null
          ? JsonCodec.stringOr(json['timeLabel'], '')
          : isToday
              ? 'Today, ${IsoDateRange.timeLabel(due.toLocal())}'
              : IsoDateRange.formatShortDate(due.toLocal()),
      isToday: isToday,
      status: status,
    );
  }

  static ComplianceChecklistItem _check(Map<String, dynamic> json) {
    final assignee = _assignee(json['assignee'] ?? json['owner'] ?? json['assignedTo']);
    final at = JsonCodec.dateTime(json['dueAt'] ?? json['completedAt'] ?? json['date']);
    final statusRaw = (JsonCodec.string(json['status'] ?? json['state']) ?? '')
        .toLowerCase();
    final status = switch (statusRaw) {
      'completed' || 'pass' || 'passed' => ComplianceItemStatus.completed,
      'due_soon' || 'duesoon' || 'warning' => ComplianceItemStatus.dueSoon,
      _ => ComplianceItemStatus.pending,
    };
    return ComplianceChecklistItem(
      id: JsonCodec.stringOr(json['id'], 'check'),
      title: JsonCodec.stringOr(json['title'] ?? json['name'] ?? json['requirement'], 'Check'),
      category: JsonCodec.stringOr(json['category'] ?? json['area'], 'Compliance'),
      assignee: assignee,
      dateLabel: at == null ? '' : IsoDateRange.formatShortDate(at.toLocal()),
      status: status,
    );
  }

  static CorrectiveAction _action(Map<String, dynamic> json) {
    final due = JsonCodec.dateTime(json['dueAt'] ?? json['deadline']);
    final late = due != null && due.isBefore(DateTime.now());
    final statusRaw = (JsonCodec.string(json['status'] ?? json['state']) ?? '')
        .toLowerCase();
    return CorrectiveAction(
      id: JsonCodec.stringOr(json['id'], 'action'),
      issueType: _issueType(json['issueType'] ?? json['type'] ?? json['category']),
      title: JsonCodec.stringOr(json['title'] ?? json['name'], 'Corrective action'),
      severity: (JsonCodec.string(json['severity'] ?? json['priority']) ?? '')
                  .toLowerCase()
                  .contains('high')
          ? CorrectiveSeverity.high
          : CorrectiveSeverity.medium,
      locationCategory: JsonCodec.stringOr(json['area'] ?? json['category'], 'Residence'),
      locationName: JsonCodec.stringOr(
        json['location'] ??
            json['residenceName'] ??
            JsonCodec.mapAt(json, 'residence')?['name'],
        '',
      ),
      assignee: _assignee(json['assignee'] ?? json['owner'] ?? json['assignedTo']),
      dueDateLabel: due == null
          ? JsonCodec.stringOr(json['dueLabel'], '')
          : late
              ? '${IsoDateRange.formatShortDate(due.toLocal())} · late'
              : IsoDateRange.formatShortDate(due.toLocal()),
      isDueLate: late,
      status: statusRaw.contains('overdue') || late
          ? CorrectiveActionStatus.overdue
          : CorrectiveActionStatus.inProgress,
    );
  }

  static Assignee _assignee(dynamic value) {
    final name = IsoDateRange.personName(value);
    return Assignee(
      initials: IsoDateRange.initials(name, fallback: '--'),
      name: name,
      colorTag: AssigneeColorTag.blue,
    );
  }

  static TaskCategory _category(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'facilities':
      case 'facility':
        return TaskCategory.facilities;
      case 'medication':
      case 'mar':
        return TaskCategory.medication;
      case 'audit':
        return TaskCategory.audit;
      default:
        return TaskCategory.safety;
    }
  }

  static CorrectiveIssueType _issueType(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'safety':
      case 'safety_improvement':
        return CorrectiveIssueType.safetyImprovement;
      case 'handover':
      case 'handover_gap':
        return CorrectiveIssueType.handoverGap;
      default:
        return CorrectiveIssueType.documentationError;
    }
  }

  const TasksComplianceMapper._();
}
