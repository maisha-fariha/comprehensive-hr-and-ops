import 'package:flutter/foundation.dart';

import 'daily_logs_enums.dart';

/// A single row in the Review tab's "Submitted Logs" list.
@immutable
class SubmittedLogEntry {
  final String id;
  final String initials;
  final String shiftLabel;
  final String staffName;
  final String submittedTimeLabel;
  final LogReviewStatus status;

  const SubmittedLogEntry({
    required this.id,
    required this.initials,
    required this.shiftLabel,
    required this.staffName,
    required this.submittedTimeLabel,
    required this.status,
  });
}
