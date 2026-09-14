import '../../../../core/network/json_codec.dart';

/// Formats CIR `payloadJson` answers for UI rows and PDF cells.
class CirAnswerFormatter {
  CirAnswerFormatter._();

  static const empty = '-';

  static String display(
    dynamic raw, {
    String? type,
    List<dynamic>? options,
  }) {
    if (raw == null) return empty;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return empty;
      return _labelForValue(trimmed, options) ?? trimmed;
    }
    if (raw is bool) return raw ? 'Yes' : 'No';
    if (raw is num) return raw.toString();

    if (raw is List) {
      if (raw.isEmpty) return empty;
      final parts = <String>[];
      for (final item in raw) {
        final part = display(item, type: type, options: options);
        if (part != empty) parts.add(part);
      }
      return parts.isEmpty ? empty : parts.join(', ');
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (type == 'signature' ||
          map.containsKey('signedAt') ||
          map.containsKey('imageUrl')) {
        final name = JsonCodec.string(map['name'])?.trim() ?? '';
        final signedAt = JsonCodec.string(map['signedAt'])?.trim() ?? '';
        if (name.isEmpty && signedAt.isEmpty) return empty;
        if (name.isEmpty) return signedAt;
        if (signedAt.isEmpty) return name;
        return '$name (signed $signedAt)';
      }
      // Generic map fallback (e.g. unexpected nested answer).
      final name = JsonCodec.string(map['name'] ?? map['label'] ?? map['value']);
      return (name == null || name.trim().isEmpty) ? empty : name.trim();
    }

    final text = raw.toString().trim();
    return text.isEmpty ? empty : text;
  }

  static String fromPayload({
    required String key,
    required Map<String, dynamic> payload,
    String? type,
    List<dynamic>? options,
  }) {
    return display(payload[key], type: type, options: options);
  }

  static String? _labelForValue(String value, List<dynamic>? options) {
    if (options == null || options.isEmpty) return null;
    final needle = value.trim().toLowerCase();
    for (final option in options) {
      if (option is! Map) {
        if (option.toString().toLowerCase() == needle) {
          return option.toString();
        }
        continue;
      }
      final map = Map<String, dynamic>.from(option);
      final optValue =
          (JsonCodec.string(map['value']) ?? '').trim().toLowerCase();
      final optLabel = JsonCodec.string(map['label']) ?? '';
      if (optValue == needle || optLabel.trim().toLowerCase() == needle) {
        return optLabel.isEmpty ? value : optLabel;
      }
    }
    return null;
  }

  static Map<String, Map<String, dynamic>> partiesTable(
    Map<String, dynamic> payload,
  ) {
    final raw = payload['partiesNotified'];
    if (raw is! Map) return const {};
    final out = <String, Map<String, dynamic>>{};
    raw.forEach((key, value) {
      if (value is Map) {
        out[key.toString()] = Map<String, dynamic>.from(value);
      }
    });
    return out;
  }
}
