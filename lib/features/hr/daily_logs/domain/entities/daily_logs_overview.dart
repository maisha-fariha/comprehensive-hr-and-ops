import 'package:flutter/foundation.dart';

import 'client_status_summary.dart';
import 'daily_log_summary_stat.dart';
import 'handover_entry.dart';
import 'missing_log_entry.dart';
import 'submitted_log_entry.dart';

/// Aggregate root for everything shown on the "Daily Logs" screen, across
/// all three of its tabs (Review / Missing / Handover).
@immutable
class DailyLogsOverview {
  // Review tab
  final List<DailyLogSummaryStat> reviewStats;
  final List<SubmittedLogEntry> submittedLogs;

  /// Total submitted-log count shown in the "Submitted Logs" section badge.
  /// Kept separate from `submittedLogs.length` because the reference
  /// screenshot's list is scrollable/cut-off - the badge shows the full
  /// count (12) while only a handful of sample rows are mocked here.
  final int submittedLogsTotalCount;
  final List<ClientStatusSummary> clientStatusSummaries;

  // Missing tab
  final List<DailyLogSummaryStat> missingStats;
  final List<MissingLogEntry> missingLogs;

  // Handover tab
  final List<DailyLogSummaryStat> handoverStats;
  final List<HandoverEntry> handoverEntries;

  const DailyLogsOverview({
    required this.reviewStats,
    required this.submittedLogs,
    required this.submittedLogsTotalCount,
    required this.clientStatusSummaries,
    required this.missingStats,
    required this.missingLogs,
    required this.handoverStats,
    required this.handoverEntries,
  });
}
