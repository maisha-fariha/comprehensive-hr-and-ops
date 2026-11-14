import '../../../../../core/formatting/web_formats.dart';

/// Manager "Outing requests" row from `GET /outings`.
class HrOuting {
  final String id;
  final String clientId;
  final String clientName;
  final String? residenceId;
  final String? residenceName;
  final String destination;
  final String? purpose;
  final DateTime departAt;
  final DateTime returnAt;
  final String responsibleAdultName;
  final String responsibleAdultPhone;
  final String? transportType;
  final bool needsMedicationPack;
  final String? specialInstructions;
  final String status;
  final String? requesterName;
  final String? decisionNotes;
  final String? decidedByName;

  const HrOuting({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.residenceId,
    this.residenceName,
    required this.destination,
    this.purpose,
    required this.departAt,
    required this.returnAt,
    required this.responsibleAdultName,
    required this.responsibleAdultPhone,
    this.transportType,
    this.needsMedicationPack = false,
    this.specialInstructions,
    required this.status,
    this.requesterName,
    this.decisionNotes,
    this.decidedByName,
  });

  bool get isPending => status == 'pending';

  String get title => '$clientName — $destination';

  String get windowLabel {
    final start = _stamp(departAt);
    final end = _stamp(returnAt);
    final home = residenceName?.trim();
    if (home == null || home.isEmpty) return '$start → $end';
    return '$start → $end · $home';
  }

  String get transportLabel {
    final raw = transportType?.trim() ?? '';
    if (raw.isEmpty) return '';
    return WebFormat.humanise(raw);
  }

  String get statusLabel => switch (status) {
        'pending' => 'Awaiting decision',
        'approved' => 'Approved',
        'declined' => 'Declined',
        'cancelled' => 'Withdrawn by family',
        _ => WebFormat.humanise(status),
      };

  static String _stamp(DateTime value) {
    final date = WebFormat.date(value, weekday: true);
    final time = WebFormat.time(value);
    if (date == '—' && time == '—') return '—';
    if (date == '—') return time;
    if (time == '—') return date;
    return '$date, $time';
  }
}

class HrOutingPage {
  final List<HrOuting> items;
  final int total;
  final int totalPages;

  const HrOutingPage({
    required this.items,
    required this.total,
    required this.totalPages,
  });
}

class HrOutingQuery {
  final int page;
  final int limit;
  final String? status;
  final String? residenceId;

  const HrOutingQuery({
    this.page = 1,
    this.limit = 50,
    this.status,
    this.residenceId,
  });
}
