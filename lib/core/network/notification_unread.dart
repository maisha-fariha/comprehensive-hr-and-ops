import 'json_codec.dart';

/// Parses the organisation notification **unread** total.
///
/// Never uses `meta.total` — some payloads put the full history count in a
/// field named `unread`, which inflated the Home bell (e.g. 30 → 3665).
abstract final class NotificationUnread {
  /// [pageUnread] = unread rows on the current page (safe fallback).
  static int fromBody(
    dynamic body, {
    required int pageUnread,
  }) {
    final meta = JsonCodec.metaOf(body) ?? const <String, dynamic>{};
    final summary = JsonCodec.mapAt(meta, 'summary') ?? const <String, dynamic>{};
    final total = JsonCodec.integer(meta['total']);

    int? pick(dynamic value) {
      final n = JsonCodec.integer(value);
      if (n == null || n < 0) return null;
      if (total != null && n > total) return null;
      return n;
    }

    // Prefer fields that mean "unread" on web / Postman.
    final explicit = pick(summary['unreadCount']) ??
        pick(meta['unreadCount']) ??
        pick(summary['unread']);
    if (explicit != null) return explicit;

    final alias = pick(meta['unread']);
    // When `unread` equals `total`, the API likely echoed history size.
    if (alias != null && total != null && alias == total && pageUnread < alias) {
      return pageUnread;
    }
    return alias ?? pageUnread;
  }
}
