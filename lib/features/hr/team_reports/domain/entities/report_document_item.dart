import 'package:flutter/foundation.dart';

/// Document list row for the Reports tab Documents section.
@immutable
class ReportDocumentItem {
  final String id;
  final String title;
  final String statusLabel;
  final String? updatedLabel;

  const ReportDocumentItem({
    required this.id,
    required this.title,
    required this.statusLabel,
    this.updatedLabel,
  });
}

@immutable
class ReportDocumentsSummary {
  final int total;
  final int expiringSoon;
  final int expired;
  final int missingMandatory;

  const ReportDocumentsSummary({
    required this.total,
    required this.expiringSoon,
    required this.expired,
    required this.missingMandatory,
  });
}
