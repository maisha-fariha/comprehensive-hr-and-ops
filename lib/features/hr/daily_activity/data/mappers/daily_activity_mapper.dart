import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/daily_activity.dart';

abstract final class DailyActivityMapper {
  static String? fullName(Map<String, dynamic>? person) {
    if (person == null) return null;
    final name = [
      JsonCodec.string(person['firstName']),
      JsonCodec.string(person['lastName']),
    ].whereType<String>().join(' ').trim();
    if (name.isNotEmpty) return name;
    return JsonCodec.string(person['displayName'] ?? person['name']);
  }

  static DailyActivityListResult pageFrom(dynamic body) {
    final items = JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((raw) => activityFrom(JsonCodec.asMap(raw)))
        .whereType<DailyActivity>()
        .toList();
    final meta = JsonCodec.metaOf(body) ?? const <String, dynamic>{};
    final summary = JsonCodec.mapAt(meta, 'summary') ?? const <String, dynamic>{};
    return DailyActivityListResult(
      items: items,
      total: JsonCodec.integerOr(meta['total'], items.length),
      totalPages: JsonCodec.integerOr(meta['totalPages'], 0),
      stats: DailyActivityStats(
        todaysActivities: JsonCodec.integerOr(summary['todaysActivities'], 0),
        activeClients: JsonCodec.integerOr(summary['activeClients'], 0),
        staffEntries: JsonCodec.integerOr(summary['staffEntries'], 0),
        pendingReview: JsonCodec.integerOr(summary['pendingReview'], 0),
      ),
    );
  }

  static DailyActivity? activityFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final client = JsonCodec.mapAt(json, 'client');
    final residence = client == null ? null : JsonCodec.mapAt(client, 'residence');
    final author = JsonCodec.mapAt(json, 'author');
    final rawDate = JsonCodec.stringOr(json['activityDate'], '');
    final files = json['attachments'] is List
        ? json['attachments'] as List
        : JsonCodec.listAt(json, 'attachmentsJson');
    return DailyActivity(
      id: id,
      clientId: JsonCodec.stringOr(json['clientId'] ?? client?['id'], ''),
      clientName: fullName(client),
      clientResidence: residence == null ? null : JsonCodec.string(residence['name']),
      clientLevel: client == null ? null : JsonCodec.string(client['level']),
      activityType: JsonCodec.stringOr(json['activityType'], ''),
      status: JsonCodec.stringOr(json['status'], ''),
      description: JsonCodec.string(json['description']),
      notes: JsonCodec.string(json['notes']),
      recordedByStaffId: JsonCodec.string(json['recordedByStaffId']),
      recordedByStaffName: fullName(JsonCodec.mapAt(json, 'recordedByStaff')),
      authorName: author == null ? null : JsonCodec.string(author['name']),
      activityDate: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
      occurredAt: JsonCodec.dateTime(json['occurredAt']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      updatedAt: JsonCodec.dateTime(json['updatedAt']),
      attachments: [
        for (final raw in files.whereType<Map>())
          if (JsonCodec.string(raw['fileUrl']) case final url?)
            DailyActivityAttachment(
              fileUrl: url,
              fileType: JsonCodec.string(raw['fileType']),
            ),
      ],
    );
  }

  static DailyActivityMonthSummary monthSummaryFrom(dynamic body) {
    final data = JsonCodec.unwrapMap(body);
    final byStatus = JsonCodec.asMap(data['byStatus']);
    final byType = JsonCodec.asMap(data['byType']);
    return DailyActivityMonthSummary(
      byStatus: [
        for (final e in byStatus.entries) (e.key, JsonCodec.integerOr(e.value, 0)),
      ],
      byType: [
        for (final e in byType.entries)
          (
            e.key,
            JsonCodec.integerOr(JsonCodec.asMap(e.value)['present'], 0) +
                JsonCodec.integerOr(JsonCodec.asMap(e.value)['absent'], 0),
          ),
      ],
    );
  }

  static List<DailyActivityOption> clientsFrom(dynamic body) => [
        for (final raw in JsonCodec.unwrapList(body).whereType<Map>())
          ?_clientOption(JsonCodec.asMap(raw)),
      ];

  static DailyActivityOption? _clientOption(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final residence = JsonCodec.mapAt(json, 'residence');
    final residenceName = residence == null ? null : JsonCodec.string(residence['name']);
    final room = JsonCodec.string(json['roomNumber']);
    return DailyActivityOption(
      id: id,
      name: fullName(json) ?? 'Unknown',
      subtitle: [?residenceName, if (room != null) 'Room $room'].join(' · '),
      residenceName: residenceName,
      level: JsonCodec.string(json['level']),
    );
  }

  static List<DailyActivityOption> staffFrom(dynamic body) => [
        for (final raw in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(raw['id']) case final id?)
            DailyActivityOption(
              id: id,
              name: fullName(JsonCodec.asMap(raw)) ?? 'Unknown',
              subtitle: JsonCodec.string(
                    JsonCodec.asMap(raw['category'])['name'],
                  ) ??
                  'Staff',
            ),
      ];
}
