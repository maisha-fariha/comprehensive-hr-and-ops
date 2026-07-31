import 'package:flutter/foundation.dart';

/// A single card in the "Late" tab's "Late Arrivals" list.
@immutable
class LateArrivalEntry {
  final String id;
  final String name;
  final String role;
  final int avatarPaletteIndex;

  /// e.g. "18 min late".
  final String lateLabel;

  /// e.g. "7:00 AM – 3:00 PM".
  final String scheduledRange;

  /// e.g. "7:18 AM".
  final String clockedInTime;

  /// e.g. "On Site · 350 ft".
  final String distanceLabel;

  const LateArrivalEntry({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarPaletteIndex,
    required this.lateLabel,
    required this.scheduledRange,
    required this.clockedInTime,
    required this.distanceLabel,
  });
}
