/// Stages a referral can no longer leave.
const List<String> closedReferralStatuses = ['admitted', 'declined', 'withdrawn'];

/// `GET /referrals/board`.
class ReferralBoard {
  final int pending;
  final int awaitingDocuments;
  final int assessmentPending;
  final int admittedLast30Days;

  const ReferralBoard({
    this.pending = 0,
    this.awaitingDocuments = 0,
    this.assessmentPending = 0,
    this.admittedLast30Days = 0,
  });
}

/// One intake question (`fieldsJson` / `templateSnapshotJson.fields`).
class IntakeField {
  final String key;
  final String label;

  /// `text`, `textarea`, `number`, `date`, `select` or `checkbox`.
  final String type;
  final bool required;
  final List<String> options;

  /// Where the answer carries over on admission; null keeps it on the referral.
  final String? target;

  const IntakeField({
    required this.key,
    required this.label,
    this.type = 'text',
    this.required = false,
    this.options = const [],
    this.target,
  });
}

class IntakeChecklistItem {
  final String key;
  final String label;
  final bool required;
  final bool requiresDocument;

  const IntakeChecklistItem({
    required this.key,
    required this.label,
    this.required = false,
    this.requiresDocument = false,
  });
}

/// `GET /intake-templates`.
class IntakeTemplate {
  final String id;
  final String name;
  final String? provinceOrState;
  final int? version;

  /// Null is treated as in use, like the web.
  final bool? isActive;
  final List<IntakeField> fields;
  final List<IntakeChecklistItem> checklist;

  const IntakeTemplate({
    required this.id,
    required this.name,
    this.provinceOrState,
    this.version,
    this.isActive,
    this.fields = const [],
    this.checklist = const [],
  });

  bool get isRetired => isActive == false;
  int get requiredChecklistCount => checklist.where((c) => c.required).length;
}

/// The form as it stood when the referral was taken.
class TemplateSnapshot {
  final String? name;
  final int? version;
  final List<IntakeField> fields;
  final List<IntakeChecklistItem> checklist;

  const TemplateSnapshot({
    this.name,
    this.version,
    this.fields = const [],
    this.checklist = const [],
  });
}

class ReferralAssessment {
  final String id;
  final String summary;
  final String? outcome;
  final DateTime? assessedAt;

  const ReferralAssessment({
    required this.id,
    required this.summary,
    this.outcome,
    this.assessedAt,
  });
}

class ReferralContact {
  final String? id;
  final String name;
  final String? relationship;
  final String? phone;
  final String? email;
  final String? address;
  final bool isPrimaryGuardian;
  final bool isEmergencyContact;

  const ReferralContact({
    this.id,
    required this.name,
    this.relationship,
    this.phone,
    this.email,
    this.address,
    this.isPrimaryGuardian = false,
    this.isEmergencyContact = false,
  });
}

class ReferralEvent {
  final String id;
  final String event;
  final String? fromStatus;
  final String? toStatus;
  final String? note;
  final DateTime? createdAt;
  final String? actorName;

  const ReferralEvent({
    required this.id,
    required this.event,
    this.fromStatus,
    this.toStatus,
    this.note,
    this.createdAt,
    this.actorName,
  });
}

class ReferralDocument {
  final String id;
  final String name;
  final String fileUrl;
  final String? checklistKey;

  const ReferralDocument({
    required this.id,
    required this.name,
    required this.fileUrl,
    this.checklistKey,
  });
}

/// `GET /referrals` row and `GET /referrals/:id` detail.
class Referral {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? source;
  final String? admissionType;
  final DateTime? expectedAdmissionDate;
  final String? reasonForAdmission;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? notes;
  final String status;
  final int? priority;
  final String? preferredResidenceId;
  final TemplateSnapshot? snapshot;
  final Map<String, dynamic> payload;
  final List<String> completedChecklist;
  final DateTime? waitlistedAt;
  final String? closedReason;
  final List<ReferralAssessment> assessments;
  final List<ReferralContact> contacts;
  final List<ReferralEvent> events;
  final List<ReferralDocument> documents;
  final DateTime? createdAt;

  const Referral({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.dateOfBirth,
    this.source,
    this.admissionType,
    this.expectedAdmissionDate,
    this.reasonForAdmission,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.notes,
    this.priority,
    this.preferredResidenceId,
    this.snapshot,
    this.payload = const {},
    this.completedChecklist = const [],
    this.waitlistedAt,
    this.closedReason,
    this.assessments = const [],
    this.contacts = const [],
    this.events = const [],
    this.documents = const [],
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  bool get isClosed => closedReferralStatuses.contains(status);

  List<IntakeChecklistItem> get checklist => snapshot?.checklist ?? const [];

  /// Required checklist items not yet ticked; any of them blocks admission.
  List<IntakeChecklistItem> get outstanding => [
        for (final item in checklist)
          if (item.required && !completedChecklist.contains(item.key)) item,
      ];

  ReferralDocument? documentFor(String checklistKey) =>
      documents.where((d) => d.checklistKey == checklistKey).firstOrNull;
}

class ReferralPage {
  final List<Referral> items;
  final int total;
  final int totalPages;

  const ReferralPage({
    required this.items,
    required this.total,
    required this.totalPages,
  });
}

class AdmissionOption {
  final String id;
  final String label;

  const AdmissionOption({required this.id, required this.label});
}

/// `GET /residences/:id/rooms`.
class AdmissionRoom {
  final String id;
  final String name;
  final String? roomType;
  final bool isActive;
  final int available;

  const AdmissionRoom({
    required this.id,
    required this.name,
    this.roomType,
    this.isActive = true,
    this.available = 0,
  });
}
