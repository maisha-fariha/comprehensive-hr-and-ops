import 'package:flutter/foundation.dart';

import 'team_reports_enums.dart';

/// A single card in the Reports tab's "Available Reports" list.
@immutable
class AvailableReportItem {
  final String id;
  final ReportTypeTag tag;
  final String title;
  final String categoryLabel;
  final String updatedLabel;

  const AvailableReportItem({
    required this.id,
    required this.tag,
    required this.title,
    required this.categoryLabel,
    required this.updatedLabel,
  });
}
