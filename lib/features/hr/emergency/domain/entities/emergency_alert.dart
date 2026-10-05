/// Someone named on an alert (raiser, acknowledger, assignee, actor).
class EmergencyPerson {
  final String id;
  final String? name;
  final String? phone;

  const EmergencyPerson({required this.id, this.name, this.phone});
}

/// One entry of the alert's "Response" timeline.
class EmergencyAction {
  final String id;
  final String action;
  final String? actorName;
  final String? targetName;
  final String? note;
  final DateTime? createdAt;

  const EmergencyAction({
    required this.id,
    required this.action,
    this.actorName,
    this.targetName,
    this.note,
    this.createdAt,
  });
}

class EmergencyAttachment {
  final String id;
  final String fileUrl;

  const EmergencyAttachment({required this.id, required this.fileUrl});

  String get fileName => fileUrl.split('/').last;
}

/// An `/emergency-alerts` row.
class EmergencyAlert {
  final String id;
  final String type;
  final String status;
  final String? priority;
  final String? note;
  final String? locationNote;
  final String? residenceName;
  final String? residencePhone;
  final String? residenceEmergencyPhone;
  final String? clientName;
  final EmergencyPerson? raiser;
  final EmergencyPerson? acknowledger;
  final EmergencyPerson? assignee;
  final DateTime? createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final List<EmergencyAction> actions;
  final List<EmergencyAttachment> attachments;

  const EmergencyAlert({
    required this.id,
    required this.type,
    required this.status,
    this.priority,
    this.note,
    this.locationNote,
    this.residenceName,
    this.residencePhone,
    this.residenceEmergencyPhone,
    this.clientName,
    this.raiser,
    this.acknowledger,
    this.assignee,
    this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolutionNote,
    this.actions = const [],
    this.attachments = const [],
  });

  bool get isActive => status == 'active';

  /// Still waiting for, or receiving, a response.
  bool get isOpen =>
      status == 'active' || status == 'acknowledged' || status == 'in_progress';

  /// The detail modal's "Add to the response" and footer actions.
  bool get isClosed => status == 'resolved' || status == 'cancelled';

  /// Row "House line": the emergency number, else the main number.
  String? get houseLine => residenceEmergencyPhone ?? residencePhone;
}

class EmergencyAlertPage {
  final List<EmergencyAlert> items;
  final int total;

  const EmergencyAlertPage({required this.items, required this.total});
}

/// The four KPI tiles, counted from the first 100 alerts.
class EmergencyStats {
  final int active;
  final int awaitingResponse;
  final int inProgress;
  final int resolvedToday;

  const EmergencyStats({
    this.active = 0,
    this.awaitingResponse = 0,
    this.inProgress = 0,
    this.resolvedToday = 0,
  });

  factory EmergencyStats.from(List<EmergencyAlert> alerts, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    return EmergencyStats(
      active: alerts.where((a) => a.status == 'active').length,
      awaitingResponse: alerts.where((a) => a.status == 'acknowledged').length,
      inProgress: alerts.where((a) => a.status == 'in_progress').length,
      resolvedToday: alerts
          .where((a) =>
              a.status == 'resolved' &&
              a.resolvedAt != null &&
              !a.resolvedAt!.toLocal().isBefore(midnight))
          .length,
    );
  }
}

class EmergencyOption {
  final String id;
  final String label;

  const EmergencyOption({required this.id, required this.label});
}
