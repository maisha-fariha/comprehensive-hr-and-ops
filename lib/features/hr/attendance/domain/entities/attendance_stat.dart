import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;

import 'attendance_enums.dart';

/// A single small stat tile shown in the row at the top of every Attendance
/// tab (e.g. "14 On Time", "3 Late Today", "18.5h Total OT Hours").
///
/// Exactly one of [iconAsset]/[iconData] is set: SVG assets are preferred
/// (reused from the Dashboard's icon set) and a Material icon is used only
/// as a temporary stand-in where no matching SVG exists yet.
@immutable
class AttendanceStat {
  final String id;
  final String value;
  final String label;
  final AttendanceStatTone tone;
  final String? iconAsset;
  final IconData? iconData;

  const AttendanceStat({
    required this.id,
    required this.value,
    required this.label,
    required this.tone,
    this.iconAsset,
    this.iconData,
  }) : assert(
          iconAsset != null || iconData != null,
          'AttendanceStat requires either an iconAsset or an iconData fallback.',
        );
}
