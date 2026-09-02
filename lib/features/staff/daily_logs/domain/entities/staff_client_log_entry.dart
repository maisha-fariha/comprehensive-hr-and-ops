import 'package:flutter/foundation.dart';

import 'staff_daily_logs_enums.dart';

/// A single client row/card shown on any of the 3 Daily Logs tabs (My
/// Clients / In Progress / Submitted). The same shape is reused across all
/// three tabs since their rows share an identical visual structure (avatar,
/// eyebrow shift label, name, subtitle line, trailing status pill) per the
/// reference screenshots.
@immutable
class StaffClientLogEntry {
  final String id;
  final String initials;

  /// Small caps eyebrow label above the name, e.g. "Morning Shift".
  final String shiftLabel;
  final String clientName;

  /// Subtitle caption shown next to a clock/status glyph, e.g. "7:00 AM",
  /// "Submitted 7:15 AM" or "Updated 8:42 AM".
  final String subtitleLabel;
  final ClientLogStatus status;

  /// Client identity details carried forward to the "Daily Note" screen
  /// when this row is tapped.
  final String dobLabel;
  final String roomLabel;
  final String clientId;
  final String? residenceId;
  final String? entryId;

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
  });
}
