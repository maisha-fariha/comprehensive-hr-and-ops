import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/available_report_item.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/messages_tab_overview.dart';
import '../../domain/entities/reports_tab_overview.dart';
import '../../domain/entities/stat_tile_data.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../domain/entities/team_reports_page_data.dart';
import '../../domain/entities/team_tab_overview.dart';
import '../../domain/entities/top_report_item.dart';

abstract final class TeamReportsMapper {
  static TeamReportsPageData compose({
    required dynamic staffBody,
    required dynamic onDutyBody,
    required dynamic openShiftsBody,
    required dynamic summaryBody,
    required dynamic kpisBody,
    required dynamic conversationsBody,
  }) {
    final staff = JsonCodec.unwrapList(staffBody);
    final onDuty = JsonCodec.unwrapList(onDutyBody);
    final openShifts = JsonCodec.unwrapList(openShiftsBody);
    final summary = JsonCodec.unwrapMap(summaryBody);
    final kpis = JsonCodec.unwrapMap(kpisBody);
    final conversations = JsonCodec.unwrapList(conversationsBody)
        .whereType<Map>()
        .map((item) => _conversation(JsonCodec.asMap(item)))
        .toList();
    final unread = conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);
    final reports = _reports(summary, kpis);

    return TeamReportsPageData(
      team: TeamTabOverview(
        stats: [
          StatTileData(
            id: 'total-staff',
            tag: TeamStatTag.totalStaff,
            value: '${staff.length}',
            label: 'Total Staff',
          ),
          StatTileData(
            id: 'on-duty-now',
            tag: TeamStatTag.onDutyNow,
            value: '${onDuty.length}',
            label: 'On Duty Now',
          ),
          StatTileData(
            id: 'open-shifts',
            tag: TeamStatTag.openShifts,
            value: '${openShifts.length}',
            label: 'Open Shifts',
          ),
          StatTileData(
            id: 'vacancies',
            tag: TeamStatTag.vacancies,
            value: JsonCodec.stringOr(kpis['vacancies'] ?? summary['vacancies'], '0'),
            label: 'Vacancies',
          ),
        ],
        topReports: reports.take(3).map(_top).toList(),
        recentMessage: conversations.isEmpty
            ? const ConversationPreview(
                id: 'none',
                senderName: 'No recent messages',
                initials: '--',
                timeLabel: '',
                previewText: 'Team conversations will appear here.',
              )
            : conversations.first,
      ),
      reports: ReportsTabOverview(
        stats: [
          StatTileData(
            id: 'generated',
            tag: ReportStatTag.generated,
            value: JsonCodec.stringOr(
              kpis['generated'] ?? summary['generatedCount'] ?? reports.length,
              '${reports.length}',
            ),
            label: 'Reports',
          ),
          StatTileData(
            id: 'pending-review',
            tag: ReportStatTag.pendingReview,
            value: JsonCodec.stringOr(
              kpis['pendingReview'] ?? summary['pendingReview'],
              '0',
            ),
            label: 'Pending Review',
          ),
          StatTileData(
            id: 'critical',
            tag: ReportStatTag.critical,
            value: JsonCodec.stringOr(kpis['critical'] ?? summary['critical'], '0'),
            label: 'Critical',
          ),
          StatTileData(
            id: 'scheduled',
            tag: ReportStatTag.scheduled,
            value: JsonCodec.stringOr(kpis['scheduled'] ?? summary['scheduled'], '0'),
            label: 'Scheduled',
          ),
        ],
        availableReports: reports,
      ),
      messages: MessagesTabOverview(
        stats: [
          StatTileData(
            id: 'unread',
            tag: MessageStatTag.unread,
            value: '$unread',
            label: 'Unread',
          ),
          StatTileData(
            id: 'urgent',
            tag: MessageStatTag.urgent,
            value: '${conversations.where((item) => item.unreadCount > 2).length}',
            label: 'Urgent',
          ),
        ],
        conversations: conversations,
        announcements: const [],
      ),
    );
  }

  static List<AvailableReportItem> _reports(
    Map<String, dynamic> summary,
    Map<String, dynamic> kpis,
  ) {
    final nested = JsonCodec.listAt(summary, 'reports').isEmpty
        ? JsonCodec.listAt(kpis, 'reports')
        : JsonCodec.listAt(summary, 'reports');
    if (nested.isNotEmpty) {
      return nested.whereType<Map>().map((item) {
        final json = JsonCodec.asMap(item);
        final tag = _reportTag(json['type'] ?? json['metric'] ?? json['id']);
        final at = JsonCodec.dateTime(json['updatedAt'] ?? json['generatedAt']);
        return AvailableReportItem(
          id: JsonCodec.stringOr(json['id'] ?? json['metric'], tag.name),
          tag: tag,
          title: JsonCodec.stringOr(json['title'] ?? json['name'], _reportTitle(tag)),
          categoryLabel: JsonCodec.stringOr(json['category'], 'Operations'),
          updatedLabel: at == null
              ? JsonCodec.stringOr(json['period'], '')
              : 'Updated ${IsoDateRange.formatShortDate(at.toLocal())}',
        );
      }).toList();
    }
    const known = [
      ReportTypeTag.dailyCensus,
      ReportTypeTag.incidentAnalysis,
      ReportTypeTag.medicationCompliance,
      ReportTypeTag.staffAttendance,
    ];
    return [
      for (final tag in known)
        if (_hasMetric(summary, kpis, tag))
          AvailableReportItem(
            id: tag.name,
            tag: tag,
            title: _reportTitle(tag),
            categoryLabel: 'Operations',
            updatedLabel: 'From live KPIs',
          ),
    ];
  }

  static bool _hasMetric(
    Map<String, dynamic> summary,
    Map<String, dynamic> kpis,
    ReportTypeTag tag,
  ) {
    final keys = switch (tag) {
      ReportTypeTag.dailyCensus => ['census', 'occupancy', 'clients'],
      ReportTypeTag.incidentAnalysis => ['incidents', 'incidentCount'],
      ReportTypeTag.medicationCompliance => ['mar', 'medication', 'compliance'],
      ReportTypeTag.staffAttendance => ['attendance', 'onDuty', 'staffOnDuty'],
    };
    for (final key in keys) {
      if (summary.containsKey(key) || kpis.containsKey(key)) return true;
    }
    return false;
  }

  static TopReportItem _top(AvailableReportItem item) {
    return TopReportItem(
      id: item.id,
      tag: item.tag,
      title: item.title,
      dateLabel: item.updatedLabel,
    );
  }

  static ConversationPreview _conversation(Map<String, dynamic> json) {
    final last = JsonCodec.mapAt(json, 'lastMessage') ?? json;
    final name = IsoDateRange.personName(
      json['title'] ??
          json['name'] ??
          json['participantName'] ??
          last['senderName'] ??
          json['subject'],
    );
    final at = JsonCodec.dateTime(
      last['createdAt'] ?? json['updatedAt'] ?? json['lastMessageAt'],
    );
    return ConversationPreview(
      id: JsonCodec.stringOr(json['id'], name),
      senderName: name,
      initials: IsoDateRange.initials(name),
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      previewText: JsonCodec.stringOr(
        last['body'] ?? last['text'] ?? json['preview'] ?? json['lastMessage'],
        '',
      ),
      unreadCount: JsonCodec.integerOr(json['unreadCount'], 0),
      isGroup: JsonCodec.boolean(json['isGroup'] ?? json['group']) ?? false,
    );
  }

  static ReportTypeTag _reportTag(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'incidents':
      case 'incident':
      case 'incidentanalysis':
        return ReportTypeTag.incidentAnalysis;
      case 'mar':
      case 'medication':
      case 'medicationcompliance':
        return ReportTypeTag.medicationCompliance;
      case 'attendance':
      case 'payroll':
      case 'staffattendance':
        return ReportTypeTag.staffAttendance;
      default:
        return ReportTypeTag.dailyCensus;
    }
  }

  static String _reportTitle(ReportTypeTag tag) {
    switch (tag) {
      case ReportTypeTag.dailyCensus:
        return 'Daily Census';
      case ReportTypeTag.incidentAnalysis:
        return 'Incident Summary';
      case ReportTypeTag.medicationCompliance:
        return 'Medication Compliance';
      case ReportTypeTag.staffAttendance:
        return 'Staff Attendance';
    }
  }

  const TeamReportsMapper._();
}
