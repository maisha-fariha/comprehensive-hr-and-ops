import 'package:get_it/get_it.dart';

import '../time/canadian_holidays.dart';
import 'app_api_client.dart';
import 'json_codec.dart';

/// One day from the web's `GET /holidays?from&to&residenceId`.
class Holiday {
  final String date;
  final String name;
  final bool statutory;
  final List<String> provinces;

  const Holiday({
    required this.date,
    required this.name,
    this.statutory = true,
    this.provinces = const [],
  });
}

/// Public holidays for the Scheduling and Appointments calendars. Uses the
/// same endpoint as the web (province comes from the residence); falls back
/// to the built-in Canadian calendar when the call fails.
abstract final class HolidaysService {
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Future<Map<String, Holiday>> fetch({
    required DateTime from,
    required DateTime to,
    String? residenceId,
    String? fallbackProvince,
  }) async {
    final out = <String, Holiday>{};
    try {
      final result = await GetIt.instance<AppApiClient>().get(
        '/holidays',
        query: {
          'from': key(from),
          'to': key(to),
          if (residenceId != null && residenceId.isNotEmpty)
            'residenceId': residenceId,
        },
        silent: true,
      );
      result.when(
        success: (body) {
          final map = JsonCodec.unwrapMap(body);
          final rows = map['holidays'] is List
              ? map['holidays'] as List
              : JsonCodec.unwrapList(body);
          for (final row in rows.whereType<Map>()) {
            final m = JsonCodec.asMap(row);
            final date = JsonCodec.string(m['date']) ?? '';
            final name = JsonCodec.string(m['name']) ?? '';
            if (date.length < 10 || name.isEmpty) continue;
            final provinces = <String>[
              for (final p in (m['provinces'] as List? ?? const []))
                if (p is Map) JsonCodec.string(p['code']) ?? '',
            ]..removeWhere((c) => c.isEmpty);
            out[date.substring(0, 10)] = Holiday(
              date: date.substring(0, 10),
              name: name,
              statutory: JsonCodec.boolean(m['statutory']) ?? true,
              provinces: provinces,
            );
          }
        },
        failure: (_) {},
      );
    } catch (_) {}
    if (out.isNotEmpty) return out;
    // Offline / endpoint unavailable: built-in calendar.
    var day = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!day.isAfter(end)) {
      final name = CanadianHolidays.on(day, province: fallbackProvince);
      if (name != null) {
        out[key(day)] = Holiday(date: key(day), name: name);
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return out;
  }
}
