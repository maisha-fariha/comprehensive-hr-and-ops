/// Defensive JSON helpers for the tenant API envelope (`{ data, meta, message }`)
/// and for loosely typed numeric/string fields.
abstract final class JsonCodec {
  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  /// Unwrap `{ data: ... }` when present; otherwise return [body] as-is.
  static dynamic unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  static Map<String, dynamic> unwrapMap(dynamic body) => asMap(unwrap(body));

  static List<dynamic> unwrapList(dynamic body) {
    final data = unwrap(body);
    if (data is List) return data;
    if (data is Map) {
      final map = asMap(data);
      for (final key in const [
        'items',
        'results',
        'rows',
        'records',
        'entries',
        'logs',
        'messages',
        'activity',
        'alerts',
        'linkedClients',
        'documents',
        'appointments',
      ]) {
        final nested = map[key];
        if (nested is List) return nested;
      }
    }
    return const [];
  }

  static Map<String, dynamic>? metaOf(dynamic body) {
    if (body is Map && body['meta'] is Map) return asMap(body['meta']);
    final data = unwrap(body);
    if (data is Map && data['meta'] is Map) return asMap(data['meta']);
    return null;
  }

  static String? string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String stringOr(dynamic value, String fallback) =>
      string(value) ?? fallback;

  static int? integer(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int integerOr(dynamic value, int fallback) =>
      integer(value) ?? fallback;

  static num? number(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  static bool? boolean(dynamic value) {
    if (value is bool) return value;
    if (value == null) return null;
    final text = value.toString().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }

  static DateTime? dateTime(dynamic value) {
    final text = string(value);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }

  static Map<String, dynamic>? mapAt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    return asMap(value);
  }

  static List<dynamic> listAt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is List) return value;
    return const [];
  }

  const JsonCodec._();
}
