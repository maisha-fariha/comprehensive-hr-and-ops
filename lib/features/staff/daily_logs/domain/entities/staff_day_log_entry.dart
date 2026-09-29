import 'package:flutter/foundation.dart';

/// One narrative entry inside a resident's day log.
@immutable
class StaffDayLogEntry {
  final String id;
  final String body;
  final String authorName;
  final String timeLabel;
  final String logType;
  final String? shift;

  const StaffDayLogEntry({
    required this.id,
    required this.body,
    required this.authorName,
    required this.timeLabel,
    this.logType = '',
    this.shift,
  });
}
