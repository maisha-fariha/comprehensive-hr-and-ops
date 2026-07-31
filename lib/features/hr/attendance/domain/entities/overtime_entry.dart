import 'package:flutter/foundation.dart';

import 'attendance_enums.dart';

/// A single card in the "OT" tab's "Overtime Tracking" list.
@immutable
class OvertimeEntry {
  final String id;
  final String name;

  /// e.g. "RN · 7:00 AM – 3:00 PM".
  final String roleShiftLabel;
  final int avatarPaletteIndex;
  final OvertimeStatus status;

  /// e.g. "2h 30m".
  final String otTodayLabel;

  /// e.g. "46.5h".
  final String weeklyTotalLabel;

  /// 0.0 - 1.0 fill fraction of the weekly-limit progress bar.
  final double progress;

  /// e.g. "Limit 48h · exceeded".
  final String limitCaption;

  const OvertimeEntry({
    required this.id,
    required this.name,
    required this.roleShiftLabel,
    required this.avatarPaletteIndex,
    required this.status,
    required this.otTodayLabel,
    required this.weeklyTotalLabel,
    required this.progress,
    required this.limitCaption,
  });
}
