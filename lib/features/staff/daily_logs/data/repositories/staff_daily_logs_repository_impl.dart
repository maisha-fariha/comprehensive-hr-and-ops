import 'package:gems_core/gems_core.dart';

import '../../domain/entities/daily_note_field.dart';
import '../../domain/entities/daily_note_overview.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';

/// Local implementation of [StaffDailyLogsRepository].
///
/// There is no backend endpoint for Staff Daily Logs yet, so this returns
/// static content matching the reference screenshots ("My Clients - Daily
/// Logs", "In Progress - Daily Logs", "Submitted - Daily Logs" and "Daily
/// Note"). Replace the body of each method with a real
/// `ApiService`/`BaseRepository` call once an API contract exists - the
/// domain layer and every widget above it will keep working unchanged.
class StaffDailyLogsRepositoryImpl implements StaffDailyLogsRepository {
  @override
  Future<Result<StaffDailyLogsOverview>> getOverview() async {
    return Result.success(
      const StaffDailyLogsOverview(
        stats: [
          StaffDailyLogSummaryStat(
            tag: StaffDailyLogStatTag.submittedToday,
            value: '12',
            label: 'Submitted Today',
          ),
          StaffDailyLogSummaryStat(
            tag: StaffDailyLogStatTag.pendingReview,
            value: '5',
            label: 'Pending Review',
          ),
          StaffDailyLogSummaryStat(
            tag: StaffDailyLogStatTag.flaggedNotes,
            value: '2',
            label: 'Flagged Notes',
          ),
        ],
        myClientsTotalCount: 8,
        myClients: [
          StaffClientLogEntry(
            id: 'james-d',
            initials: 'JD',
            shiftLabel: 'Morning Shift',
            clientName: 'James D.',
            subtitleLabel: '7:00 AM',
            status: ClientLogStatus.pending,
            dobLabel: 'DOB 05/12/1965',
            roomLabel: 'Room 101',
          ),
          StaffClientLogEntry(
            id: 'maria-s',
            initials: 'MS',
            shiftLabel: 'Morning Shift',
            clientName: 'Maria S.',
            subtitleLabel: '7:05 AM',
            status: ClientLogStatus.inProgress,
            dobLabel: 'DOB 09/23/1958',
            roomLabel: 'Room 104',
          ),
          StaffClientLogEntry(
            id: 'robert-h',
            initials: 'RH',
            shiftLabel: 'Morning Shift',
            clientName: 'Robert H.',
            subtitleLabel: '7:10 AM',
            status: ClientLogStatus.pending,
            dobLabel: 'DOB 02/17/1949',
            roomLabel: 'Room 106',
          ),
          StaffClientLogEntry(
            id: 'linda-k',
            initials: 'LK',
            shiftLabel: 'Morning Shift',
            clientName: 'Linda K.',
            subtitleLabel: 'Submitted 7:15 AM',
            status: ClientLogStatus.submitted,
            dobLabel: 'DOB 11/30/1961',
            roomLabel: 'Room 108',
          ),
          StaffClientLogEntry(
            id: 'michael-t',
            initials: 'MT',
            shiftLabel: 'Morning Shift',
            clientName: 'Michael T.',
            subtitleLabel: '7:20 AM',
            status: ClientLogStatus.pending,
            dobLabel: 'DOB 04/08/1972',
            roomLabel: 'Room 110',
          ),
        ],
        inProgressClients: [
          StaffClientLogEntry(
            id: 'maria-s',
            initials: 'MS',
            shiftLabel: 'Morning Shift',
            clientName: 'Maria S.',
            subtitleLabel: 'Updated 8:42 AM',
            status: ClientLogStatus.inProgress,
            dobLabel: 'DOB 09/23/1958',
            roomLabel: 'Room 104',
          ),
          StaffClientLogEntry(
            id: 'david-l',
            initials: 'DL',
            shiftLabel: 'Morning Shift',
            clientName: 'David L.',
            subtitleLabel: 'Updated 9:05 AM',
            status: ClientLogStatus.inProgress,
            dobLabel: 'DOB 06/14/1966',
            roomLabel: 'Room 112',
          ),
        ],
        submittedTotalCount: 5,
        submittedClients: [
          StaffClientLogEntry(
            id: 'linda-k',
            initials: 'LK',
            shiftLabel: 'Morning Shift',
            clientName: 'Linda K.',
            subtitleLabel: 'Submitted 7:15 AM',
            status: ClientLogStatus.submitted,
            dobLabel: 'DOB 11/30/1961',
            roomLabel: 'Room 108',
          ),
          StaffClientLogEntry(
            id: 'patricia-b',
            initials: 'PB',
            shiftLabel: 'Morning Shift',
            clientName: 'Patricia B.',
            subtitleLabel: 'Submitted 7:25 AM',
            status: ClientLogStatus.submitted,
            dobLabel: 'DOB 01/05/1953',
            roomLabel: 'Room 114',
          ),
          StaffClientLogEntry(
            id: 'george-a',
            initials: 'GA',
            shiftLabel: 'Early Shift',
            clientName: 'George A.',
            subtitleLabel: 'Submitted 6:55 AM',
            status: ClientLogStatus.submitted,
            dobLabel: 'DOB 08/19/1957',
            roomLabel: 'Room 116',
          ),
          StaffClientLogEntry(
            id: 'nancy-p',
            initials: 'NP',
            shiftLabel: 'Early Shift',
            clientName: 'Nancy P.',
            subtitleLabel: 'Submitted 6:40 AM',
            status: ClientLogStatus.submitted,
            dobLabel: 'DOB 03/27/1964',
            roomLabel: 'Room 118',
          ),
          StaffClientLogEntry(
            id: 'kevin-r',
            initials: 'KR',
            shiftLabel: 'Early Shift',
            clientName: 'Kevin R.',
            subtitleLabel: 'Submitted 6:15 AM',
            status: ClientLogStatus.submitted,
            dobLabel: 'DOB 12/02/1969',
            roomLabel: 'Room 120',
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<DailyNoteOverview>> getDailyNoteOverview() async {
    return Result.success(
      const DailyNoteOverview(
        fields: [
          DailyNoteField(key: DailyNoteFieldKey.mood, label: 'Mood', value: 'Happy'),
          DailyNoteField(key: DailyNoteFieldKey.meals, label: 'Meals', value: 'Ate well'),
          DailyNoteField(key: DailyNoteFieldKey.sleep, label: 'Sleep', value: 'Slept well'),
          DailyNoteField(key: DailyNoteFieldKey.hygiene, label: 'Hygiene', value: 'Showered'),
          DailyNoteField(key: DailyNoteFieldKey.activities, label: 'Activities', value: 'Group exercise'),
          DailyNoteField(
            key: DailyNoteFieldKey.behavior,
            label: 'Behavior',
            value: 'Cooperative & engaged',
          ),
          DailyNoteField(key: DailyNoteFieldKey.wellness, label: 'Wellness', value: 'No concerns'),
        ],
      ),
    );
  }
}
