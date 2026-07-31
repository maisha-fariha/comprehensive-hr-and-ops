import 'package:flutter/foundation.dart';

import 'family_document.dart';

/// Aggregate root for everything shown on the "Documents" screen.
@immutable
class FamilyDocumentsOverview {
  final String captionText;
  final List<FamilyDocument> documents;

  const FamilyDocumentsOverview({
    required this.captionText,
    required this.documents,
  });
}
