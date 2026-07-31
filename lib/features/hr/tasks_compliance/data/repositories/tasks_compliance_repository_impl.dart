import 'package:gems_core/gems_core.dart';

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
import '../../domain/repositories/tasks_compliance_repository.dart';

/// Local implementation of [TasksComplianceRepository].
///
/// There is no backend endpoint for this screen yet, so this returns the
/// exact static content shown in the Figma design (as re-verified from the
/// user-supplied reference screenshot, since Figma MCP access was
/// unavailable for this feature - see the "Corrective" list's third card,
/// whose assignee/due-date/status were not visible in that screenshot and
/// are therefore plausible placeholders rather than confirmed values).
/// Replace the body of [getOverview] with a real `ApiService`/
/// `BaseRepository` call once an API contract exists - the domain layer and
/// every widget above it will keep working unchanged.
class TasksComplianceRepositoryImpl implements TasksComplianceRepository {
  @override
  Future<Result<TasksComplianceOverview>> getOverview() async {
    return Result.success(
      const TasksComplianceOverview(
        headerSubtitle: '4 residences · Today',
        taskStats: [
          TaskStat(id: 'due-today', tag: TaskStatTag.dueToday, value: '8', label: 'Due Today'),
          TaskStat(id: 'this-week', tag: TaskStatTag.thisWeek, value: '5', label: 'This Week'),
          TaskStat(id: 'upcoming', tag: TaskStatTag.upcoming, value: '12', label: 'Upcoming'),
          TaskStat(id: 'completed', tag: TaskStatTag.completed, value: '25', label: 'Completed'),
        ],
        tasksDueCount: 8,
        taskItems: [
          TaskItem(
            id: 'fire-drill',
            title: 'Fire Drill',
            category: TaskCategory.safety,
            timeLabel: 'Today, 10:00 AM',
            isToday: true,
            status: TaskStatus.overdue,
          ),
          TaskItem(
            id: 'kitchen-inspection',
            title: 'Kitchen Inspection',
            category: TaskCategory.facilities,
            timeLabel: 'Today, 2:00 PM',
            isToday: true,
            status: TaskStatus.due,
          ),
          TaskItem(
            id: 'medication-cart-check',
            title: 'Medication Cart Check',
            category: TaskCategory.medication,
            timeLabel: 'Today, 4:00 PM',
            isToday: true,
            status: TaskStatus.due,
          ),
          TaskItem(
            id: 'monthly-safety-audit',
            title: 'Monthly Safety Audit',
            category: TaskCategory.audit,
            timeLabel: 'May 15, 9:00 AM',
            isToday: false,
            status: TaskStatus.upcoming,
          ),
        ],
        complianceSummary: ComplianceSummary(
          percent: 94,
          description: '42 of 49 checks passing across all residences this period.',
          trendLabel: '+3% vs last month',
        ),
        complianceStats: [
          ComplianceStat(id: 'completed', tag: ComplianceStatTag.completed, value: '42', label: 'Completed'),
          ComplianceStat(
            id: 'pending-review',
            tag: ComplianceStatTag.pendingReview,
            value: '5',
            label: 'Pending Review',
          ),
          ComplianceStat(
            id: 'needs-attention',
            tag: ComplianceStatTag.needsAttention,
            value: '2',
            label: 'Needs Attention',
          ),
        ],
        complianceChecklistCount: 4,
        complianceChecklistItems: [
          ComplianceChecklistItem(
            id: 'medication-documentation-review',
            title: 'Medication Documentation Review',
            category: 'Medication',
            assignee: Assignee(initials: 'SJ', name: 'Sarah J.', colorTag: AssigneeColorTag.blue),
            dateLabel: 'May 12',
            status: ComplianceItemStatus.completed,
          ),
          ComplianceChecklistItem(
            id: 'safety-inspection',
            title: 'Safety Inspection',
            category: 'Facilities',
            assignee: Assignee(initials: 'MT', name: 'Mike T.', colorTag: AssigneeColorTag.purple),
            dateLabel: 'May 14',
            status: ComplianceItemStatus.pending,
          ),
          ComplianceChecklistItem(
            id: 'staff-training-verification',
            title: 'Staff Training Verification',
            category: 'HR',
            assignee: Assignee(initials: 'AN', name: 'Aisha N.', colorTag: AssigneeColorTag.green),
            dateLabel: 'May 15',
            status: ComplianceItemStatus.dueSoon,
          ),
        ],
        correctiveStats: [
          CorrectiveStat(id: 'open', tag: CorrectiveStatTag.open, value: '4', label: 'Open Actions'),
          CorrectiveStat(id: 'in-progress', tag: CorrectiveStatTag.inProgress, value: '3', label: 'In Progress'),
          CorrectiveStat(id: 'completed', tag: CorrectiveStatTag.completed, value: '18', label: 'Completed'),
          CorrectiveStat(id: 'overdue', tag: CorrectiveStatTag.overdue, value: '1', label: 'Overdue'),
        ],
        correctiveActionsCount: 4,
        correctiveActions: [
          CorrectiveAction(
            id: 'medication-documentation-error',
            issueType: CorrectiveIssueType.documentationError,
            title: 'Medication Documentation Error',
            severity: CorrectiveSeverity.high,
            locationCategory: 'Medication',
            locationName: 'Sunrise Home',
            assignee: Assignee(initials: 'SJ', name: 'Sarah J.', colorTag: AssigneeColorTag.blue),
            dueDateLabel: 'May 11 · 2d late',
            isDueLate: true,
            status: CorrectiveActionStatus.overdue,
          ),
          CorrectiveAction(
            id: 'fall-prevention-improvement',
            issueType: CorrectiveIssueType.safetyImprovement,
            title: 'Fall Prevention Improvement',
            severity: CorrectiveSeverity.medium,
            locationCategory: 'Safety',
            locationName: 'Maple Court',
            assignee: Assignee(initials: 'MT', name: 'Mike T.', colorTag: AssigneeColorTag.purple),
            dueDateLabel: 'May 20',
            isDueLate: false,
            status: CorrectiveActionStatus.inProgress,
          ),
          // NOTE: the reference screenshot cropped this card before its
          // assignee/due-date/footer status became visible - those 3 fields
          // are a plausible placeholder consistent with the other cards
          // rather than a confirmed Figma value. Revisit once real Figma
          // access is restored.
          CorrectiveAction(
            id: 'staff-handover-log-gaps',
            issueType: CorrectiveIssueType.handoverGap,
            title: 'Staff Handover Log Gaps',
            severity: CorrectiveSeverity.medium,
            locationCategory: 'Operations',
            locationName: 'Cedar Grove',
            assignee: Assignee(initials: 'AN', name: 'Aisha N.', colorTag: AssigneeColorTag.green),
            dueDateLabel: 'May 22',
            isDueLate: false,
            status: CorrectiveActionStatus.inProgress,
          ),
        ],
      ),
    );
  }
}
