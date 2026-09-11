import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/available_report_item.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/messages_tab_overview.dart';
import '../../domain/entities/report_analytics_item.dart';
import '../../domain/entities/report_document_item.dart';
import '../../domain/entities/report_export_item.dart';
import '../../domain/entities/report_insight.dart';
import '../../domain/entities/reports_tab_overview.dart';
import '../../domain/entities/stat_tile_data.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../domain/entities/team_reports_page_data.dart';
import '../../domain/entities/team_staff_member.dart';
import '../../domain/entities/team_staff_profile.dart';
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
    dynamic analyticsBody,
    dynamic exportsBody,
    dynamic documentsBody,
    dynamic documentsSummaryBody,
    dynamic documentTypesBody,
    dynamic notificationsBody,
    Map<String, dynamic> seriesBodies = const {},
  }) {
    final staffMembers = staffMembersFrom(staffBody);
    final staffTotal = JsonCodec.integerOr(
      JsonCodec.metaOf(staffBody)?['total'],
      staffMembers.length,
    );
    final onDuty = JsonCodec.unwrapList(onDutyBody);
    final onDutyTotal = JsonCodec.integerOr(
      JsonCodec.metaOf(onDutyBody)?['total'],
      onDuty.length,
    );
    final openShifts = JsonCodec.unwrapList(openShiftsBody);
    final openShiftsMeta = JsonCodec.metaOf(openShiftsBody) ?? const {};
    final openShiftsTotal = JsonCodec.integerOr(
      openShiftsMeta['total'],
      openShifts.length,
    );
    final vacanciesTotal = JsonCodec.integerOr(
      openShiftsMeta['vacancies'] ?? openShiftsMeta['unfilled'],
      _vacancyCount(openShifts),
    );
    final summary = JsonCodec.unwrapMap(summaryBody);
    final kpis = JsonCodec.unwrapMap(kpisBody);
    final conversations = JsonCodec.unwrapList(conversationsBody)
        .whereType<Map>()
        .map((item) => _conversation(JsonCodec.asMap(item)))
        .toList();
    final unread =
        conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);
    final reports = _reports(summary, kpis);
    final insights = insightsFrom(seriesBodies);
    final analytics = analyticsFrom(analyticsBody);
    final exports = exportsFrom(exportsBody);
    final documents = documentsFrom(documentsBody);
    final documentsSummary = documentsSummaryFrom(documentsSummaryBody);
    final documentTypes = documentTypeNamesFrom(documentTypesBody);

    return TeamReportsPageData(
      team: TeamTabOverview(
        stats: [
          StatTileData(
            id: 'total-staff',
            tag: TeamStatTag.totalStaff,
            value: '$staffTotal',
            label: 'Total Staff',
          ),
          StatTileData(
            id: 'on-duty-now',
            tag: TeamStatTag.onDutyNow,
            value: '$onDutyTotal',
            label: 'On Duty Now',
          ),
          StatTileData(
            id: 'open-shifts',
            tag: TeamStatTag.openShifts,
            value: '$openShiftsTotal',
            label: 'Open Shifts',
          ),
          StatTileData(
            id: 'vacancies',
            tag: TeamStatTag.vacancies,
            value: '$vacanciesTotal',
            label: 'Vacancies',
          ),
        ],
        topReports: reports.take(3).map(_top).toList(),
        recentMessages: conversations.take(5).toList(),
        staffMembers: staffMembers,
      ),
      reports: ReportsTabOverview(
        stats: _kpiStats(kpis: kpis, summary: summary, reportCount: reports.length),
        availableReports: reports,
        insights: insights,
        analytics: analytics,
        exports: exports,
        documentsSummary: documentsSummary,
        documents: documents,
        documentTypeNames: documentTypes,
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
            value: '${conversations.where((item) => item.isUrgent).length}',
            label: 'Urgent',
          ),
        ],
        conversations: conversations,
        announcements: announcementsFrom(notificationsBody),
      ),
    );
  }

  static List<StatTileData<ReportStatTag>> _kpiStats({
    required Map<String, dynamic> kpis,
    required Map<String, dynamic> summary,
    required int reportCount,
  }) {
    return [
      StatTileData(
        id: 'generated',
        tag: ReportStatTag.generated,
        value: JsonCodec.stringOr(
          kpis['generated'] ??
              kpis['reports'] ??
              kpis['total'] ??
              summary['generatedCount'] ??
              reportCount,
          '$reportCount',
        ),
        label: 'Reports',
      ),
      StatTileData(
        id: 'pending-review',
        tag: ReportStatTag.pendingReview,
        value: JsonCodec.stringOr(
          kpis['pendingReview'] ?? kpis['pending'] ?? summary['pendingReview'],
          '0',
        ),
        label: 'Pending Review',
      ),
      StatTileData(
        id: 'critical',
        tag: ReportStatTag.critical,
        value: JsonCodec.stringOr(
          kpis['critical'] ?? summary['critical'],
          '0',
        ),
        label: 'Critical',
      ),
      StatTileData(
        id: 'scheduled',
        tag: ReportStatTag.scheduled,
        value: JsonCodec.stringOr(
          kpis['scheduled'] ?? summary['scheduled'],
          '0',
        ),
        label: 'Scheduled',
      ),
    ];
  }

  static List<TeamStaffMember> staffMembersFrom(dynamic body) {
    final options = <TeamStaffMember>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final user = JsonCodec.mapAt(json, 'user') ??
          JsonCodec.mapAt(json, 'profile') ??
          json;
      final category = JsonCodec.mapAt(json, 'category') ??
          JsonCodec.mapAt(json, 'staffCategory') ??
          const {};
      final name = IsoDateRange.personName(
        user['preferredName'] ??
            user['fullName'] ??
            user['displayName'] ??
            user['name'] ??
            [
              user['firstName'] ?? json['firstName'],
              user['lastName'] ?? json['lastName'],
            ].where((p) => p != null && p.toString().trim().isNotEmpty).join(' '),
      );
      if (name == 'Unknown') continue;
      final role = JsonCodec.string(
        category['name'] ??
            json['categoryName'] ??
            json['role'] ??
            json['jobTitle'] ??
            user['role'],
      );
      options.add(
        TeamStaffMember(
          id: JsonCodec.stringOr(
            json['id'] ?? json['staffId'] ?? user['id'],
            name,
          ),
          name: name,
          initials: IsoDateRange.initials(name),
          role: role,
        ),
      );
    }
    return options;
  }

  static TeamStaffProfile staffProfileFrom({
    required dynamic detailBody,
    dynamic documentsBody,
  }) {
    final json = JsonCodec.unwrapMap(detailBody);
    final user = JsonCodec.mapAt(json, 'user') ??
        JsonCodec.mapAt(json, 'profile') ??
        json;
    final category = JsonCodec.mapAt(json, 'category') ??
        JsonCodec.mapAt(json, 'staffCategory') ??
        const {};
    final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
    final name = IsoDateRange.personName(
      user['preferredName'] ??
          user['fullName'] ??
          user['displayName'] ??
          user['name'] ??
          [
            user['firstName'] ?? json['firstName'],
            user['lastName'] ?? json['lastName'],
          ].where((p) => p != null && p.toString().trim().isNotEmpty).join(' '),
    );
    return TeamStaffProfile(
      id: JsonCodec.stringOr(json['id'] ?? json['staffId'] ?? user['id'], name),
      name: name,
      initials: IsoDateRange.initials(name),
      email: JsonCodec.string(user['email'] ?? json['email']),
      phone: JsonCodec.string(
        user['phone'] ?? json['phone'] ?? json['mobile'] ?? json['phoneNumber'],
      ),
      role: JsonCodec.string(
        category['name'] ??
            json['categoryName'] ??
            json['role'] ??
            json['jobTitle'],
      ),
      residenceName: JsonCodec.string(
        json['residenceName'] ?? residence['name'],
      ),
      documents: staffDocumentsFrom(documentsBody),
    );
  }

  static List<TeamStaffDocument> staffDocumentsFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final at = JsonCodec.dateTime(
            json['updatedAt'] ?? json['createdAt'] ?? json['uploadedAt'],
          );
          return TeamStaffDocument(
            id: JsonCodec.stringOr(json['id'] ?? json['documentId'], 'doc'),
            title: JsonCodec.stringOr(
              json['title'] ?? json['name'] ?? json['fileName'] ?? json['type'],
              'Document',
            ),
            updatedLabel: at == null
                ? null
                : 'Updated ${IsoDateRange.formatShortDate(at.toLocal())}',
          );
        })
        .toList();
  }

  static int _vacancyCount(List<dynamic> openShifts) {
    var count = 0;
    for (final item in openShifts) {
      if (item is! Map) {
        count++;
        continue;
      }
      final json = JsonCodec.asMap(item);
      final assigned = json['assignedStaffIds'] ??
          json['assignees'] ??
          json['staffIds'] ??
          json['assignments'];
      if (assigned is List && assigned.isNotEmpty) continue;
      if (JsonCodec.string(json['assignedStaffId'] ?? json['staffId']) != null) {
        continue;
      }
      count++;
    }
    return count;
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
          title: JsonCodec.stringOr(
            json['title'] ?? json['name'],
            _reportTitle(tag),
          ),
          categoryLabel: JsonCodec.stringOr(json['category'], 'Operations'),
          updatedLabel: at == null
              ? JsonCodec.stringOr(json['period'], '')
              : 'Updated ${IsoDateRange.formatShortDate(at.toLocal())}',
        );
      }).toList();
    }

    final generatedAt = JsonCodec.dateTime(summary['generatedAt']);
    final updated = generatedAt == null
        ? 'Live summary'
        : 'Updated ${IsoDateRange.formatShortDate(generatedAt.toLocal())}';

    final fromSummary = <AvailableReportItem>[
      if (summary['attendance'] is Map)
        AvailableReportItem(
          id: 'attendance_summary',
          tag: ReportTypeTag.staffAttendance,
          title: 'Attendance Summary',
          categoryLabel: 'Attendance',
          updatedLabel:
              '${JsonCodec.integerOr(JsonCodec.asMap(summary['attendance'])['total'], 0)} records · $updated',
        ),
      if (summary['incidents'] is Map)
        AvailableReportItem(
          id: 'incidents_summary',
          tag: ReportTypeTag.incidentAnalysis,
          title: 'Incident Analysis',
          categoryLabel: 'Incidents',
          updatedLabel:
              '${JsonCodec.integerOr(JsonCodec.asMap(summary['incidents'])['total'], 0)} records · $updated',
        ),
      if (summary['mar'] is Map)
        AvailableReportItem(
          id: 'mar_summary',
          tag: ReportTypeTag.medicationCompliance,
          title: 'Medication Compliance',
          categoryLabel: 'MAR',
          updatedLabel:
              '${JsonCodec.integerOr(JsonCodec.asMap(summary['mar'])['total'], 0)} doses · $updated',
        ),
      if (summary['payroll'] is Map)
        AvailableReportItem(
          id: 'payroll_summary',
          tag: ReportTypeTag.dailyCensus,
          title: 'Payroll Summary',
          categoryLabel: 'Payroll',
          updatedLabel:
              '${JsonCodec.integerOr(JsonCodec.asMap(summary['payroll'])['runs'], 0)} runs · $updated',
        ),
    ];
    if (fromSummary.isNotEmpty) return fromSummary;

    return const [];
  }

  static List<ReportInsight> insightsFrom(Map<String, dynamic> seriesBodies) {
    const titles = {
      'attendance': 'Attendance',
      'incidents': 'Incidents',
      'mar': 'Medication (MAR)',
      'payroll': 'Payroll',
    };
    final insights = <ReportInsight>[];
    for (final entry in seriesBodies.entries) {
      final json = JsonCodec.unwrapMap(entry.value);
      final points = JsonCodec.unwrapList(json['points'] ?? json['data'])
          .whereType<Map>()
          .map(JsonCodec.asMap)
          .toList();
      if (points.isEmpty) continue;
      final first = JsonCodec.integerOr(points.first['value'], 0).toDouble();
      final last = JsonCodec.integerOr(points.last['value'], 0).toDouble();
      final delta = last - first;
      final pct = first == 0
          ? (last == 0 ? 0.0 : 100.0)
          : (delta / first) * 100;
      final isUp = delta >= 0;
      insights.add(
        ReportInsight(
          metric: entry.key,
          title: titles[entry.key] ?? entry.key,
          trendLabel: '${isUp ? '+' : ''}${pct.toStringAsFixed(0)}%',
          isUp: isUp,
          detail:
              '${points.length} points · latest ${last.toStringAsFixed(0)}',
        ),
      );
    }
    return insights;
  }

  static List<ReportAnalyticsItem> analyticsFrom(dynamic body) {
    if (body == null) return const [];
    final json = JsonCodec.unwrapMap(body);
    final items = <ReportAnalyticsItem>[];

    void addSeries(String key, String title) {
      final list = JsonCodec.unwrapList(json[key]);
      if (list.isEmpty) return;
      final last = JsonCodec.asMap(list.last);
      items.add(
        ReportAnalyticsItem(
          id: key,
          title: title,
          valueLabel: JsonCodec.stringOr(
            last['primary'] ?? last['value'] ?? last['percent'],
            '0',
          ),
          subtitle: JsonCodec.stringOr(last['period'], 'Latest period'),
        ),
      );
    }

    addSeries('overtime', 'Overtime');
    addSeries('staffing', 'Staffing');
    addSeries('behaviour', 'Behaviour');
    addSeries('payroll', 'Payroll');

    final occupancy = JsonCodec.unwrapList(json['occupancy']);
    for (final row in occupancy.whereType<Map>().take(3)) {
      final map = JsonCodec.asMap(row);
      items.add(
        ReportAnalyticsItem(
          id: JsonCodec.stringOr(map['id'], 'occ'),
          title: JsonCodec.stringOr(map['name'], 'Residence'),
          valueLabel: '${JsonCodec.integerOr(map['percent'], 0)}%',
          subtitle:
              '${JsonCodec.integerOr(map['occupied'], 0)}/${JsonCodec.integerOr(map['capacity'], 0)} occupied',
        ),
      );
    }
    return items;
  }

  static List<ReportExportItem> exportsFrom(dynamic body) {
    if (body == null) return const [];
    final list = JsonCodec.unwrapList(body);
    if (list.isEmpty) {
      final map = JsonCodec.unwrapMap(body);
      if (map.isEmpty || map['id'] == null) return const [];
      return [exportFrom(map)];
    }
    return list
        .whereType<Map>()
        .map((item) => exportFrom(item))
        .toList();
  }

  static ReportExportItem exportFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final at = JsonCodec.dateTime(json['createdAt'] ?? json['updatedAt']);
    return ReportExportItem(
      id: JsonCodec.stringOr(json['id'], 'export'),
      reportKey: JsonCodec.stringOr(json['reportKey'] ?? json['name'], 'report'),
      format: JsonCodec.stringOr(json['format'], 'csv'),
      status: JsonCodec.stringOr(json['status'], 'unknown'),
      createdLabel: at == null
          ? ''
          : IsoDateRange.formatShortDate(at.toLocal()),
      downloadUrl: JsonCodec.string(
        json['downloadUrl'] ?? json['signedUrl'] ?? json['fileUrl'],
      ),
    );
  }

  static List<ReportDocumentItem> documentsFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final at = JsonCodec.dateTime(
            json['updatedAt'] ?? json['createdAt'] ?? json['expiresAt'],
          );
          return ReportDocumentItem(
            id: JsonCodec.stringOr(json['id'], 'doc'),
            title: JsonCodec.stringOr(
              json['name'] ?? json['title'] ?? json['fileName'],
              'Document',
            ),
            statusLabel: JsonCodec.stringOr(json['status'], 'active'),
            updatedLabel: at == null
                ? null
                : IsoDateRange.formatShortDate(at.toLocal()),
          );
        })
        .toList();
  }

  static ReportDocumentsSummary? documentsSummaryFrom(dynamic body) {
    if (body == null) return null;
    final json = JsonCodec.unwrapMap(body);
    if (json.isEmpty) return null;
    return ReportDocumentsSummary(
      total: JsonCodec.integerOr(json['documents'] ?? json['total'], 0),
      expiringSoon: JsonCodec.integerOr(json['expiringSoon'], 0),
      expired: JsonCodec.integerOr(json['expired'], 0),
      missingMandatory: JsonCodec.integerOr(json['missingMandatory'], 0),
    );
  }

  static List<String> documentTypeNamesFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          return JsonCodec.string(json['name'] ?? json['title'] ?? json['label']);
        })
        .whereType<String>()
        .toList();
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
    final nestedLast = JsonCodec.mapAt(json, 'lastMessage');
    Map<String, dynamic>? last = nestedLast;
    DateTime? lastAt = nestedLast == null
        ? null
        : JsonCodec.dateTime(nestedLast['createdAt']);

    // Live API puts the latest message in `messages[]`, not `lastMessage`.
    for (final raw in JsonCodec.listAt(json, 'messages').whereType<Map>()) {
      final row = JsonCodec.asMap(raw);
      final at = JsonCodec.dateTime(row['createdAt']);
      if (last == null ||
          (at != null && (lastAt == null || at.isAfter(lastAt)))) {
        last = row;
        lastAt = at;
      }
    }
    last ??= const <String, dynamic>{};

    final members = JsonCodec.listAt(json, 'members');
    final type = (json['type'] ?? '').toString().toLowerCase();
    final isGroup = JsonCodec.boolean(json['isGroup'] ?? json['group']) ??
        (type.contains('group') ||
            type.contains('residence') ||
            members.length > 2);

    String? peerName;
    if (!isGroup) {
      for (final raw in members.whereType<Map>()) {
        final member = JsonCodec.asMap(raw);
        final user = JsonCodec.mapAt(member, 'user') ?? member;
        final name = JsonCodec.string(user['name'] ?? user['fullName']);
        if (name != null && name.trim().isNotEmpty) {
          peerName = name.trim();
          break;
        }
      }
    }

    final name = IsoDateRange.personName(
      json['title'] ??
          json['name'] ??
          peerName ??
          json['participantName'] ??
          last['senderName'] ??
          json['subject'],
    );
    lastAt ??= JsonCodec.dateTime(
      last['createdAt'] ?? json['updatedAt'] ?? json['lastMessageAt'],
    );

    String preview = JsonCodec.stringOr(
      last['body'] ?? last['text'] ?? json['preview'],
      '',
    );
    if (preview.isEmpty && json['lastMessage'] is String) {
      preview = json['lastMessage'] as String;
    }

    return ConversationPreview(
      id: JsonCodec.stringOr(json['id'], name),
      senderName: name,
      initials: IsoDateRange.initials(name),
      timeLabel: lastAt == null ? '' : IsoDateRange.timeLabel(lastAt.toLocal()),
      previewText: preview,
      unreadCount: JsonCodec.integerOr(json['unreadCount'], 0),
      isGroup: isGroup,
      isUrgent: _isUrgentConversation(json, last),
    );
  }

  static List<Announcement> announcementsFrom(dynamic body) {
    if (body == null) return const [];
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final at = JsonCodec.dateTime(
            json['createdAt'] ?? json['sentAt'] ?? json['updatedAt'],
          );
          final title = JsonCodec.stringOr(
            json['title'] ?? json['subject'] ?? json['type'],
            'Announcement',
          );
          final bodyText = JsonCodec.stringOr(
            json['body'] ?? json['message'] ?? json['text'],
            '',
          );
          final meta = JsonCodec.mapAt(json, 'metaJson') ??
              JsonCodec.mapAt(json, 'meta') ??
              const <String, dynamic>{};
          final eventKey = (JsonCodec.string(
                    meta['eventKey'] ?? meta['event'] ?? json['type'],
                  ) ??
                  '')
              .toLowerCase();
          final blob = '$eventKey $title $bodyText'.toLowerCase();
          final tag = blob.contains('train')
              ? AnnouncementTag.training
              : AnnouncementTag.policy;
          final priority = blob.contains('urgent') ||
                  blob.contains('emergency') ||
                  blob.contains('critical') ||
                  blob.contains('incident') ||
                  JsonCodec.boolean(json['isRead']) == false
              ? AnnouncementPriority.highPriority
              : AnnouncementPriority.upcoming;

          return Announcement(
            id: JsonCodec.stringOr(
              json['id'] ?? json['notificationId'],
              title,
            ),
            tag: tag,
            title: title,
            dateLabel: at == null
                ? ''
                : IsoDateRange.formatShortDate(at.toLocal()),
            priority: priority,
          );
        })
        .take(20)
        .toList();
  }

  static bool _isUrgentConversation(
    Map<String, dynamic> json,
    Map<String, dynamic> last,
  ) {
    if (JsonCodec.boolean(json['urgent'] ?? json['isUrgent'] ?? last['urgent']) ==
        true) {
      return true;
    }
    final priority =
        (JsonCodec.string(json['priority'] ?? last['priority']) ?? '')
            .toLowerCase();
    return priority == 'urgent' || priority == 'high' || priority == 'critical';
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
