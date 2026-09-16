import '../../../../../core/network/json_codec.dart';

class StaffShiftHandover {
  final String id;
  final String residenceName;
  final String summary;
  final String status;
  final String authorName;
  final DateTime? createdAt;
  final int alertingCount;
  final List<String> clientNames;
  final List<String> pendingActions;
  final List<String> acknowledgementLabels;
  final bool isAcknowledged;

  const StaffShiftHandover({
    required this.id,
    required this.residenceName,
    required this.summary,
    required this.status,
    required this.authorName,
    this.createdAt,
    this.alertingCount = 0,
    this.clientNames = const [],
    this.pendingActions = const [],
    this.acknowledgementLabels = const [],
    this.isAcknowledged = false,
  });

  String get authorMeta {
    final parts = <String>[];
    if (authorName.isNotEmpty) parts.add(authorName);
    if (createdAt != null) parts.add(_dateTimeLabel(createdAt!));
    return parts.join(' · ');
  }

  String get acknowledgementFooter => acknowledgementLabels.join(' · ');

  String displayResidence([String? fallback]) {
    if (residenceName.isNotEmpty && residenceName != 'Residence') {
      return residenceName;
    }
    if (fallback != null && fallback.trim().isNotEmpty) return fallback.trim();
    return residenceName;
  }

  String get attentionLabel {
    if (alertingCount <= 0) return '';
    if (alertingCount == 1) return '1 needing attention';
    return '$alertingCount needing attention';
  }

  static String _dateTimeLabel(DateTime value) {
    final d = value.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} $hour:$minute';
  }

  static String _timeLabel(DateTime value) {
    final d = value.toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static StaffShiftHandover fromJson(Map<String, dynamic> json) {
    final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
    final author = JsonCodec.mapAt(json, 'author') ?? const {};
    final createdBy = JsonCodec.mapAt(json, 'createdByUser') ??
        JsonCodec.mapAt(json, 'createdByStaff');

    final clientNames = <String>[];
    for (final item
        in JsonCodec.unwrapList(json['clientUpdates']).whereType<Map>()) {
      final row = JsonCodec.asMap(item);
      final name = JsonCodec.string(
        row['clientName'] ??
            JsonCodec.mapAt(row, 'client')?['name'] ??
            row['name'],
      );
      if (name != null && name.trim().isNotEmpty) {
        clientNames.add(name.trim());
      }
    }

    final pending = <String>[];
    for (final item in JsonCodec.unwrapList(json['pendingActions'])) {
      if (item is String && item.trim().isNotEmpty) {
        pending.add(item.trim());
      } else if (item is Map) {
        final row = JsonCodec.asMap(item);
        final title = JsonCodec.string(row['title'] ?? row['name'] ?? row);
        if (title != null && title.trim().isNotEmpty) pending.add(title.trim());
      }
    }
    for (final item in JsonCodec.unwrapList(json['tasks']).whereType<Map>()) {
      final row = JsonCodec.asMap(item);
      final title = JsonCodec.string(row['title']);
      if (title != null &&
          title.trim().isNotEmpty &&
          !pending.contains(title.trim())) {
        pending.add(title.trim());
      }
    }

    final ackLabels = <String>[];
    for (final item
        in JsonCodec.unwrapList(json['acknowledgements']).whereType<Map>()) {
      final row = JsonCodec.asMap(item);
      final user = JsonCodec.mapAt(row, 'user') ??
          JsonCodec.mapAt(row, 'staff') ??
          const {};
      final name = JsonCodec.string(
            user['name'] ??
                [
                  JsonCodec.stringOr(user['firstName'], ''),
                  JsonCodec.stringOr(user['lastName'], ''),
                ].where((p) => p.isNotEmpty).join(' '),
          ) ??
          '';
      final at = JsonCodec.dateTime(row['createdAt'] ?? row['acknowledgedAt']);
      if (name.isEmpty) continue;
      if (at != null) {
        ackLabels.add('$name at ${_timeLabel(at)}');
      } else {
        ackLabels.add(name);
      }
    }

    final alerting = JsonCodec.integerOr(
      json['alertingCount'],
      clientNames.isEmpty
          ? 0
          : JsonCodec.unwrapList(json['clientUpdates']).whereType<Map>().where((
              item,
            ) {
              final status = JsonCodec.stringOr(
                JsonCodec.asMap(item)['status'],
                '',
              );
              return status == 'needs_attention' || status == 'flagged';
            }).length,
    );

    final status = JsonCodec.stringOr(json['status'], '');
    final acknowledged = ackLabels.isNotEmpty ||
        status.toLowerCase() == 'acknowledged' ||
        status.toLowerCase() == 'viewed';

    return StaffShiftHandover(
      id: JsonCodec.stringOr(json['id'], ''),
      residenceName: JsonCodec.stringOr(
        residence['name'] ?? json['residenceName'],
        'Residence',
      ),
      summary: JsonCodec.stringOr(json['summary'], ''),
      status: status,
      authorName: JsonCodec.stringOr(
        author['name'] ?? createdBy?['name'] ?? json['createdByName'],
        '',
      ),
      createdAt: JsonCodec.dateTime(json['createdAt'] ?? json['submittedAt']),
      alertingCount: alerting,
      clientNames: clientNames,
      pendingActions: pending,
      acknowledgementLabels: ackLabels,
      isAcknowledged: acknowledged,
    );
  }
}
