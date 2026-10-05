import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive_ce/hive_ce.dart';

import '../offline/offline_config.dart';

/// A cached GET body plus when it was fetched from the server.
class CachedResponse {
  final dynamic body;
  final DateTime savedAt;

  const CachedResponse(this.body, this.savedAt);
}

/// A saved GET request, as listed by [ResponseCache.cachedRequests].
class CachedRequest {
  final String path;
  final Map<String, String> query;
  final DateTime savedAt;
  final DateTime lastAccess;
  final bool hasTimeParams;

  const CachedRequest({
    required this.path,
    required this.query,
    required this.savedAt,
    required this.lastAccess,
    required this.hasTimeParams,
  });
}

class _CacheMeta {
  final String fullKey;
  final DateTime savedAt;
  final int bytes;

  /// Request key without its date/time parameters.
  final String? looseKey;

  /// The date/time parameters that were stripped from [looseKey].
  final Map<String, String> timeParams;
  DateTime lastAccess;

  _CacheMeta(
    this.fullKey,
    this.savedAt,
    this.bytes, {
    this.looseKey,
    this.timeParams = const {},
  }) : lastAccess = savedAt;
}

/// Encrypted JSON GET cache for offline reads.
///
/// Entries are scoped by tenant + user, carry `savedAt` for staleness, and
/// are capped by count and size (least-recently-used evicted first).
///
/// Many screens put "now" or "today" in their query (`from`, `to`, ISO
/// timestamps), so an exact key rarely matches a later visit. When there is
/// no exact copy, [read] falls back to the newest copy of the same request
/// whose other parameters are identical and whose date/time parameters are
/// each within [timeWindowTolerance] — never a different week or residence.
class ResponseCache {
  final BoxBase<String> _values;
  final Box<String> _meta;
  final String Function() _scope;
  final int maxEntries;
  final int maxBytes;

  static const Duration timeWindowTolerance = Duration(hours: 36);

  static const Set<String> _timeKeys = {
    'from',
    'to',
    'start',
    'end',
    'since',
    'until',
    'date',
    'day',
    'startdate',
    'enddate',
    'fromdate',
    'todate',
    'datefrom',
    'dateto',
    'startat',
    'endat',
    'startsat',
    'endsat',
    'weekstart',
    'weekend',
    'scheduledfrom',
    'scheduledto',
    'after',
    'before',
  };

