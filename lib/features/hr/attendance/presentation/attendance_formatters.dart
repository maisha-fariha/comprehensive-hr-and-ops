import '../domain/entities/attendance_record.dart';

/// Display rules of the web Attendance table, in device local time.
abstract final class AttendanceFormat {
  static String two(int n) => n.toString().padLeft(2, '0');

  /// `dd/MM/yyyy`.
  static String date(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  /// `HH:mm`.
  static String time(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${two(local.hour)}:${two(local.minute)}';
  }

  /// `yyyy-MM-dd HH:mm`, as the web wizard's review panels print times.
  static String wallClock(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  /// "pending_approval" -> "Pending approval".
  static String humanise(String? value) {
    if (value == null || value.isEmpty) return '';
    final words = value.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return words[0].toUpperCase() + words.substring(1).toLowerCase();
  }

  /// Worked column: "8h", "7h 25m", "—".
  static String worked(int? minutes) {
    if (minutes == null) return '—';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  /// Wizard durations: "7h 25m", "45m", "—".
  static String span(int? minutes) {
    if (minutes == null || minutes < 0) return '—';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return hours > 0 ? '${hours}h ${rest}m' : '${rest}m';
  }

  static String inOut(AttendanceRecord record) =>
      '${time(record.checkInAt)} – '
      '${record.checkOutAt == null ? 'Still in' : time(record.checkOutAt)}';

  static String? exceptionLine(AttendanceRecord record) {
    final parts = <String>[
      if (record.lateMinutes != null) '${record.lateMinutes}m late',
      if (record.earlyDepartureMinutes != null)
        'left ${record.earlyDepartureMinutes}m early'
            '${record.earlyDepartureReason == null ? '' : ' · ${humanise(record.earlyDepartureReason)}'}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String where(AttendanceCheckpoint checkIn) {
    final distance =
        checkIn.distanceMeters == null ? '' : ' · ${checkIn.distanceMeters} m';
    return switch (checkIn.geofenceStatus) {
      'inside' => 'On site$distance',
      'outside' => 'Outside$distance',
      'not_configured' => 'No fence set',
      _ => 'No location',
    };
  }
}
