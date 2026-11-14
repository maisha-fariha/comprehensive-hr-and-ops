import 'package:flutter/foundation.dart';

/// One row of `GET /documents` (the registry merges `staff_document`
/// certificates into the same list).
@immutable
class HrDocument {
  final String id;
  final String name;
  final String? documentTypeId;
  final String? fileUrl;
  final String? ownerType;
  final String? ownerId;
  final DateTime? expiresAt;
  final String? status;
  final String? visibility;
  final String? notes;
  final String? uploadedBy;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final String source;
  final bool ackRequired;
  final String? signingMode;
  final bool signingHeld;
  final DateTime? ackDueAt;
  final DateTime? ackRequestedAt;
  final bool myAckRequired;
  final DateTime? myAcknowledgedAt;
  final DateTime? myAckDueAt;

  const HrDocument({
    required this.id,
    required this.name,
    this.documentTypeId,
    this.fileUrl,
    this.ownerType,
    this.ownerId,
    this.expiresAt,
    this.status,
    this.visibility,
    this.notes,
    this.uploadedBy,
    this.deletedAt,
    this.createdAt,
    this.source = 'document',
    this.ackRequired = false,
    this.signingMode,
    this.signingHeld = false,
    this.ackDueAt,
    this.ackRequestedAt,
    this.myAckRequired = false,
    this.myAcknowledgedAt,
    this.myAckDueAt,
  });
}

/// One person in `GET /documents/:id/acknowledgments`.
@immutable
class HrAckPerson {
  final String userId;
  final String name;
  final String? email;
  final DateTime? acknowledgedAt;
  final bool overdue;

  const HrAckPerson({
    required this.userId,
    required this.name,
    this.email,
    this.acknowledgedAt,
    this.overdue = false,
  });

  bool get signed => acknowledgedAt != null;
}

/// Progress payload from `GET /documents/:id/acknowledgments`.
@immutable
class HrAcknowledgmentProgress {
  final String documentId;
  final String name;
  final int version;
  final String? mode;
  final bool held;
  final DateTime? dueAt;
  final DateTime? requestedAt;
  final int required;
  final int acknowledged;
  final int pending;
  final int overdue;
  final List<HrAckPerson> people;

  const HrAcknowledgmentProgress({
    required this.documentId,
    required this.name,
    this.version = 1,
    this.mode,
    this.held = false,
    this.dueAt,
    this.requestedAt,
    this.required = 0,
    this.acknowledged = 0,
    this.pending = 0,
    this.overdue = 0,
    this.people = const [],
  });
}

/// Role or user option for the Send for signing audience pickers.
@immutable
class HrSignOption {
  final String id;
  final String label;

  const HrSignOption({required this.id, required this.label});
}

@immutable
class HrDocumentPage {
  final List<HrDocument> items;
  final int total;
  final int totalPages;

  const HrDocumentPage({
    this.items = const [],
    this.total = 0,
    this.totalPages = 0,
  });
}

@immutable
class HrDocumentType {
  final String id;
  final String name;
  final String? appliesTo;
  final bool isMandatory;
  final bool isActive;

  const HrDocumentType({
    required this.id,
    required this.name,
    this.appliesTo,
    this.isMandatory = false,
    this.isActive = true,
  });
}

@immutable
class HrMissingGap {
  final String documentTypeId;
  final String name;
  final String? appliesTo;
  final int owners;
  final int filed;
  final int missing;

  const HrMissingGap({
    required this.documentTypeId,
    required this.name,
    this.appliesTo,
    required this.owners,
    required this.filed,
    required this.missing,
  });
}

@immutable
class HrCategorySlice {
  final String? documentTypeId;
  final String name;
  final int count;

  const HrCategorySlice({
    this.documentTypeId,
    required this.name,
    required this.count,
  });
}

/// `GET /documents/summary` — computed for the same filters as the list.
@immutable
class HrDocumentsSummary {
  final int documents;
  final int expiringSoon;
  final int expired;
  final int restricted;
  final int addedLast30Days;
  final int missingMandatory;
  final List<HrMissingGap> missingByType;
  final List<HrCategorySlice> byType;

  const HrDocumentsSummary({
    this.documents = 0,
    this.expiringSoon = 0,
    this.expired = 0,
    this.restricted = 0,
    this.addedLast30Days = 0,
    this.missingMandatory = 0,
    this.missingByType = const [],
    this.byType = const [],
  });
}

/// A record a document can be filed against (resident, staff member or
/// residence).
@immutable
class HrDocumentOwner {
  final String id;
  final String name;

  const HrDocumentOwner({required this.id, required this.name});
}

/// Registry filters; empty strings mean "any".
@immutable
class HrDocumentFilters {
  final String search;
  final String ownerType;
  final String documentTypeId;
  final String status;
  final String visibility;
  final bool includeDeleted;

  const HrDocumentFilters({
    this.search = '',
    this.ownerType = '',
    this.documentTypeId = '',
    this.status = '',
    this.visibility = '',
    this.includeDeleted = false,
  });

  Map<String, dynamic> toQuery() => {
        if (ownerType.isNotEmpty) 'ownerType': ownerType,
        if (documentTypeId.isNotEmpty) 'documentTypeId': documentTypeId,
        if (status.isNotEmpty) 'status': status,
        if (visibility.isNotEmpty) 'visibility': visibility,
        if (search.isNotEmpty) 'search': search,
        if (includeDeleted) 'includeDeleted': true,
      };
}

/// A downloaded stored file.
@immutable
class HrDocumentFile {
  final List<int> bytes;
  final String fileName;

  const HrDocumentFile({required this.bytes, required this.fileName});
}

/// A file chosen on the device for upload.
@immutable
class HrPickedFile {
  final String path;
  final String name;
  final int size;

  const HrPickedFile({required this.path, required this.name, this.size = 0});
}
