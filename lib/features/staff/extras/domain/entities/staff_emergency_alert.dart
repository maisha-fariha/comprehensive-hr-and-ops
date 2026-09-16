import '../../../../../core/network/json_codec.dart';

class StaffEmergencyResponseNote {
  final String id;
  final String note;
  final String actorName;
  final DateTime? createdAt;

  const StaffEmergencyResponseNote({
    required this.id,
    required this.note,
    required this.actorName,
    this.createdAt,
  });
}

class StaffEmergencyAlert {
  final String id;
  final String status;
  final String priority;
  final String type;
  final String typeLabel;
  final String residenceName;
  final String houseLine;
  final String raisedByName;
  final String raisedByPhone;
  final String note;
  final String locationNote;
  final String residentLabel;
  final String assignedToLabel;
  final String resolutionNote;
  final List<StaffEmergencyResponseNote> responseNotes;
  final DateTime? createdAt;

  const StaffEmergencyAlert({
    required this.id,
    required this.status,
    required this.priority,
    required this.type,
    required this.typeLabel,
    required this.residenceName,
    required this.houseLine,
    required this.raisedByName,
    required this.raisedByPhone,
    required this.note,
    required this.locationNote,
    this.residentLabel = 'Not about a resident',
    this.assignedToLabel = 'Nobody yet',
    this.resolutionNote = '',
    this.responseNotes = const [],
    this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';

  bool get isAcknowledged => status.toLowerCase() == 'acknowledged';

  bool get isInProgress {
    final s = status.toLowerCase().replaceAll('-', '_');
    return s == 'in_progress';
  }

  bool get isResolved => status.toLowerCase() == 'resolved';

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get statusLabel {
    if (isInProgress) return 'In Progress';
    final s = status.toLowerCase();
    if (s.isEmpty) return 'Unknown';
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  String get priorityLabel {
    final p = priority.toLowerCase();
    if (p.isEmpty) return '';
    if (p == 'critical' || p == 'high' || p == 'urgent') return 'High';
    if (p == 'low') return 'Low';
    if (p == 'standard' || p == 'normal') return 'Standard';
    return '${priority[0].toUpperCase()}${priority.substring(1)}';
  }

  String get raisedMeta {
    final parts = <String>[];
    if (raisedByName.isNotEmpty) parts.add('Raised by $raisedByName');
    if (raisedByPhone.isNotEmpty) parts.add(raisedByPhone);
    if (createdAt != null) {
      parts.add(_dateLabel(createdAt!));
    }
    return parts.join(' · ');
  }

  String get headerSubtitle {
    final parts = <String>[];
    if (residenceName.isNotEmpty) parts.add(residenceName);
    if (createdAt != null) {
      parts.add('${_dateLabel(createdAt!)} $timeLabel');
    }
    return parts.join(' · ');
  }

  String get timeLabel {
    if (createdAt == null) return '';
    final d = createdAt!.toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get locationDisplay =>
      locationNote.trim().isEmpty ? '—' : locationNote.trim();

  static String _dateLabel(DateTime value) {
    final d = value.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  static StaffEmergencyAlert fromJson(Map<String, dynamic> json) {
    final raiser = JsonCodec.mapAt(json, 'raiser') ?? const {};
    final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
    final client = JsonCodec.mapAt(json, 'client');
    final assignee = JsonCodec.mapAt(json, 'assignee');
    final type = JsonCodec.stringOr(json['type'], 'other');

    var residentLabel = 'Not about a resident';
    if (client != null) {
      final name = JsonCodec.string(
        client['name'] ??
            [
              JsonCodec.stringOr(client['firstName'], ''),
              JsonCodec.stringOr(client['lastName'], ''),
            ].where((p) => p.isNotEmpty).join(' '),
      );
      if (name != null && name.trim().isNotEmpty) {
        residentLabel = name.trim();
      }
    }

    var assignedToLabel = 'Nobody yet';
    final assigneeName = JsonCodec.string(assignee?['name']);
    if (assigneeName != null && assigneeName.isNotEmpty) {
      assignedToLabel = assigneeName;
    } else {
      final assignedRaw = JsonCodec.string(json['assignedTo']);
      if (assignedRaw != null && assignedRaw.isNotEmpty) {
        assignedToLabel = assignedRaw;
      }
    }

    final responseNotes = <StaffEmergencyResponseNote>[];
    for (final item in JsonCodec.unwrapList(json['actions']).whereType<Map>()) {
      final action = JsonCodec.asMap(item);
      final kind = JsonCodec.stringOr(action['action'], '');
      final text = JsonCodec.stringOr(action['note'], '').trim();
      if (text.isEmpty) continue;
      if (kind.isNotEmpty && kind != 'note' && kind != 'status') continue;
      final actor = JsonCodec.mapAt(action, 'actor') ?? const {};
      responseNotes.add(
        StaffEmergencyResponseNote(
          id: JsonCodec.stringOr(action['id'], text),
          note: text,
          actorName: JsonCodec.stringOr(actor['name'], ''),
          createdAt: JsonCodec.dateTime(action['createdAt']),
        ),
      );
    }

    final resolution = JsonCodec.stringOr(json['resolutionNote'], '');
    if (resolution.isNotEmpty &&
        !responseNotes.any((n) => n.note == resolution)) {
      final resolver = JsonCodec.mapAt(json, 'resolver') ?? const {};
      responseNotes.insert(
        0,
        StaffEmergencyResponseNote(
          id: 'resolution',
          note: resolution,
          actorName: JsonCodec.stringOr(resolver['name'], 'Resolution'),
          createdAt: JsonCodec.dateTime(json['resolvedAt']),
        ),
      );
    }

    return StaffEmergencyAlert(
      id: JsonCodec.stringOr(json['id'], ''),
      status: JsonCodec.stringOr(json['status'], ''),
      priority: JsonCodec.stringOr(json['priority'], ''),
      type: type,
      typeLabel: _typeLabel(type),
      residenceName: JsonCodec.stringOr(
        residence['name'] ?? json['residenceName'],
        '',
      ),
      houseLine: JsonCodec.stringOr(
        residence['emergencyPhone'] ?? residence['phone'],
        '',
      ),
      raisedByName: JsonCodec.stringOr(
        raiser['name'] ?? json['raisedByName'],
        '',
      ),
      raisedByPhone: JsonCodec.stringOr(raiser['phone'], ''),
      note: JsonCodec.stringOr(json['note'], ''),
      locationNote: JsonCodec.stringOr(json['locationNote'], ''),
      residentLabel: residentLabel,
      assignedToLabel: assignedToLabel,
      resolutionNote: resolution,
      responseNotes: responseNotes,
      createdAt: JsonCodec.dateTime(json['createdAt']),
    );
  }

  static String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return 'Medical';
      case 'security':
        return 'Security';
      case 'fire':
        return 'Fire';
      case 'behavioral':
        return 'Behavioral';
      case 'missing':
        return 'Missing';
      default:
        if (type.isEmpty) return 'Alert';
        return '${type[0].toUpperCase()}${type.substring(1)}';
    }
  }
}
