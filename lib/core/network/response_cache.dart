import 'dart:convert';

import 'package:gems_data_layer/gems_data_layer.dart';

/// JSON GET cache stored in the gems Hive [DatabaseService].
class ResponseCache {
  static const _prefix = 'http_cache:';
  static const _box = 'http_cache';

  final DatabaseService _db;

  ResponseCache(this._db);

  Future<void> ensureReady() async {
    try {
      await _db.openBox(_box);
    } catch (_) {}
  }

  String _key(String method, String path, Map<String, dynamic>? query) {
    final parts = (query ?? {}).entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .toList()
      ..sort();
    return '$_prefix$method:$path?${parts.join('&')}';
  }

  Future<void> put({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    required dynamic body,
  }) async {
    try {
      await _db.save<String>(
        _key(method, path, query),
        jsonEncode({
          'savedAt': DateTime.now().toIso8601String(),
          'body': body,
        }),
        boxName: _box,
      );
    } catch (_) {}
  }

  dynamic get({
    required String method,
    required String path,
    Map<String, dynamic>? query,
  }) {
    try {
      final raw = _db.get<String>(_key(method, path, query), boxName: _box);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded.containsKey('body')) {
        return decoded['body'];
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _db.clear(boxName: _box);
    } catch (_) {}
  }
}
