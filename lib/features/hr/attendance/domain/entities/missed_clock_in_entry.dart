import 'package:flutter/foundation.dart';

/// A single card in the "Missed" tab's "Missed Clock-Ins" list.
@immutable
class MissedClockInEntry {
  final String id;
  final String name;

  /// e.g. "RN · 7:00 AM – 3:00 PM".
  final String roleShiftLabel;
  final int avatarPaletteIndex;

  /// e.g. "Not recorded", "Shift missed".
  final String reasonLabel;

  const MissedClockInEntry({
    required this.id,
    required this.name,
    required this.roleShiftLabel,
    required this.avatarPaletteIndex,
    required this.reasonLabel,
  });
}
