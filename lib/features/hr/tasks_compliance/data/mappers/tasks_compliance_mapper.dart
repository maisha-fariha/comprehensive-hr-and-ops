import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/assignee.dart';
import '../../domain/entities/compliance_checklist_item.dart';
import '../../domain/entities/compliance_requirement_item.dart';
import '../../domain/entities/compliance_stat.dart';
import '../../domain/entities/compliance_summary.dart';
import '../../domain/entities/corrective_action.dart';
import '../../domain/entities/corrective_stat.dart';
import '../../domain/entities/expiring_certificate.dart';
import '../../domain/entities/task_analytics.dart';
import '../../domain/entities/task_client_option.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/task_residence_option.dart';
import '../../domain/entities/task_shift_option.dart';
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

    final today = JsonCodec.mapAt(stats, 'today') ?? const <String, dynamic>{};
    final statusMap =
        JsonCodec.mapAt(stats, 'status') ?? const <String, dynamic>{};
    final todayDue = JsonCodec.integerOr(today['due'], 0);
    final todayCompleted = JsonCodec.integerOr(today['completed'], 0);
    final todayPercent = JsonCodec.integer(today['percent']) ??
        JsonCodec.number(today['percent'])?.round();
    final statusPending = JsonCodec.integerOr(
      statusMap['pending'],
      tasks
          .where(
            (item) =>
                item.status != TaskStatus.completed && !item.awaitingReview,
          )
          .length,
    );
    final statusOverdue = JsonCodec.integerOr(
      statusMap['overdue'],
      tasks.where((item) => item.status == TaskStatus.overdue).length,
    );
    final statusCompleted = JsonCodec.integerOr(
      statusMap['completed'],
      tasks
          .where(
            (item) => item.status == TaskStatus.completed && !item.awaitingReview,
          )
          .length,
    );
    final recurringActive = JsonCodec.integerOr(
      stats['recurringActive'],
      recurringItems
          .where((item) => item.status != TaskStatus.completed)
          .length,
    );
    final reviewMeta = JsonCodec.metaOf(reviewBody) ?? const <String, dynamic>{};
    final reviewQueueCount = JsonCodec.integerOr(
      reviewMeta['total'],
      reviewItems.length,
    );
    final recurringMeta =
        JsonCodec.metaOf(recurringBody) ?? const <String, dynamic>{};
    final recurringCount = JsonCodec.integerOr(
      recurringMeta['total'],
      recurringItems.length,
    );
    final byType = _byType(stats);
    final trend = _trendPoints(stats);
    final trendChangePercent = JsonCodec.integer(stats['trendChangePercent']) ??
        JsonCodec.number(stats['trendChangePercent'])?.round();
    final todayValue = todayPercent == null ? '—' : '$todayPercent%';
    final todayBadge = todayDue == 0 && todayCompleted == 0
        ? 'Nothing due'
        : (todayDue > 0 ? '$todayDue due' : null);

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

    // Web Task Management has no “Residence · Today” chrome under the title.
    // Only show a subtitle when the session is actually scoped to a home.
    final scopedName = (residenceName ?? '').trim();
    return TasksComplianceOverview(
      headerSubtitle: scopedName,
      taskStats: [
        TaskStat(
          id: 'today-completion',
          tag: TaskStatTag.todayCompletion,
          value: todayValue,
          label: "Today's Completion",
          badge: todayBadge,
        ),
        TaskStat(
          id: 'pending',
          tag: TaskStatTag.pending,
          value: '$statusPending',
          label: 'Pending Tasks',
          badge: 'Open',
        ),
        TaskStat(
          id: 'overdue',
          tag: TaskStatTag.overdue,
          value: '$statusOverdue',
          label: 'Overdue Tasks',
          badge: 'Overdue',
        ),
        TaskStat(
          id: 'recurring-active',
          tag: TaskStatTag.recurringActive,
          value: '$recurringActive',
          label: 'Recurring Tasks Active',
        ),
      ],
      taskAnalytics: TaskAnalytics(
        statusCompleted: statusCompleted,
        statusPending: statusPending,
        statusOverdue: statusOverdue,
        todayPercent: todayPercent,
        todayDue: todayDue,
        todayCompleted: todayCompleted,
        trendChangePercent: trendChangePercent,
        byType: byType,
        trend: trend,
      ),
      // Web “All Tasks” badge uses status.pending (“0 pending”), not list length.
      tasksDueCount: statusPending,
      reviewQueueCount: reviewQueueCount,
      recurringCount: recurringCount,
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

  static List<String> roomNamesFrom(dynamic body) {
    final map = body is Map ? JsonCodec.asMap(body) : const <String, dynamic>{};
    final data = map['data'];
    final rows = data is Map ? JsonCodec.listAt(JsonCodec.asMap(data), 'rooms') : JsonCodec.unwrapList(body);
    return [
      for (final row in rows.whereType<Map>())
        ?JsonCodec.string(JsonCodec.asMap(row)['name']),
    ];
  }

  static List<TaskShiftOption> shiftOptionsFrom(dynamic body) {
    final now = DateTime.now();
    final options = <TaskShiftOption>[];
    for (final row in JsonCodec.unwrapList(body).whereType<Map>()) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null || JsonCodec.string(json['status']) == 'cancelled') continue;
      final startsAt = JsonCodec.dateTime(json['startsAt']);
      final endsAt = JsonCodec.dateTime(json['endsAt']);
      final active = startsAt != null &&
          endsAt != null &&
          !now.isBefore(startsAt) &&
          !now.isAfter(endsAt);
      final staffNames = rosteredNames(json);
      // Web Create Task / Assign shift menu:
      // "Custom · Thu 12/11/2026 5:00 pm–5:30 pm · Rina …"
      final label = WebFormat.describeShift(
        shiftType: JsonCodec.string(json['shiftType']),
        title: JsonCodec.string(json['title']),
        startsAt: startsAt,
        endsAt: endsAt,
        staffNames: staffNames,
        includeStaff: staffNames.isNotEmpty,
      );
      options.add(
        TaskShiftOption(
          id: id,
          startsAt: startsAt,
          endsAt: endsAt,
          isActive: active,
          label: label,
        ),
      );
    }
    // Web lists newest start first (descending by startsAt).
    options.sort((a, b) {
      final x = a.startsAt, y = b.startsAt;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
    return options;
  }

  /// Names on a shift, leaving out declined assignments and pending bids.
  static List<String> rosteredNames(Map<String, dynamic> shift) => [
        for (final person in JsonCodec.listAt(shift, 'staff').whereType<Map>())
          if (!const {'declined', 'bid_pending'}
              .contains(JsonCodec.string(person['status'])))
            ?JsonCodec.string(person['name']),
      ];

  static List<TaskClientOption> clientsFrom(dynamic body) {
    final options = <TaskClientOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      // Live `/clients` returns firstName/lastName with name null — same as web.
      final name = IsoDateRange.personName(json);
      if (name.isEmpty || name == 'Unknown') continue;

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
    final now = TenantClock.now();
    final dueWall = due == null ? null : TenantClock.wallOf(due);
    final isToday = dueWall != null &&
        dueWall.year == now.year &&
        dueWall.month == now.month &&
        dueWall.day == now.day;
    final statusRaw = (JsonCodec.string(json['status'] ?? json['state']) ?? '')
        .toLowerCase();
    final awaitingReview = _awaitingReview(json, statusRaw);
    final finished = statusRaw == 'completed' ||
        statusRaw == 'done' ||
        statusRaw == 'complete' ||
        statusRaw == 'closed' ||
        statusRaw == 'approved';
    // Web marks open / in-progress tasks Overdue once dueAt is in the past,
    // even when the API still sends status "pending".
    final pastDue = due != null && due.toUtc().isBefore(now.toUtc());
    final status = switch (statusRaw) {
      'overdue' || 'late' => TaskStatus.overdue,
      'upcoming' || 'scheduled' =>
        pastDue ? TaskStatus.overdue : TaskStatus.upcoming,
      'completed' || 'done' || 'complete' || 'closed' || 'approved' =>
        TaskStatus.completed,
      'pending_review' || 'awaiting_review' || 'in_review' || 'review' =>
        TaskStatus.due,
      'due' || 'in_progress' || 'pending' || 'open' => pastDue && !awaitingReview
          ? TaskStatus.overdue
          : isToday
              ? TaskStatus.due
              : TaskStatus.upcoming,
      _ => pastDue && !finished && !awaitingReview
          ? TaskStatus.overdue
          : isToday
              ? TaskStatus.due
              : TaskStatus.upcoming,
    };
    final typeRaw = JsonCodec.stringOr(
      json['taskType'] ?? json['type'] ?? json['category'],
      '',
    );
    final priorityRaw = JsonCodec.stringOr(json['priority'], '');
    final assignees = _assignees(json);
    final residence = JsonCodec.mapAt(json, 'residence');
    final client = JsonCodec.mapAt(json, 'client');
    final room = JsonCodec.string(json['roomArea']);
    final residenceName = [
      JsonCodec.string(residence?['name'] ?? json['residenceName']),
      if (room != null && room.trim().isNotEmpty) room.trim(),
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    final checklist = JsonCodec.unwrapList(json['checklist']);
    var checklistDone = 0;
    for (final raw in checklist) {
      if (raw is! Map) continue;
      final step = JsonCodec.asMap(raw);
      if (step['done'] == true ||
          step['completed'] == true ||
          step['checked'] == true) {
        checklistDone++;
      }
    }
    return TaskItem(
      id: JsonCodec.stringOr(json['id'], 'task'),
      title: JsonCodec.stringOr(json['title'] ?? json['name'], 'Task'),
      category: _category(typeRaw),
      timeLabel: due == null
          ? JsonCodec.stringOr(json['timeLabel'] ?? json['completedAtLabel'], '')
          : WebFormat.dateTime(due),
      isToday: isToday,
      status: status,
      awaitingReview: awaitingReview,
      typeLabel: _humanType(typeRaw),
      priorityLabel: _humanPriority(priorityRaw),
      assigneeName: assignees.name,
      assigneeInitials: assignees.initials,
      extraAssigneeCount: assignees.extra,
      residenceName: residenceName,
      clientName: client == null
          ? JsonCodec.stringOr(json['clientName'], '')
          : IsoDateRange.personName(client),
      checklistDone: checklistDone,
      checklistTotal: checklist.length,
    );
  }

  static ({String name, String initials, int extra}) _assignees(
    Map<String, dynamic> json,
  ) {
    final names = <String>[];
    for (final raw in JsonCodec.unwrapList(json['assignees'])) {
      if (raw is! Map) continue;
      final map = JsonCodec.asMap(raw);
      final staff = JsonCodec.mapAt(map, 'staff') ?? map;
      final name = IsoDateRange.personName(staff);
      if (name.trim().isNotEmpty && name != '—') names.add(name.trim());
    }
    if (names.isEmpty) {
      final fallback = JsonCodec.string(json['assigneeName'] ?? json['staffName']);
      if (fallback != null && fallback.trim().isNotEmpty) {
        names.add(fallback.trim());
      }
    }
    if (names.isEmpty) {
      return (name: '', initials: '', extra: 0);
    }
    return (
      name: names.first,
      initials: IsoDateRange.initials(names.first, fallback: ''),
      extra: names.length - 1,
    );
  }

  static List<TaskTypeBreakdown> _byType(Map<String, dynamic> stats) {
    final out = <TaskTypeBreakdown>[];
    for (final raw in JsonCodec.unwrapList(stats['byType'])) {
      if (raw is! Map) continue;
      final map = JsonCodec.asMap(raw);
      final type = JsonCodec.stringOr(map['type'], 'other');
      final total = JsonCodec.integerOr(map['total'], 0);
      final completed = JsonCodec.integerOr(map['completed'], 0);
      final percent = JsonCodec.integer(map['percent']) ??
          (total <= 0 ? 0 : ((completed / total) * 100).round());
      out.add(
        TaskTypeBreakdown(
          type: type,
          label: _humanType(type),
          total: total,
          completed: completed,
          percent: percent,
        ),
      );
    }
    return out;
  }

  static List<TaskTrendPoint> _trendPoints(Map<String, dynamic> stats) {
    final out = <TaskTrendPoint>[];
    for (final raw in JsonCodec.unwrapList(stats['trend'])) {
      if (raw is! Map) continue;
      final map = JsonCodec.asMap(raw);
      final week = JsonCodec.dateTime(map['weekStart']);
      if (week == null) continue;
      out.add(
        TaskTrendPoint(
          weekStart: week,
          completed: JsonCodec.integerOr(map['completed'], 0),
        ),
      );
    }
    return out;
  }

  static String _humanType(String raw) {
    final text = raw.trim().replaceAll('_', ' ');
    if (text.isEmpty) return '';
    return text
        .split(RegExp(r'\s+'))
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String _humanPriority(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '';
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  /// Web list: a finished task that still needs a reviewer is “Awaiting review”,
  /// not “Completed”. `reviewedAt` empty means nobody has reviewed it yet.
  static bool _awaitingReview(Map<String, dynamic> json, String statusRaw) {
    final reviewed = json['reviewedAt'];
    final notReviewed = reviewed == null ||
        (reviewed is String && reviewed.trim().isEmpty);
    if (!notReviewed) return false;
    if (statusRaw == 'pending_review' ||
        statusRaw == 'awaiting_review' ||
        statusRaw == 'in_review' ||
        statusRaw == 'review') {
      return true;
    }
    final finished = statusRaw == 'completed' ||
        statusRaw == 'done' ||
        statusRaw == 'complete';
    return finished && json['requiresReview'] == true;
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
          : 'Expires ${IsoDateRange.formatShortDate(TenantClock.wallOf(expires))}',
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
      dateLabel: at == null
          ? ''
          : IsoDateRange.formatShortDate(TenantClock.wallOf(at)),
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
          ? 'Resolved ${IsoDateRange.formatShortDate(TenantClock.wallOf(completedAt))}'
          : due == null
              ? JsonCodec.stringOr(json['dueLabel'], '')
              : late
                  ? '${IsoDateRange.formatShortDate(TenantClock.wallOf(due))} · late'
                  : IsoDateRange.formatShortDate(TenantClock.wallOf(due)),
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
      case 'administrative':
      case 'follow_up':
      case 'follow-up':
      case 'other':
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