  static final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}');

  final Map<String, _CacheMeta> _index = {};
  final Map<String, Set<String>> _byLooseKey = {};
  int _totalBytes = 0;

  /// `savedAt` of the most recent response served from cache (offline).
  final Rxn<DateTime> lastServedSavedAt = Rxn<DateTime>();

  ResponseCache({
    required BoxBase<String> values,
    required Box<String> meta,
    String Function()? scope,
    this.maxEntries = OfflineConfig.cacheMaxEntries,
    this.maxBytes = OfflineConfig.cacheMaxBytes,
  })  : _values = values,
        _meta = meta,
        _scope = scope ?? (() => '');

  Future<void> ensureReady() async {
    _index.clear();
    _byLooseKey.clear();
    _totalBytes = 0;
    for (final key in _meta.keys) {
      final raw = _meta.get(key);
      if (raw == null) continue;
      try {
        final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
        final meta = _CacheMeta(
          map['k'] as String,
          DateTime.parse(map['s'] as String).toLocal(),
          (map['b'] as num).toInt(),
          looseKey: map['l'] as String?,
          timeParams: (map['t'] as Map?)?.map(
                (k, v) => MapEntry('$k', '$v'),
              ) ??
              const {},
        );
        _addToIndex('$key', meta);
      } catch (_) {}
    }
  }

  void _addToIndex(String key, _CacheMeta meta) {
    _index[key] = meta;
    _totalBytes += meta.bytes;
    final loose = meta.looseKey;
    if (loose != null) (_byLooseKey[loose] ??= {}).add(key);
  }

  void _removeFromIndex(String key) {
    final meta = _index.remove(key);
    if (meta == null) return;
    _totalBytes -= meta.bytes;
    final loose = meta.looseKey;
    if (loose == null) return;
    final keys = _byLooseKey[loose];
    keys?.remove(key);
    if (keys != null && keys.isEmpty) _byLooseKey.remove(loose);
  }

  static bool _isTimeParam(String key, Object? value) {
    if (_timeKeys.contains(key.toLowerCase())) return true;
    return value is String && _isoDate.hasMatch(value);
  }

  String _fullKey(String method, String path, Map<String, dynamic>? query) {
    final parts = (query ?? {}).entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .toList()
      ..sort();
    return '${_scope()}|$method:$path?${parts.join('&')}';
  }

  ({String key, Map<String, String> timeParams})? _looseKey(
    String method,
    String path,
    Map<String, dynamic>? query,
  ) {
    final time = <String, String>{};
    final parts = <String>[];
    for (final e in (query ?? const <String, dynamic>{}).entries) {
      if (e.value == null) continue;
      if (_isTimeParam(e.key, e.value)) {
        time[e.key] = '${e.value}';
      } else {
        parts.add('${e.key}=${e.value}');
      }
    }
    if (time.isEmpty) return null;
    parts.sort();
    return (
      key: '${_scope()}|$method:$path?${parts.join('&')}',
      timeParams: time,
    );
  }

  /// Hive string keys max out at 255 chars, so store under a stable hash and
  /// keep the full key in the meta record to rule out collisions.
  static String _hash(String input) {
    var h1 = 0x811c9dc5;
    var h2 = 0x811c9dc5;
    final units = input.codeUnits;
    for (var i = 0; i < units.length; i++) {
      h1 = ((h1 ^ units[i]) * 0x01000193) & 0xffffffff;
      h2 = ((h2 ^ units[units.length - 1 - i]) * 0x01000193) & 0xffffffff;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}'
        '${h2.toRadixString(16).padLeft(8, '0')}';
  }

  Future<void> put({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    required dynamic body,
  }) async {
    try {
      final fullKey = _fullKey(method, path, query);
      final loose = _looseKey(method, path, query);
      final key = _hash(fullKey);
      final encoded = jsonEncode(body);
      final now = DateTime.now();
      await _values.put(key, encoded);
      await _meta.put(
        key,
        jsonEncode({
          'k': fullKey,
          's': now.toUtc().toIso8601String(),
          'b': encoded.length,
          if (loose != null) 'l': loose.key,
          if (loose != null) 't': loose.timeParams,
        }),
      );
      _removeFromIndex(key);
      _addToIndex(
        key,
        _CacheMeta(
          fullKey,
          now,
          encoded.length,
          looseKey: loose?.key,
          timeParams: loose?.timeParams ?? const {},
        ),
      );
      await _evictIfNeeded();
    } catch (_) {}
  }

  Future<CachedResponse?> read({
    required String method,
    required String path,
    Map<String, dynamic>? query,
  }) async {
    try {
      final fullKey = _fullKey(method, path, query);
      final key = _hash(fullKey);
      final meta = _index[key];
      if (meta != null && meta.fullKey == fullKey) {
        final hit = await _load(key, meta);
        if (hit != null) return hit;
      }
      return await _readNearby(method, path, query);
    } catch (_) {
      return null;
    }
  }

  Future<CachedResponse?> _load(String key, _CacheMeta meta) async {
    final raw = await _readValue(key);
    if (raw == null || raw.isEmpty) return null;
    meta.lastAccess = DateTime.now();
    return CachedResponse(jsonDecode(raw), meta.savedAt);
  }

  /// Newest copy of the same request whose date/time parameters are each
  /// within [timeWindowTolerance] of the requested ones.
  Future<CachedResponse?> _readNearby(
    String method,
    String path,
    Map<String, dynamic>? query,
  ) async {
    final loose = _looseKey(method, path, query);
    if (loose == null) return null;
    final candidates = _byLooseKey[loose.key];
    if (candidates == null || candidates.isEmpty) return null;
    String? bestKey;
    _CacheMeta? best;
    for (final key in candidates) {
      final meta = _index[key];
      if (meta == null) continue;
      if (!_timeParamsClose(loose.timeParams, meta.timeParams)) continue;
      if (best == null || meta.savedAt.isAfter(best.savedAt)) {
        best = meta;
        bestKey = key;
      }
    }
    if (best == null || bestKey == null) return null;
    return _load(bestKey, best);
  }

  static bool _timeParamsClose(
    Map<String, String> wanted,
    Map<String, String> cached,
  ) {
    if (wanted.length != cached.length) return false;
    for (final entry in wanted.entries) {
      final other = cached[entry.key];
      if (other == null) return false;
      if (other == entry.value) continue;
      final a = DateTime.tryParse(entry.value);
      final b = DateTime.tryParse(other);
      if (a == null || b == null) return false;
      if (a.difference(b).abs() > timeWindowTolerance) return false;
    }
    return true;
  }

  /// When the cached copy for this request was fetched, if any.
  DateTime? savedAt({
    required String method,
    required String path,
    Map<String, dynamic>? query,
  }) {
    final fullKey = _fullKey(method, path, query);
    final meta = _index[_hash(fullKey)];
    if (meta == null || meta.fullKey != fullKey) return null;
    return meta.savedAt;
  }

  /// GET requests saved for the current tenant + user (query values as the
  /// strings they were keyed with).
  List<CachedRequest> cachedRequests() {
    final prefix = '${_scope()}|GET:';
    final out = <CachedRequest>[];
    for (final meta in _index.values) {
      if (!meta.fullKey.startsWith(prefix)) continue;
      final rest = meta.fullKey.substring(prefix.length);
      final mark = rest.indexOf('?');
      final path = mark < 0 ? rest : rest.substring(0, mark);
      final query = <String, String>{};
      if (mark >= 0) {
        for (final part in rest.substring(mark + 1).split('&')) {
          final eq = part.indexOf('=');
          if (eq <= 0) continue;
          query[part.substring(0, eq)] = part.substring(eq + 1);
        }
      }
      out.add(CachedRequest(
        path: path,
        query: query,
        savedAt: meta.savedAt,
        lastAccess: meta.lastAccess,
        hasTimeParams: meta.timeParams.isNotEmpty,
      ));
    }
    return out;
  }

  /// Newest saved GET for [path] with any query (current tenant + user).
  Future<CachedResponse?> newestForPath(String path) async {
    final prefix = '${_scope()}|GET:$path?';
    String? bestKey;
    _CacheMeta? best;
    for (final entry in _index.entries) {
      if (!entry.value.fullKey.startsWith(prefix)) continue;
      if (best == null || entry.value.savedAt.isAfter(best.savedAt)) {
        best = entry.value;
        bestKey = entry.key;
      }
    }
    if (best == null || bestKey == null) return null;
    try {
      final raw = await _readValue(bestKey);
      if (raw == null || raw.isEmpty) return null;
      return CachedResponse(jsonDecode(raw), best.savedAt);
    } catch (_) {
      return null;
    }
  }

  int get entryCount => _index.length;
  int get totalBytes => _totalBytes;

  Future<String?> _readValue(String key) async {
    final box = _values;
    if (box is LazyBox<String>) return box.get(key);
    if (box is Box<String>) return box.get(key);
    return null;
  }

  Future<void> _evictIfNeeded() async {
    if (_index.length <= maxEntries && _totalBytes <= maxBytes) return;
    final targetEntries = (maxEntries * 0.9).floor();
    final targetBytes = (maxBytes * 0.9).floor();
    final ordered = _index.entries.toList()
      ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));
    for (final entry in ordered) {
      if (_index.length <= targetEntries && _totalBytes <= targetBytes) break;
      _removeFromIndex(entry.key);
      await _values.delete(entry.key);
      await _meta.delete(entry.key);
    }
  }

  Future<void> clear() async {
    try {
      _index.clear();
      _byLooseKey.clear();
      _totalBytes = 0;
      lastServedSavedAt.value = null;
      await _values.clear();
      await _meta.clear();
    } catch (_) {}
  }
}
