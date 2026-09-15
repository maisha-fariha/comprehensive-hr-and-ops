import 'package:flutter/foundation.dart';

/// Counters from `GET /tasks/stats` for All / Overdue / Due Today / Done chips.
///
/// Mapped from `data.status`: overdue / pending / completed.
/// The "Due Today" chip uses [dueToday] = `status.pending` (matches the
/// `status=pending` list filter), not `data.today.due`.
@immutable
class TaskStats {
  final int all;
  final int overdue;
  /// Pending count from stats (`status.pending`) — shown as "Due Today".
  final int dueToday;
  final int done;

  const TaskStats({
    this.all = 0,
    this.overdue = 0,
    this.dueToday = 0,
    this.done = 0,
  });
}
