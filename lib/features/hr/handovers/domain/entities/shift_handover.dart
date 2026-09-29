/// A `/shift-handovers` record: what one shift tells the next.
class ShiftHandover {
  final String id;
  final String residenceId;
  final String? residenceName;
  final String? fromShiftId;
  final DateTime? fromShiftStartsAt;
  final DateTime? toShiftStartsAt;
  final String summary;

  /// `draft`, `submitted`, `viewed` or `acknowledged`.
  final String status;
  final List<String> pendingActions;
  final List<HandoverClientUpdate> clientUpdates;
  final int alertingCount;
  final bool needsAcknowledgement;
  final List<HandoverIncident> incidents;
  final List<HandoverComment> comments;
  final List<HandoverTask> tasks;
  final List<HandoverAcknowledgement> acknowledgements;
  final String? flagCategory;
  final String? createdBy;
  final String? authorName;
  final DateTime? createdAt;

  const ShiftHandover({
    required this.id,
    required this.residenceId,
    required this.summary,
    required this.status,
    this.residenceName,
    this.fromShiftId,
    this.fromShiftStartsAt,
    this.toShiftStartsAt,
    this.pendingActions = const [],
    this.clientUpdates = const [],
    this.alertingCount = 0,
    this.needsAcknowledgement = false,
    this.incidents = const [],
    this.comments = const [],
    this.tasks = const [],
    this.acknowledgements = const [],
    this.flagCategory,
    this.createdBy,
    this.authorName,
    this.createdAt,
  });

  bool acknowledgedBy(String? userId) =>
      userId != null && acknowledgements.any((a) => a.userId == userId);
}

class HandoverClientUpdate {
  final String id;
  final String? clientName;

  /// `stable`, `needs_attention` or `urgent`.
  final String status;
  final Map<String, String> health;
  final Map<String, String> medication;
  final HandoverCare? care;

  const HandoverClientUpdate({
    required this.id,
    required this.status,
    this.clientName,
    this.health = const {},
    this.medication = const {},
    this.care,
  });
}

class HandoverCare {
  final List<String> completed;
  final String? otherCompleted;
  final String? pending;
  final String? followUpRequired;

  const HandoverCare({
    this.completed = const [],
    this.otherCompleted,
    this.pending,
    this.followUpRequired,
  });
}

class HandoverIncident {
  final String id;
  final String? reference;
  final String? title;
  final String? severity;
  final String? categoryName;

  const HandoverIncident({
    required this.id,
    this.reference,
    this.title,
    this.severity,
    this.categoryName,
  });
}

class HandoverComment {
  final String id;
  final String body;
  final String? authorName;
  final DateTime? createdAt;

  const HandoverComment({
    required this.id,
    required this.body,
    this.authorName,
    this.createdAt,
  });
}

class HandoverTask {
  final String id;
  final String title;
  final String status;
  final String? priority;
  final List<String> assigneeFirstNames;

  const HandoverTask({
    required this.id,
    required this.title,
    required this.status,
    this.priority,
    this.assigneeFirstNames = const [],
  });

  bool get done => status == 'done' || status == 'completed';
}

class HandoverAcknowledgement {
  final String userId;
  final String? staffFirstName;
  final String? userName;
  final DateTime? createdAt;

  const HandoverAcknowledgement({
    required this.userId,
    this.staffFirstName,
    this.userName,
    this.createdAt,
  });
}

/// `announcedTo` on a created handover.
class HandoverAnnouncement {
  final String mode;
  final int recipients;

  const HandoverAnnouncement({required this.mode, required this.recipients});
}
