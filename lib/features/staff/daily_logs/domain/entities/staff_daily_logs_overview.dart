import 'package:flutter/foundation.dart';

import 'staff_client_log_entry.dart';
import 'staff_daily_log_summary_stat.dart';

/// Aggregate root for everything shown on the Staff "Daily Logs" screen,
/// across all three of its tabs (My Clients / In Progress / Submitted).
///
/// The 3 summary stat tiles are shared/identical across every tab per the
/// reference screenshots, so - unlike the Manager Daily Logs feature - only
/// a single [stats] list is needed here.
@immutable
class StaffDailyLogsOverview {
  final List<StaffDailyLogSummaryStat> stats;

  // My Clients tab
  final List<StaffClientLogEntry> myClients;

  /// Total client count shown in the "My Clients" section's "N total"
  /// trailing label. Kept separate from `myClients.length` because the
  /// reference screenshot's list is scrollable/cut-off - the label shows
  /// the full count (8) while only a handful of sample rows are mocked
  /// here.
  final int myClientsTotalCount;

  // In Progress tab
  final List<StaffClientLogEntry> inProgressClients;

  // Submitted tab
  final List<StaffClientLogEntry> submittedClients;
  final int submittedTotalCount;

  const StaffDailyLogsOverview({
    required this.stats,
    required this.myClients,
    required this.myClientsTotalCount,
    required this.inProgressClients,
    required this.submittedClients,
    required this.submittedTotalCount,
  });
}
