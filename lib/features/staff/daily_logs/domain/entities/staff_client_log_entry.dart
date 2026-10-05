import 'package:flutter/foundation.dart';

import 'staff_daily_logs_enums.dart';

/// A client/log row for To review, Missing, or day-view lists.
@immutable
class StaffClientLogEntry {
  final String id;
  final String initials;
  final String shiftLabel;
  final String clientName;
  final String subtitleLabel;
  final ClientLogStatus status;
  final String dobLabel;
  final String roomLabel;
  final String clientId;
  final String? residenceId;
  final String? entryId;
  final String? logDateIso;
  final int entriesCount;

  const StaffClientLogEntry({
    required this.id,
    required this.initials,
    required this.shiftLabel,
    required this.clientName,
    required this.subtitleLabel,
    required this.status,
    required this.dobLabel,
    required this.roomLabel,
    this.clientId = '',
    this.residenceId,
    this.entryId,
    this.logDateIso,
    this.entriesCount = 0,
  });
}
