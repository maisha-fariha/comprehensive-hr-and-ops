import 'package:flutter/foundation.dart';

import 'team_reports_enums.dart';

/// A single row in the Team tab's "Top Reports" list.
@immutable
class TopReportItem {
  final String id;
  final ReportTypeTag tag;
  final String title;
  final String dateLabel;

  const TopReportItem({
    required this.id,
    required this.tag,
    required this.title,
    required this.dateLabel,
  });
}
