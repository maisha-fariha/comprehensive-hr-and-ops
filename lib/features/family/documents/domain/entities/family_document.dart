import 'package:flutter/foundation.dart';

import 'family_document_enums.dart';

/// A single document shared with the family from the "Documents" screen
/// (care plan, appointment summary, policy, etc.).
@immutable
class FamilyDocument {
  final String id;
  final String title;

  /// Pre-formatted date portion of the subtext line, e.g.
  /// "Updated May 10, 2025" or just "May 2025" (see the reference
  /// screenshot: only some rows carry the "Updated" prefix).
  final String dateLabel;
  final FamilyDocumentFileType fileType;

  const FamilyDocument({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.fileType,
  });

  /// Full subtext line rendered under the title, e.g.
  /// "Updated May 10, 2025 · PDF".
  String get subtitle => '$dateLabel · ${fileType.label}';
}
