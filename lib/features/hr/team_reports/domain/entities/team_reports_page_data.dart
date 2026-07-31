import 'package:flutter/foundation.dart';

import 'messages_tab_overview.dart';
import 'reports_tab_overview.dart';
import 'team_tab_overview.dart';

/// Aggregate root for the whole "Team & Reports" screen: the data behind
/// all three segmented tabs is loaded together in one call, since they
/// share a single header/tab-bar and controller.
@immutable
class TeamReportsPageData {
  final TeamTabOverview team;
  final ReportsTabOverview reports;
  final MessagesTabOverview messages;

  const TeamReportsPageData({
    required this.team,
    required this.reports,
    required this.messages,
  });
}
