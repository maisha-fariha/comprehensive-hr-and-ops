import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/assignee.dart';
import '../../domain/entities/compliance_checklist_item.dart';
import '../../domain/entities/compliance_requirement_item.dart';
import '../../domain/entities/compliance_stat.dart';
import '../../domain/entities/compliance_summary.dart';
import '../../domain/entities/corrective_action.dart';
import '../../domain/entities/corrective_stat.dart';
import '../../domain/entities/expiring_certificate.dart';
import '../../domain/entities/task_client_option.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/task_residence_option.dart';
import '../../domain/entities/task_staff_option.dart';
import '../../domain/entities/task_stat.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import '../../domain/entities/tasks_compliance_overview.dart';

abstract final class TasksComplianceMapper {
  static TasksComplianceOverview compose({
    required dynamic statsBody,
    required dynamic tasksBody,
    dynamic reviewBody,
    dynamic recurringBody,
    dynamic certificatesBody,
    required dynamic scoreBody,
    required dynamic overviewBody,
    required dynamic checksBody,
    dynamic requirementsBody,
    dynamic alertsBody,
    dynamic activeActionsBody,
    dynamic overdueActionsBody,
    dynamic completedActionsBody,
    required String? residenceName,
  }) {
    final stats = JsonCodec.unwrapMap(statsBody);
    final tasks = tasksFrom(tasksBody);
    final reviewItems = tasksFrom(reviewBody);
    final recurringItems = recurringFrom(recurringBody);
    final certificates = certificatesFrom(certificatesBody);
    final scoreJson = JsonCodec.unwrapMap(scoreBody);
    final overview = JsonCodec.unwrapMap(overviewBody);
    final checks = checksFrom(checksBody);
    final requirements = requirementsFrom(requirementsBody);
    final alertCount = _alertCount(alertsBody);
    final activeActions = actionsFrom(activeActionsBody);
    final overdueActions = actionsFrom(overdueActionsBody, forceOverdue: true);
    final completedActions = actionsFrom(
      completedActionsBody,
      forceCompleted: true,
    );

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
      tasks.where((item) => item.status == TaskStatus.completed).length,
    );

    final percent = JsonCodec.integer(
          scoreJson['percent'] ??
              scoreJson['score'] ??
              overview['percent'] ??
              overview['score'],
        ) ??
        0;
    final breakdown = JsonCodec.mapAt(scoreJson, 'breakdown') ??
        JsonCodec.mapAt(overview, 'breakdown') ??
        const <String, dynamic>{};
    final checksMeta = JsonCodec.metaOf(checksBody) ?? const <String, dynamic>{};
    final checksSummary = JsonCodec.mapAt(checksMeta, 'summary') ??
        const <String, dynamic>{};

    final completedFallback = (JsonCodec.integerOr(
              checksSummary['checks'],
              checks
                  .where((item) => item.status == ComplianceItemStatus.completed)
                  .length,
            ) -
            JsonCodec.integerOr(checksSummary['outstanding'], 0))
        .clamp(0, 999999)
        .toInt();

    final complianceCompletedCount = JsonCodec.integerOr(
      overview['completed'] ??
          overview['complete'] ??
          overview['completedCount'] ??
          overview['passing'],
      completedFallback,
    );

    final pendingReviewCount = JsonCodec.integerOr(
      overview['pendingReview'] ??
          overview['pending'] ??
          overview['awaitingReview'] ??
          overview['pendingReviewCount'],
      JsonCodec.integerOr(
        checksSummary['awaitingReview'],
        checks.where((item) => item.status == ComplianceItemStatus.pending).length,
      ),
    );

    final needsAttentionCount = JsonCodec.integerOr(
      overview['needsAttention'] ??
          overview['attention'] ??
          overview['needsAttentionCount'],
      JsonCodec.integerOr(
        checksSummary['overdue'] ?? checksSummary['failing'],
        _breakdownIssueCount(breakdown),
      ),
    );

