import '../network/json_codec.dart';
import '../network/response_cache.dart';

/// A saved request shape learned from one opened record, e.g.
/// `/conversations/{id}/messages`, so the same view can be saved for every
/// record in the `/conversations` list.
class DetailTemplate {
  final String collection;
  final String suffix;
  final Map<String, String> query;

  const DetailTemplate({
    required this.collection,
    required this.suffix,
    required this.query,
  });

  String pathFor(String id) => '$collection/$id$suffix';

  String get key {
    final q = query.entries.map((e) => '${e.key}=${e.value}').toList()..sort();
    return '$collection/{id}$suffix?${q.join('&')}';
  }
}

/// Works out what to download so screens opened before keep working offline:
/// saved requests to refresh, and per-record requests learned from them.
/// Only plans GETs; [OfflinePrewarmer] runs them.
abstract final class OfflineCrawler {
  static final RegExp _date = RegExp(r'^\d{4}-\d{2}-\d{2}');
  static final RegExp _idSegment =
      RegExp(r'^(\d+|(?=[A-Za-z0-9_-]*\d)[A-Za-z0-9_-]{8,})$');

  static final RegExp _linkSegment = RegExp(r'[/-]link(/|$)');

  static const Set<String> _searchKeys = {'search', 'q', 'query', 'keyword'};

  /// Paths that are links, files, exports or searches: never replayed.
  static bool skipPath(String path) {
    final p = path.toLowerCase();
    return _linkSegment.hasMatch(p) ||
        p.contains('download') ||
        p.contains('.pdf') ||
        p.contains('export') ||
        p.contains('.csv') ||
        p.startsWith('/files/') ||
        p.contains('/search') ||
        p.contains('/public/') ||
        p.contains('/auth/') ||
        p.contains('offline-');
  }

  static bool _isSearch(Map<String, String> query) => query.entries
      .any((e) => _searchKeys.contains(e.key.toLowerCase()) && e.value.isNotEmpty);

  static bool isIdSegment(String segment) =>
      !_date.hasMatch(segment) &&
      !segment.startsWith('offline-') &&
      _idSegment.hasMatch(segment);

  /// Saved requests worth refreshing now, most recently used first.
  /// Requests with dates are only refreshed on the day they were made (a
  /// later screen asks for a new window, which the main pre-load covers).
  static List<CachedRequest> refreshPlan(
    List<CachedRequest> saved, {
    required DateTime now,
    Duration freshFor = const Duration(minutes: 10),
    int limit = 150,
  }) {
    final plan = saved.where((r) {
      if (skipPath(r.path) || _isSearch(r.query)) return false;
      if (now.difference(r.savedAt) < freshFor) return false;
      if (r.hasTimeParams && !_sameDay(r.savedAt, now)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.lastAccess.compareTo(a.lastAccess));
    return plan.take(limit).toList();
  }

  /// One template per saved per-record request with exactly one id segment.
  static List<DetailTemplate> templates(List<CachedRequest> saved) {
    final byKey = <String, DetailTemplate>{};
    for (final r in saved) {
      if (r.hasTimeParams || skipPath(r.path) || _isSearch(r.query)) continue;
      final segments = r.path.split('/').where((s) => s.isNotEmpty).toList();
      final ids = [
        for (var i = 0; i < segments.length; i++)
          if (isIdSegment(segments[i])) i,
      ];
      if (ids.length != 1 || ids.single == 0) continue;
      final at = ids.single;
      final template = DetailTemplate(
        collection: '/${segments.take(at).join('/')}',
        suffix: at + 1 < segments.length
            ? '/${segments.skip(at + 1).join('/')}'
            : '',
        query: r.query,
      );
      byKey[template.key] = template;
    }
    return byKey.values.toList();
  }

  /// Record ids in a saved list response.
  static List<String> idsIn(dynamic listBody) {
    final ids = <String>[];
    for (final raw in JsonCodec.unwrapList(listBody)) {
      if (raw is! Map) continue;
      final id = '${raw['id'] ?? ''}'.trim();
      if (id.isNotEmpty && isIdSegment(id) && !ids.contains(id)) ids.add(id);
    }
    return ids;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
