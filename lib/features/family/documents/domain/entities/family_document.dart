import 'package:flutter/foundation.dart';

import 'family_document_enums.dart';

/// A single document shared with the family from the "Documents" screen
/// (care plan, appointment summaries, policies, etc.).
@immutable
class FamilyDocument {
  final String id;
  final String title;
  final String dateLabel;
  final FamilyDocumentFileType fileType;
  final String? uploadId;
  final String? downloadUrl;

  /// API-relative file path, e.g. `/files/documents/demo-care-plan.pdf`
  /// or `/files/{tenantId}/{category}/{fileName}`.
  final String? fileUrl;
  final String? fileName;
  final String? tenantId;

  /// `consent_form` or `resident_memory` when the family sent it. Empty for care-home files.
  final String category;
  final String? documentType;
  final bool uploadedByMe;
  final DateTime? updatedAt;
  final bool signatureRequired;
  final DateTime? signatureAcknowledgedAt;
  final DateTime? signatureDueAt;

  const FamilyDocument({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.fileType,
    this.uploadId,
    this.downloadUrl,
    this.fileUrl,
    this.fileName,
    this.tenantId,
    this.category = '',
    this.documentType,
    this.uploadedByMe = false,
    this.updatedAt,
    this.signatureRequired = false,
    this.signatureAcknowledgedAt,
    this.signatureDueAt,
  });

  /// Web type line: category label, otherwise the document type, otherwise General.
  String get kindLabel {
    switch (category) {
      case 'consent_form':
        return 'Consent form';
      case 'resident_memory':
        return 'Memory';
    }
    final type = documentType?.trim();
    if (type != null && type.isNotEmpty) return type;
    return 'General';
  }

  /// Web source badge.
  String get sourceLabel {
    if (uploadedByMe) return 'Sent by you';
    if (category.isNotEmpty) return 'From family';
    return 'From the care home';
  }

  String get subtitle => '$dateLabel · ${fileType.label}';

  String get openFileName {
    final explicit = fileName?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final fromUrl = fileUrl ?? downloadUrl;
    if (fromUrl != null && fromUrl.isNotEmpty) {
      final path = Uri.tryParse(fromUrl)?.path ?? fromUrl;
      final parts = path.split('/').where((part) => part.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.last;
    }
    final extension = fileType == FamilyDocumentFileType.jpg ? 'jpg' : 'pdf';
    return '${title.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')}.$extension';
  }
}

/// Bytes + metadata returned when opening a family document.
@immutable
class FamilyDocumentOpenPayload {
  final List<int> bytes;
  final String fileName;
  final String mimeType;

  const FamilyDocumentOpenPayload({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });
}
