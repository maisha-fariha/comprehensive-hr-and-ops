import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:get/get.dart';

import '../network/api_endpoints.dart';
import '../network/app_api_client.dart';
import '../network/json_codec.dart';
import '../roles/user_session.dart';

/// Wall-clock times for the organisation, matching Settings → General timezone.
///
/// The web converts a date and a time-of-day in the tenant zone into a UTC
/// instant. A phone set to another zone must do the same, or deadlines and
/// displayed times disagree with the home.
abstract final class TenantClock {
  static String? timeZone;
  static String dateFormat = 'DD/MM/YYYY';
  static String timeFormat = '12h';
  /// Settings → General `logoUrl` (web sidebar brand image).
  static String? logoUrl;
  /// Settings → General `platformName` when set (else tenant name from session).
  static String? platformName;
  static bool _ready = false;
  static Future<void>? _loading;
  static int _syncGeneration = 0;

  /// True when Settings → General uses 24-hour clocks for every role.
  static bool get is24Hour => timeFormat == '24h';

  /// [iana] empty or unknown falls back to the device zone.
  static void use(
    String? iana, {
    String? dateFmt,
    String? timeFmt,
  }) {
    final name = iana?.trim();
    if (name == null || name.isEmpty) {
      timeZone = null;
      dateFormat = 'DD/MM/YYYY';
      timeFormat = '12h';
      // Keep logo/platformName across timezone clears from incomplete payloads.
    } else {
      _ensure();
      try {
        tz.getLocation(name);
        timeZone = name;
      } catch (_) {
        timeZone = null;
      }
    }
    if (dateFmt != null && dateFmt.trim().isNotEmpty) {
      dateFormat = dateFmt.trim();
    }
    if (timeFmt != null && timeFmt.trim().isNotEmpty) {
      timeFormat = _normalizeTimeFormat(timeFmt);
    }
  }

  /// Web/API may send `12h`, `12-hour`, `24h`, or `24-hour`.
  static String _normalizeTimeFormat(String raw) {
    final v = raw.trim().toLowerCase().replaceAll(' ', '');
    if (v.startsWith('24')) return '24h';
    return '12h';
  }

  /// Loads `GET /settings/general`.
  ///
  /// Without [force], reuses a successful in-memory zone. Pass [force] on
  /// schedule/attendance loads so admin Settings → General changes apply
  /// without requiring sign-out.
  static Future<void> syncFromApi(
    AppApiClient api, {
    bool force = false,
  }) {
    if (!force && timeZone != null) {
      return _loading ?? Future.value();
    }
    if (!force && _loading != null) return _loading!;

    final generation = ++_syncGeneration;
    late final Future<void> next;
    next = _sync(api, generation).whenComplete(() {
      if (identical(_loading, next)) _loading = null;
    });
    _loading = next;
    return next;
  }

  static Future<void> _sync(AppApiClient api, int generation) async {
    final result = await api.get(ApiEndpoints.settingsGeneral, silent: true);
    // A newer force-sync started while this one was in flight — drop this
    // response so an older timezone cannot overwrite the latest.
    if (generation != _syncGeneration) return;
    result.when(
      success: (body) {
        if (generation != _syncGeneration) return;
        final json = JsonCodec.unwrapMap(body);
        // Nested `general` (from GET /settings) or flat /settings/general.
        final general = JsonCodec.mapAt(json, 'general') ?? json;
        use(
          JsonCodec.string(general['timezone']),
          dateFmt: JsonCodec.string(general['dateFormat']),
          timeFmt: JsonCodec.string(general['timeFormat']),
        );
        final nextLogo = JsonCodec.string(general['logoUrl'])?.trim();
        logoUrl = (nextLogo == null || nextLogo.isEmpty) ? null : nextLogo;
        final nextPlatform = JsonCodec.string(general['platformName'])?.trim();
        platformName =
            (nextPlatform == null || nextPlatform.isEmpty) ? null : nextPlatform;
        if (Get.isRegistered<UserSession>()) {
          Get.find<UserSession>().applyOrgBranding(
            name: platformName,
            logoUrl: logoUrl,
          );
        }
      },
      failure: (_) {},
    );
  }

  static void _ensure() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  /// Current wall clock in the tenant zone (date/time parts only).
  static DateTime now() {
    final zone = timeZone;
    if (zone == null) return DateTime.now();
    _ensure();
    final zoned = tz.TZDateTime.now(tz.getLocation(zone));
    return DateTime(
      zoned.year,
      zoned.month,
      zoned.day,
      zoned.hour,
      zoned.minute,
      zoned.second,
      zoned.millisecond,
    );
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
    return DateTime(
      zoned.year,
      zoned.month,
      zoned.day,
      zoned.hour,
      zoned.minute,
      zoned.second,
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Date as Settings → General date format (default `DD/MM/YYYY`).
  static String formatDate(DateTime? instant) {
    if (instant == null) return '—';
    final w = wallOf(instant);
    return switch (dateFormat) {
      'MM/DD/YYYY' => '${_two(w.month)}/${_two(w.day)}/${w.year}',
      'YYYY-MM-DD' => '${w.year}-${_two(w.month)}-${_two(w.day)}',
      _ => '${_two(w.day)}/${_two(w.month)}/${w.year}',
    };
  }

  /// Time as Settings → General time format (`12h` / `24h`).
  static String formatTime(DateTime? instant) {
    if (instant == null) return '—';
    final w = wallOf(instant);
    return formatClock(hour: w.hour, minute: w.minute);
  }

  /// Wall-clock parts already in the tenant zone (no further conversion).
  ///
  /// Use for shift start/end minutes, TimeOfDay pickers, and other values that
  /// are already organisation-local — every role must share this path so the
  /// app never mixes 12h and 24h against Settings → General.
  static String formatClock({required int hour, required int minute}) {
    final h = hour.clamp(0, 23);
    final m = minute.clamp(0, 59);
    if (is24Hour) {
      return '${_two(h)}:${_two(m)}';
    }
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final ampm = h >= 12 ? 'pm' : 'am';
    return '$h12:${_two(m)} $ampm';
  }

  /// Minutes after midnight in the tenant zone → Settings → General time.
  static String formatMinutes(int? minutesAfterMidnight) {
    if (minutesAfterMidnight == null) return '—';
    final minutes = minutesAfterMidnight % (24 * 60);
    return formatClock(hour: minutes ~/ 60, minute: minutes % 60);
  }

  /// `date time` using tenant formats.
  static String formatDateTime(DateTime? instant) {
    if (instant == null) return '—';
    return '${formatDate(instant)} ${formatTime(instant)}';
  }
}
