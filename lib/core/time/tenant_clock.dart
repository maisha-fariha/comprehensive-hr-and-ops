import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Wall-clock times for the organisation, matching the web tenant timezone.
///
/// The web converts a date and a time-of-day in the tenant zone (for this
/// home, America/Vancouver) into a UTC instant. A phone set to another zone
/// must do the same, or a bidding deadline that is still in the future at
/// the home is sent as already past.
abstract final class TenantClock {
  static String? timeZone;
  static bool _ready = false;

  /// [iana] empty or unknown falls back to the device zone.
  static void use(String? iana) {
    final name = iana?.trim();
    if (name == null || name.isEmpty) {
      timeZone = null;
      return;
    }
    _ensure();
    try {
      tz.getLocation(name);
      timeZone = name;
    } catch (_) {
      timeZone = null;
    }
  }

  static void _ensure() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  /// [date]'s calendar day plus [minutes] after midnight, in the tenant zone.
  static DateTime at(DateTime date, int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final zone = timeZone;
    if (zone == null) {
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
    _ensure();
    return tz.TZDateTime(
      tz.getLocation(zone),
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  /// Calendar parts of [instant] as the home shows them.
  ///
  /// The returned value is only a carrier for year/month/day/hour/minute.
  /// Callers must not convert it again.
  static DateTime wallOf(DateTime instant) {
    final zone = timeZone;
    if (zone == null) return instant.toLocal();
    _ensure();
    final zoned = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
    return DateTime(zoned.year, zoned.month, zoned.day, zoned.hour, zoned.minute);
  }
}
