import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_daily_activity_item.dart';
import '../../domain/entities/staff_daily_activity_metrics.dart';
import '../../domain/entities/staff_daily_activity_option.dart';
import '../../domain/entities/staff_daily_activity_overview.dart';

abstract final class StaffDailyActivityMapper {
  static StaffDailyActivityOverview fromListBody(dynamic body) {
    final items = JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((raw) => itemFromJson(JsonCodec.asMap(raw)))
        .toList();

    final root = body is Map ? JsonCodec.asMap(body) : const <String, dynamic>{};
    final meta = JsonCodec.mapAt(root, 'meta') ?? const {};
    final summary = JsonCodec.mapAt(meta, 'summary') ?? const {};

    return StaffDailyActivityOverview(
      metrics: StaffDailyActivityMetrics(
        todaysActivities: _int(summary['todaysActivities']),
        activeClients: _int(summary['activeClients']),
        staffEntries: _int(summary['staffEntries']),
        pendingReview: _int(summary['pendingReview']),
      ),
      items: items,
      total: _int(meta['total'], fallback: items.length),
      page: _int(meta['page'], fallback: 1),
      limit: _int(meta['limit'], fallback: 20),
      totalPages: _int(meta['totalPages'], fallback: 1),
    );
  }

  static StaffDailyActivityItem itemFromJson(Map<String, dynamic> json) {
    final id = JsonCodec.stringOr(json['id'], '');
    final client = JsonCodec.mapAt(json, 'client') ?? const {};
    final residence = JsonCodec.mapAt(client, 'residence') ?? const {};
    final recordedBy = JsonCodec.mapAt(json, 'recordedByStaff') ??
        JsonCodec.mapAt(json, 'author') ??
        const {};

    final residentName = IsoDateRange.personName(client);
    final authorName = IsoDateRange.personName(recordedBy);
    final activityDate = JsonCodec.dateTime(json['activityDate']);
    final occurredAt = JsonCodec.dateTime(json['occurredAt']);
    final type = JsonCodec.stringOr(json['activityType'], '');
    final status = JsonCodec.stringOr(json['status'], '');

    return StaffDailyActivityItem(
      id: id,
      activityCode: _activityCode(id),
      clientId: JsonCodec.stringOr(json['clientId'] ?? client['id'], ''),
      residentName: residentName == 'Unknown' ? 'Resident' : residentName,
      residenceName: JsonCodec.stringOr(residence['name'], ''),
      activityType: type,
      activityTypeLabel: StaffDailyActivityEnums.labelForType(type),
      description: JsonCodec.stringOr(json['description'], ''),
      notes: JsonCodec.stringOr(json['notes'], ''),
      recordedByName: authorName == 'Unknown' ? '—' : authorName,
      recordedByInitials: IsoDateRange.initials(
        authorName == 'Unknown' ? null : authorName,
        fallback: '—',
      ),
      recordedByStaffId: JsonCodec.string(
        json['recordedByStaffId'] ?? recordedBy['id'],
      ),
      activityDate: activityDate,
      occurredAt: occurredAt,
      dateTimeLabel: _dateTimeLabel(activityDate, occurredAt),
      status: status,
      statusLabel: StaffDailyActivityEnums.labelForStatus(status),
    );
  }

  static List<StaffDailyActivityPersonOption> peopleFrom(
    dynamic body, {
    bool preferDisplayName = false,
  }) {
    return JsonCodec.unwrapList(body).whereType<Map>().map((raw) {
      final json = JsonCodec.asMap(raw);
      final id = JsonCodec.stringOr(json['id'], '');
      final name = preferDisplayName
          ? JsonCodec.stringOr(
              json['displayName'] ??
                  json['name'] ??
                  '${JsonCodec.stringOr(json['firstName'], '')} ${JsonCodec.stringOr(json['lastName'], '')}'
                      .trim(),
              'Unknown',
            )
          : IsoDateRange.personName(json);
      final residence = JsonCodec.mapAt(json, 'residence');
      final subtitle = residence == null
          ? null
          : JsonCodec.string(residence['name']);
      return StaffDailyActivityPersonOption(
        id: id,
        name: name.trim().isEmpty ? 'Unknown' : name.trim(),
        subtitle: subtitle,
      );
    }).where((p) => p.id.isNotEmpty).toList();
  }

  static String _activityCode(String id) {
    final compact = id.replaceAll('-', '').toUpperCase();
    if (compact.isEmpty) return 'ACT-—';
    final take = compact.length >= 8 ? compact.substring(0, 8) : compact;
    return 'ACT-$take';
  }

  static String _dateTimeLabel(DateTime? activityDate, DateTime? occurredAt) {
    final primary = (occurredAt ?? activityDate)?.toLocal();
    if (primary == null) return '—';
    final d =
        '${primary.day.toString().padLeft(2, '0')}/${primary.month.toString().padLeft(2, '0')}/${primary.year}';
    if (occurredAt == null) return d;
    final h = primary.hour.toString().padLeft(2, '0');
    final m = primary.minute.toString().padLeft(2, '0');
    return '$d $h:$m';
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
