import 'package:flutter/foundation.dart';

@immutable
class StaffDocument {
  final String id;
  final String name;
  final String? fileUrl;
  final String ownerType;
  final String? ownerId;
  final String ownerName;
  final String? documentTypeId;
  final String categoryLabel;
  final String status;
  final String visibility;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? notes;
  final String source;

  const StaffDocument({
    required this.id,
    required this.name,
    this.fileUrl,
    required this.ownerType,
    this.ownerId,
    this.ownerName = '',
    this.documentTypeId,
    this.categoryLabel = 'Unclassified',
    this.status = 'valid',
    this.visibility = 'all',
    this.expiresAt,
    this.createdAt,
    this.deletedAt,
    this.notes,
    this.source = 'document',
  });

  bool get isWithdrawn => deletedAt != null;

  String get ownerTypeLabel {
    switch (ownerType) {
      case 'client':
        return 'Resident';
      case 'staff':
        return 'Staff';
      case 'residence':
        return 'Residence';
      case 'tenant':
        return 'Organisation';
      case 'referral':
        return 'Referral';
      default:
        return ownerType;
    }
  }

  String get visibilityLabel {
    switch (visibility) {
      case 'staff_only':
        return 'Staff only';
      case 'management_only':
        return 'Management only';
      case 'family':
        return 'Family';
      case 'all':
        return 'Everyone';
      default:
        return visibility;
    }
  }

  String get statusLabel {
    if (isWithdrawn) return 'Withdrawn';
    switch (status) {
      case 'expiring':
        return 'Expiring soon';
      case 'expired':
        return 'Expired';
      case 'valid':
        return 'In date';
      default:
        return status;
    }
  }

  String get expiryLabel {
    final at = expiresAt;
    if (at == null) return 'No expiry';
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  String get uploadedLabel {
    final at = createdAt;
    if (at == null) return '—';
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }
}

@immutable
class StaffDocumentType {
  final String id;
  final String name;
  final String appliesTo;
  final bool isMandatory;
  final bool isActive;

  const StaffDocumentType({
    required this.id,
    required this.name,
    this.appliesTo = 'general',
    this.isMandatory = false,
    this.isActive = true,
  });

  String get appliesToLabel {
    switch (appliesTo) {
      case 'staff':
        return 'Staff';
      case 'client':
        return 'Residents';
      case 'residence':
        return 'Residences';
      case 'general':
        return 'Anything';
      default:
        return appliesTo;
    }
  }

  String get subtitle {
    final parts = <String>[appliesToLabel];
    if (isMandatory) parts.add('Required');
    if (!isActive) parts.add('Archived');
    return parts.join(' · ');
  }
}

@immutable
class StaffDocumentMissingGap {
  final String documentTypeId;
  final String name;
  final String appliesTo;
  final int owners;
  final int filed;
  final int missing;

  const StaffDocumentMissingGap({
    required this.documentTypeId,
    required this.name,
    required this.appliesTo,
    required this.owners,
    required this.filed,
    required this.missing,
  });

  String get peopleLabel => appliesTo == 'client' ? 'residents' : 'staff';
}

@immutable
class StaffDocumentCategorySlice {
  final String? documentTypeId;
  final String name;
  final int count;

  const StaffDocumentCategorySlice({
    this.documentTypeId,
    required this.name,
    required this.count,
  });
}

@immutable
class StaffDocumentsSummary {
  final int documents;
  final int addedLast30Days;
  final int missingMandatory;
  final int expiringSoon;
  final int expired;
  final int restricted;
  final List<StaffDocumentMissingGap> missingByType;
  final List<StaffDocumentCategorySlice> byType;

  const StaffDocumentsSummary({
    this.documents = 0,
    this.addedLast30Days = 0,
    this.missingMandatory = 0,
    this.expiringSoon = 0,
    this.expired = 0,
    this.restricted = 0,
    this.missingByType = const [],
    this.byType = const [],
  });
}

@immutable
class StaffDocumentsPageResult {
  final List<StaffDocument> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const StaffDocumentsPageResult({
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });
}

@immutable
class StaffDocumentOwnerOption {
  final String id;
  final String label;

  const StaffDocumentOwnerOption({required this.id, required this.label});
}

@immutable
class StaffCreateDocumentInput {
  final String name;
  final String ownerType;
  final String? ownerId;
  final String? documentTypeId;
  final String fileUrl;
  final String visibility;
  final DateTime? expiresAt;
  final String? notes;

  const StaffCreateDocumentInput({
    required this.name,
    required this.ownerType,
    this.ownerId,
    this.documentTypeId,
    required this.fileUrl,
    this.visibility = 'staff_only',
    this.expiresAt,
    this.notes,
  });
}
