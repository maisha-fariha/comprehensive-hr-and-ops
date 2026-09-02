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
  final String category;

  const FamilyDocument({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.fileType,
    this.uploadId,
    this.downloadUrl,
    this.category = '',
  });

  String get subtitle => '$dateLabel · ${fileType.label}';
}