    final openCount = activeActions
        .where((item) => item.status == CorrectiveActionStatus.open)
        .length;
    final inProgressCount = activeActions
        .where((item) => item.status == CorrectiveActionStatus.inProgress)
        .length;
    final overdueCount = JsonCodec.integerOr(
      JsonCodec.metaOf(overdueActionsBody)?['total'],
      overdueActions.length,
    );
    final correctiveCompletedCount = JsonCodec.integerOr(
      JsonCodec.metaOf(completedActionsBody)?['total'],
      completedActions.length,
    );

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
      tasksDueCount: dueToday > 0 ? dueToday : tasks.length,
      taskItems: tasks,
      reviewQueueItems: reviewItems,
      recurringItems: recurringItems,
      expiringCertificates: certificates,
      complianceSummary: ComplianceSummary(
        percent: percent,
        description: _scoreDescription(
          percent: percent,
          breakdown: breakdown,
          overview: overview,
        ),
        trendLabel: _trendLabel(overview: overview, score: scoreJson),
      ),
      complianceStats: [
        ComplianceStat(
          id: 'completed',
          tag: ComplianceStatTag.completed,
          value: '$complianceCompletedCount',
          label: 'Completed',
        ),
        ComplianceStat(
          id: 'pending-review',
          tag: ComplianceStatTag.pendingReview,
          value: '$pendingReviewCount',
          label: 'Pending Review',
        ),
        ComplianceStat(
          id: 'needs-attention',
          tag: ComplianceStatTag.needsAttention,
          value: '$needsAttentionCount',
          label: 'Needs Attention',
        ),
      ],
      complianceChecklistCount: JsonCodec.integerOr(
        checksMeta['total'] ?? checksSummary['outstanding'] ?? checksSummary['checks'],
        checks.length,
      ),
      complianceChecklistItems: checks,
      upcomingReviewsCount: JsonCodec.integerOr(
        JsonCodec.metaOf(requirementsBody)?['total'],
        requirements.length,
      ),
      upcomingReviews: requirements,
      complianceAlertCount: alertCount,
      correctiveStats: [
        CorrectiveStat(
          id: 'open',
          tag: CorrectiveStatTag.open,
          value: '$openCount',
          label: 'Open',
        ),
        CorrectiveStat(
          id: 'in-progress',
          tag: CorrectiveStatTag.inProgress,
          value: '$inProgressCount',
          label: 'In Progress',
        ),
        CorrectiveStat(
          id: 'completed',
          tag: CorrectiveStatTag.completed,
          value: '$correctiveCompletedCount',
          label: 'Completed',
        ),
        CorrectiveStat(
          id: 'overdue',
          tag: CorrectiveStatTag.overdue,
          value: '$overdueCount',
          label: 'Overdue',
        ),
      ],
      correctiveActionsCount: JsonCodec.integerOr(
        JsonCodec.metaOf(activeActionsBody)?['total'],
        activeActions.length,
      ),
      correctiveActions: activeActions,
      correctiveOverdueCount: overdueCount,
      recentResolutionsCount: correctiveCompletedCount,
      recentResolutions: completedActions,
    );
  }

  static List<CorrectiveAction> actionsFrom(
    dynamic body, {
    bool forceOverdue = false,
    bool forceCompleted = false,
  }) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(
          (item) => _action(
            JsonCodec.asMap(item),
            forceOverdue: forceOverdue,
            forceCompleted: forceCompleted,
          ),
        )
        .toList();
  }

  static List<ComplianceChecklistItem> checksFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => _check(JsonCodec.asMap(item)))
        .toList();
  }

  static List<ComplianceRequirementItem> requirementsFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => _requirement(JsonCodec.asMap(item)))
        .toList();
  }

  static int _alertCount(dynamic body) {
    if (body == null) return 0;
    final list = JsonCodec.unwrapList(body);
    if (list.isNotEmpty) return list.length;
    final map = JsonCodec.unwrapMap(body);
    return JsonCodec.integerOr(
      map['count'] ?? map['total'] ?? map['alertCount'],
      0,
    );
  }

  static int _breakdownIssueCount(Map<String, dynamic> breakdown) {
    var total = 0;
    for (final value in breakdown.values) {
      final n = JsonCodec.integer(value);
      if (n != null && n > 0) total += n;
    }
    return total;
  }

  static String _scoreDescription({
    required int percent,
    required Map<String, dynamic> breakdown,
    required Map<String, dynamic> overview,
  }) {
    final explicit = JsonCodec.string(
      overview['description'] ??
          overview['summary'] ??
          breakdown['description'],
    );
    if (explicit != null && explicit.trim().isNotEmpty) return explicit.trim();

    final issues = _breakdownIssueCount(breakdown);
    if (issues > 0) {
      return '$issues open gap${issues == 1 ? '' : 's'} in the weighted score.';
    }
    if (percent >= 100) {
      return 'All weighted compliance checks are currently passing.';
    }
    return 'Live compliance score from the care home.';
  }

  static String _trendLabel({
    required Map<String, dynamic> overview,
    required Map<String, dynamic> score,
  }) {
    final explicit = JsonCodec.string(
      overview['trendLabel'] ?? score['trendLabel'],
    );
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    final scoreTrend = score['trend'];
    if (scoreTrend is String && scoreTrend.trim().isNotEmpty) {
      return scoreTrend.trim();
    }

    final trend = JsonCodec.unwrapList(overview['trend']);
    if (trend.length >= 2) {
      final prev = JsonCodec.asMap(trend[trend.length - 2]);
      final last = JsonCodec.asMap(trend[trend.length - 1]);
      final prevOpened = JsonCodec.integerOr(prev['opened'], 0);
      final lastOpened = JsonCodec.integerOr(last['opened'], 0);
      final delta = prevOpened - lastOpened;
      if (delta > 0) return '+$delta vs last week';
      if (delta < 0) return '$delta vs last week';
    }
    return '';
  }

  static List<TaskItem> tasksFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => _task(JsonCodec.asMap(item)))
        .toList();
  }

  static List<TaskItem> recurringFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => _recurring(JsonCodec.asMap(item)))
        .toList();
  }

  static List<ExpiringCertificate> certificatesFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => _certificate(JsonCodec.asMap(item)))
        .toList();
  }

  static List<TaskResidenceOption> residencesFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((row) {
          final map = JsonCodec.asMap(row);
          final id = JsonCodec.string(map['id'] ?? map['residenceId'])?.trim();
          if (id == null || id.isEmpty) return null;
          return TaskResidenceOption(
            id: id,
            name: JsonCodec.stringOr(map['name'] ?? map['residenceName'], id),
          );
        })
        .whereType<TaskResidenceOption>()
        .toList();
  }

  static List<TaskClientOption> clientsFrom(dynamic body) {
    final options = <TaskClientOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      final name = JsonCodec.string(
            json['preferredName'] ??
                json['fullName'] ??
                json['name'] ??
                json['displayName'] ??
                json['clientName'] ??
                json['residentName'],
          ) ??
          '';
      if (name.isEmpty) continue;

      final room = JsonCodec.string(
        json['room'] ?? json['roomNumber'] ?? json['location'],
      );
      final residenceName = JsonCodec.string(
        json['residenceName'] ?? residence['name'],
      );
      final subtitle = [
        if (room != null && room.isNotEmpty) room,
        if (residenceName != null && residenceName.isNotEmpty) residenceName,
      ].join(' · ');

      options.add(
        TaskClientOption(
          id: JsonCodec.stringOr(json['id'] ?? json['clientId'], name),
          name: name,
          residenceId: JsonCodec.string(
            json['residenceId'] ?? residence['id'],
          ),
          subtitle: subtitle.isEmpty ? null : subtitle,
        ),
      );
    }
    return options;
  }

  static List<TaskStaffOption> staffFrom(dynamic body) {
    final options = <TaskStaffOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final user = JsonCodec.mapAt(json, 'user') ??
          JsonCodec.mapAt(json, 'profile') ??
          json;
      final category = JsonCodec.mapAt(json, 'category') ??
          JsonCodec.mapAt(json, 'staffCategory') ??
          JsonCodec.mapAt(user, 'category') ??
          const {};
      final name = JsonCodec.string(
            user['preferredName'] ??
                user['fullName'] ??
                user['displayName'] ??
                user['name'] ??
                [
                  user['firstName'] ?? json['firstName'],
                  user['lastName'] ?? json['lastName'],
                ]
                    .where((p) => p != null && p.toString().trim().isNotEmpty)
                    .join(' '),
          ) ??
          '';
      if (name.isEmpty) continue;

      final role = JsonCodec.string(
        category['name'] ??
            json['categoryName'] ??
            json['role'] ??
            json['jobTitle'] ??
            json['title'] ??
            user['role'],
      );

      options.add(
        TaskStaffOption(
          id: JsonCodec.stringOr(
            json['id'] ?? json['staffId'] ?? user['id'],
            name,
          ),
          name: name,
          subtitle: role,
        ),
      );
    }
    return options;
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
      'completed' || 'done' || 'complete' || 'closed' || 'approved' =>
        TaskStatus.completed,
      'pending_review' || 'awaiting_review' || 'review' => TaskStatus.due,
      'due' || 'in_progress' || 'pending' || 'open' =>
        isToday ? TaskStatus.due : TaskStatus.upcoming,
      _ => isToday ? TaskStatus.due : TaskStatus.upcoming,
    };
    return TaskItem(
      id: JsonCodec.stringOr(json['id'], 'task'),
      title: JsonCodec.stringOr(json['title'] ?? json['name'], 'Task'),
      category: _category(
        json['category'] ?? json['taskType'] ?? json['type'],
      ),
      timeLabel: due == null
          ? JsonCodec.stringOr(json['timeLabel'] ?? json['completedAtLabel'], '')
          : isToday
              ? 'Today, ${IsoDateRange.timeLabel(due.toLocal())}'
              : IsoDateRange.formatShortDate(due.toLocal()),
      isToday: isToday,
      status: status,
    );
  }

  static TaskItem _recurring(Map<String, dynamic> json) {
    final active = JsonCodec.boolean(json['isActive'] ?? json['active']) ?? true;
    final frequency = JsonCodec.stringOr(
      json['frequency'] ?? json['scheduleLabel'] ?? json['rrule'],
      'Recurring',
    );
    final interval = JsonCodec.integer(json['intervalMinutes']);
    final schedule = interval != null && frequency.toLowerCase() == 'interval'
        ? 'Every $interval min'
        : frequency;
    return TaskItem(
      id: JsonCodec.stringOr(json['id'] ?? json['recurrenceId'], 'recurring'),
      title: JsonCodec.stringOr(json['title'] ?? json['name'], 'Recurring task'),
      category: _category(json['category'] ?? json['taskType'] ?? json['type']),
      timeLabel: schedule,
      isToday: false,
      status: active ? TaskStatus.upcoming : TaskStatus.completed,
    );
  }

  static ExpiringCertificate _certificate(Map<String, dynamic> json) {
    final staff = json['staff'] ?? json['assignee'] ?? json['user'];
    final expires = JsonCodec.dateTime(
      json['expiresAt'] ?? json['expiryDate'] ?? json['validUntil'],
    );
    return ExpiringCertificate(
      id: JsonCodec.stringOr(json['id'] ?? json['certificateId'], 'cert'),
      staffName: staff == null
          ? JsonCodec.stringOr(json['staffName'] ?? json['holderName'], 'Staff')
          : IsoDateRange.personName(staff),
      title: JsonCodec.stringOr(
        json['title'] ??
            json['name'] ??
            json['courseName'] ??
            json['certificateType'],
        'Certificate',
      ),
      expiryLabel: expires == null
          ? JsonCodec.stringOr(json['expiryLabel'], 'Expiring soon')
          : 'Expires ${IsoDateRange.formatShortDate(expires.toLocal())}',
    );
  }

  static ComplianceChecklistItem _check(Map<String, dynamic> json) {
    final assignee = _assignee(
      json['assignedStaffName'] ??
          json['assignee'] ??
          json['owner'] ??
          json['assignedTo'] ??
          json['reviewedByName'],
    );
    final at = JsonCodec.dateTime(
      json['dueAt'] ?? json['checkedAt'] ?? json['completedAt'] ?? json['date'],
    );
    final resultRaw = (JsonCodec.string(
              json['result'] ?? json['status'] ?? json['state'],
            ) ??
            '')
        .toLowerCase();
    final status = switch (resultRaw) {
      'pass' ||
      'passed' ||
      'compliant' ||
      'completed' ||
      'complete' =>
        ComplianceItemStatus.completed,
      'needs_review' ||
      'partially_compliant' ||
      'partial' ||
      'pending' =>
        ComplianceItemStatus.pending,
      'fail' ||
      'failed' ||
      'non_compliant' ||
      'overdue' ||
      'due_soon' ||
      'duesoon' ||
      'warning' =>
        ComplianceItemStatus.dueSoon,
      _ => ComplianceItemStatus.pending,
    };
    final frequency = JsonCodec.string(json['frequency']);
    return ComplianceChecklistItem(
      id: JsonCodec.stringOr(json['id'], 'check'),
      title: JsonCodec.stringOr(
        json['requirementName'] ??
            json['title'] ??
            json['name'] ??
            json['requirement'],
        'Check',
      ),
      category: JsonCodec.stringOr(
        json['category'] ??
            json['standard'] ??
            json['area'] ??
            (frequency == null ? null : _titleCase(frequency)),
        'Compliance',
      ),
      assignee: assignee,
      dateLabel: at == null ? '' : IsoDateRange.formatShortDate(at.toLocal()),
      status: status,
    );
  }

  static ComplianceRequirementItem _requirement(Map<String, dynamic> json) {
    final supervisor = _assignee(
      json['reviewerName'] ??
          json['responsibleName'] ??
          json['supervisorName'] ??
          json['supervisor'] ??
          json['reviewer'] ??
          json['responsible'],
    );
    final frequency = JsonCodec.string(json['frequency'] ?? json['frequencyNote']);
    return ComplianceRequirementItem(
      id: JsonCodec.stringOr(json['id'], 'requirement'),
      title: JsonCodec.stringOr(json['name'] ?? json['title'], 'Requirement'),
      frequencyLabel: frequency == null || frequency.isEmpty
          ? 'Scheduled'
          : _titleCase(frequency),
      category: JsonCodec.stringOr(
        json['category'] ?? json['standard'] ?? json['priority'],
        'Compliance',
      ),
      supervisor: supervisor,
    );
  }

  static String _titleCase(String value) {
    final trimmed = value.trim().replaceAll('_', ' ');
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static CorrectiveAction _action(
    Map<String, dynamic> json, {
    bool forceOverdue = false,
    bool forceCompleted = false,
  }) {
    final due = JsonCodec.dateTime(json['dueAt'] ?? json['deadline']);
    final completedAt = JsonCodec.dateTime(json['completedAt']);
    final late = due != null &&
        due.isBefore(DateTime.now()) &&
        completedAt == null;
    final statusRaw = (JsonCodec.string(json['status'] ?? json['state']) ?? '')
        .toLowerCase();
    final status = forceCompleted
        ? CorrectiveActionStatus.completed
        : forceOverdue || statusRaw.contains('overdue') || late
            ? CorrectiveActionStatus.overdue
            : switch (statusRaw) {
                'completed' || 'done' || 'closed' || 'resolved' =>
                  CorrectiveActionStatus.completed,
                'open' || 'new' => CorrectiveActionStatus.open,
                'in_progress' || 'in-progress' || 'progress' =>
                  CorrectiveActionStatus.inProgress,
                _ => CorrectiveActionStatus.inProgress,
              };

    return CorrectiveAction(
      id: JsonCodec.stringOr(json['id'], 'action'),
      issueType: _issueType(json['issueType'] ?? json['type'] ?? json['category']),
      title: JsonCodec.stringOr(
        json['description'] ?? json['title'] ?? json['name'],
        'Corrective action',
      ),
      severity: (JsonCodec.string(json['severity'] ?? json['priority']) ?? '')
                  .toLowerCase()
                  .contains('high')
          ? CorrectiveSeverity.high
          : CorrectiveSeverity.medium,
      locationCategory: JsonCodec.stringOr(
        json['area'] ?? json['category'] ?? json['sourceType'],
        'Residence',
      ),
      locationName: JsonCodec.stringOr(
        json['location'] ??
            json['residenceName'] ??
            JsonCodec.mapAt(json, 'residence')?['name'],
        '',
      ),
      assignee: _assignee(
        json['assignee'] ??
            json['ownerName'] ??
            json['owner'] ??
            json['assignedTo'] ??
            json['createdByName'],
      ),
      dueDateLabel: status == CorrectiveActionStatus.completed && completedAt != null
          ? 'Resolved ${IsoDateRange.formatShortDate(completedAt.toLocal())}'
          : due == null
              ? JsonCodec.stringOr(json['dueLabel'], '')
              : late
                  ? '${IsoDateRange.formatShortDate(due.toLocal())} · late'
                  : IsoDateRange.formatShortDate(due.toLocal()),
      isDueLate: late || status == CorrectiveActionStatus.overdue,
      status: status,
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
      case 'maintenance':
      case 'housekeeping':
        return TaskCategory.facilities;
      case 'medication':
      case 'mar':
      case 'care':
        return TaskCategory.medication;
      case 'audit':
      case 'admin':
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
