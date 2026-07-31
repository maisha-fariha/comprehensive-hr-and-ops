import 'package:gems_core/gems_core.dart';

import '../../domain/entities/announcement.dart';
import '../../domain/entities/available_report_item.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/messages_tab_overview.dart';
import '../../domain/entities/reports_tab_overview.dart';
import '../../domain/entities/stat_tile_data.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../domain/entities/team_reports_page_data.dart';
import '../../domain/entities/team_tab_overview.dart';
import '../../domain/entities/top_report_item.dart';
import '../../domain/repositories/team_reports_repository.dart';

/// Local implementation of [TeamReportsRepository].
///
/// There is no backend endpoint for this screen yet, so this returns the
/// exact static content shown in the reference design for the Team, Reports
/// and Messages tabs. Replace the body of [getPageData] with a real
/// `ApiService`/`BaseRepository` call (see
/// `flutter_gems/lib/repositories/todo_repository.dart` for the established
/// pattern) once an API contract exists - the domain layer and every widget
/// above it will keep working unchanged.
class TeamReportsRepositoryImpl implements TeamReportsRepository {
  @override
  Future<Result<TeamReportsPageData>> getPageData() async {
    return Result.success(
      const TeamReportsPageData(
        team: TeamTabOverview(
          stats: [
            StatTileData(id: 'total-staff', tag: TeamStatTag.totalStaff, value: '48', label: 'Total Staff'),
            StatTileData(id: 'on-duty-now', tag: TeamStatTag.onDutyNow, value: '16', label: 'On Duty Now'),
            StatTileData(id: 'open-shifts', tag: TeamStatTag.openShifts, value: '3', label: 'Open Shifts'),
            StatTileData(id: 'vacancies', tag: TeamStatTag.vacancies, value: '2', label: 'Vacancies'),
          ],
          topReports: [
            TopReportItem(
              id: 'daily-census',
              tag: ReportTypeTag.dailyCensus,
              title: 'Daily Census',
              dateLabel: 'May 12, 2025',
            ),
            TopReportItem(
              id: 'incident-summary',
              tag: ReportTypeTag.incidentAnalysis,
              title: 'Incident Summary',
              dateLabel: 'May 1 - May 12, 2025',
            ),
            TopReportItem(
              id: 'medication-compliance',
              tag: ReportTypeTag.medicationCompliance,
              title: 'Medication Compliance',
              dateLabel: 'May 1 - May 12, 2025',
            ),
          ],
          recentMessage: ConversationPreview(
            id: 'sarah-j-recent',
            senderName: 'Sarah J.',
            initials: 'SJ',
            timeLabel: '8:24 AM',
            previewText: 'Morning update: All clients stable today...',
            isOnline: true,
          ),
        ),
        reports: ReportsTabOverview(
          stats: [
            StatTileData(id: 'generated', tag: ReportStatTag.generated, value: '24', label: 'Generated'),
            StatTileData(id: 'pending-review', tag: ReportStatTag.pendingReview, value: '5', label: 'Pending Review'),
            StatTileData(id: 'critical', tag: ReportStatTag.critical, value: '3', label: 'Critical'),
            StatTileData(id: 'scheduled', tag: ReportStatTag.scheduled, value: '8', label: 'Scheduled'),
          ],
          availableReports: [
            AvailableReportItem(
              id: 'daily-census-report',
              tag: ReportTypeTag.dailyCensus,
              title: 'Daily Census Report',
              categoryLabel: 'Operations',
              updatedLabel: 'Updated today',
            ),
            AvailableReportItem(
              id: 'incident-analysis',
              tag: ReportTypeTag.incidentAnalysis,
              title: 'Incident Analysis',
              categoryLabel: 'Safety',
              updatedLabel: 'Updated yesterday',
            ),
            AvailableReportItem(
              id: 'medication-compliance-report',
              tag: ReportTypeTag.medicationCompliance,
              title: 'Medication Compliance Report',
              categoryLabel: 'Clinical',
              updatedLabel: 'Updated today',
            ),
            AvailableReportItem(
              id: 'staff-attendance-report',
              tag: ReportTypeTag.staffAttendance,
              title: 'Staff Attendance Report',
              categoryLabel: 'Workforce',
              updatedLabel: 'Updated this week',
            ),
          ],
        ),
        messages: MessagesTabOverview(
          stats: [
            StatTileData(id: 'unread', tag: MessageStatTag.unread, value: '2', label: 'Unread Messages'),
            StatTileData(id: 'urgent', tag: MessageStatTag.urgent, value: '1', label: 'Urgent Messages'),
          ],
          conversations: [
            ConversationPreview(
              id: 'sarah-j',
              senderName: 'Sarah J.',
              initials: 'SJ',
              timeLabel: '8:24 AM',
              previewText: 'Morning shift completed successfully',
              unreadCount: 1,
              isOnline: true,
            ),
            ConversationPreview(
              id: 'mike-t',
              senderName: 'Mike T.',
              initials: 'MT',
              timeLabel: '7:52 AM',
              previewText: 'Need coverage for Friday evening shift',
              unreadCount: 1,
            ),
            ConversationPreview(
              id: 'supervisor-team',
              senderName: 'Supervisor Team',
              initials: 'ST',
              timeLabel: 'Yesterday',
              previewText: 'New compliance update available',
              isGroup: true,
            ),
          ],
          announcements: [
            Announcement(
              id: 'policy-update',
              tag: AnnouncementTag.policy,
              title: 'Policy Update',
              dateLabel: 'May 13, 2025',
              priority: AnnouncementPriority.highPriority,
            ),
            Announcement(
              id: 'training-reminder',
              tag: AnnouncementTag.training,
              title: 'Training Reminder',
              dateLabel: 'May 20, 2025',
              priority: AnnouncementPriority.upcoming,
            ),
          ],
        ),
      ),
    );
  }
}
