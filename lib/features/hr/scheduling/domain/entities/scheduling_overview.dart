import 'package:flutter/foundation.dart';

import 'board_overview.dart';
import 'calendar_schedule.dart';
import 'requests_overview.dart';

/// Aggregate root for everything shown on the Manager "Scheduling" screen
/// (its 3 segmented tabs: Calendar, Board and Requests).
@immutable
class SchedulingOverview {
  final CalendarSchedule calendar;
  final BoardOverview board;
  final RequestsOverview requests;

  const SchedulingOverview({
    required this.calendar,
    required this.board,
    required this.requests,
  });
}
