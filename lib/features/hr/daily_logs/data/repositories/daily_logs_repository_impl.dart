import 'package:gems_core/gems_core.dart';

import '../../domain/entities/client_status_summary.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/daily_logs_overview.dart';
import '../../domain/entities/handover_entry.dart';
import '../../domain/entities/handover_note.dart';
import '../../domain/entities/missing_log_entry.dart';
import '../../domain/entities/submitted_log_entry.dart';
import '../../domain/repositories/daily_logs_repository.dart';

/// Local implementation of [DailyLogsRepository].
///
/// There is no backend endpoint for Daily Logs yet, so this returns static
/// content matching the reference screenshots for the Review/Missing/
/// Handover tabs. Replace the body of [getOverview] with a real
/// `ApiService`/`BaseRepository` call once an API contract exists - the
/// domain layer and every widget above it will keep working unchanged.
class DailyLogsRepositoryImpl implements DailyLogsRepository {
  @override
  Future<Result<DailyLogsOverview>> getOverview() async {
    return Result.success(
      const DailyLogsOverview(
        reviewStats: [
          DailyLogSummaryStat(
            tag: DailyLogStatTag.submittedToday,
            value: '12',
            label: 'Submitted Today',
          ),
          DailyLogSummaryStat(
            tag: DailyLogStatTag.pendingReview,
            value: '5',
            label: 'Pending Review',
          ),
          DailyLogSummaryStat(
            tag: DailyLogStatTag.flaggedNotes,
            value: '2',
            label: 'Flagged Notes',
            isHighlighted: true,
          ),
        ],
        submittedLogsTotalCount: 12,
        submittedLogs: [
          SubmittedLogEntry(
            id: 'sarah-j',
            initials: 'SJ',
            shiftLabel: 'Morning Shift',
            staffName: 'Sarah J.',
            submittedTimeLabel: 'Submitted 7:15 AM',
            status: LogReviewStatus.complete,
          ),
          SubmittedLogEntry(
            id: 'priya-k',
            initials: 'PK',
            shiftLabel: 'Evening Shift',
            staffName: 'Priya K.',
            submittedTimeLabel: 'Submitted 3:20 PM',
            status: LogReviewStatus.complete,
          ),
          SubmittedLogEntry(
            id: 'tyler-m',
            initials: 'TM',
            shiftLabel: 'Night Shift',
            staffName: 'Tyler M.',
            submittedTimeLabel: 'Submitted 11:48 PM',
            status: LogReviewStatus.inReview,
          ),
          SubmittedLogEntry(
            id: 'marcus-c',
            initials: 'MC',
            shiftLabel: 'Morning Shift',
            staffName: 'Marcus C.',
            submittedTimeLabel: 'Submitted 8:02 AM',
            status: LogReviewStatus.flagged,
          ),
        ],
        clientStatusSummaries: [
          ClientStatusSummary(
            id: 'sunrise-home',
            clientName: 'Sunrise Home',
            statusLabel: 'All logs up to date',
          ),
          ClientStatusSummary(
            id: 'maple-court',
            clientName: 'Maple Court',
            statusLabel: '1 log pending review',
            isOnTrack: false,
          ),
          ClientStatusSummary(
            id: 'willow-creek',
            clientName: 'Willow Creek',
            statusLabel: 'All logs up to date',
          ),
        ],
        missingStats: [
          DailyLogSummaryStat(
            tag: DailyLogStatTag.missingLogs,
            value: '4',
            label: 'Missing Logs',
          ),
          DailyLogSummaryStat(
            tag: DailyLogStatTag.overdue,
            value: '2',
            label: 'Overdue',
          ),
          DailyLogSummaryStat(
            tag: DailyLogStatTag.followUpRequired,
            value: '3',
            label: 'Follow Up Required',
          ),
        ],
        missingLogs: [
          MissingLogEntry(
            id: 'james-d',
            staffName: 'James D.',
            initials: 'JD',
            locationLabel: 'Sunrise Home',
            overdueLabel: '2h overdue',
            expectedShiftLabel: 'Morning Shift',
            assignedStaffName: 'Sarah J.',
            assignedStaffInitials: 'SJ',
          ),
          MissingLogEntry(
            id: 'maria-s',
            staffName: 'Maria S.',
            initials: 'MS',
            locationLabel: 'Maple Court',
            overdueLabel: '1h 20m overdue',
            expectedShiftLabel: 'Evening Shift',
            assignedStaffName: 'Diego L.',
            assignedStaffInitials: 'DL',
          ),
          MissingLogEntry(
            id: 'robert-h',
            staffName: 'Robert H.',
            initials: 'RH',
            locationLabel: 'Sunrise Home',
            overdueLabel: '35m late',
            expectedShiftLabel: 'Night Shift',
            assignedStaffName: 'Emma K.',
            assignedStaffInitials: 'EK',
          ),
          MissingLogEntry(
            id: 'chris-b',
            staffName: 'Chris B.',
            initials: 'CB',
            locationLabel: 'Willow Creek',
            overdueLabel: '10m late',
            expectedShiftLabel: 'Morning Shift',
            assignedStaffName: 'Priya K.',
            assignedStaffInitials: 'PK',
          ),
        ],
        handoverStats: [
          DailyLogSummaryStat(
            tag: DailyLogStatTag.activeHandovers,
            value: '3',
            label: 'Active Handovers',
          ),
          DailyLogSummaryStat(
            tag: DailyLogStatTag.pendingAcknowledgement,
            value: '2',
            label: 'Pending Acknowledgement',
          ),
          DailyLogSummaryStat(
            tag: DailyLogStatTag.urgentNotes,
            value: '1',
            label: 'Urgent Notes',
          ),
        ],
        handoverEntries: [
          HandoverEntry(
            id: 'morning-evening',
            fromShiftLabel: 'Morning',
            toShiftLabel: 'Evening',
            isUrgent: true,
            fromStaffName: 'Sarah J.',
            fromStaffInitials: 'SJ',
            toStaffName: 'Marcus C.',
            toStaffInitials: 'MC',
            notes: [
              HandoverNote(
                type: HandoverNoteType.medication,
                title: 'Medication follow-up',
                description: 'James D. missed 2 PM dose, administer with dinner and confirm.',
              ),
              HandoverNote(
                type: HandoverNoteType.observation,
                title: 'Client observation',
                description: 'Maria S. reported mild dizziness, monitor mobility.',
              ),
              HandoverNote(
                type: HandoverNoteType.task,
                title: 'Pending tasks',
                description: 'Restock incontinence supplies in Room 3.',
              ),
            ],
            acknowledgementCaption: 'Awaiting acknowledgement',
          ),
          HandoverEntry(
            id: 'night-morning',
            fromShiftLabel: 'Night',
            toShiftLabel: 'Morning',
            tagLabel: '\$ Routine',
          ),
        ],
      ),
    );
  }
}
