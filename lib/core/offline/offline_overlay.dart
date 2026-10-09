import 'outbox_item.dart';

/// Shows changes still waiting in the outbox inside saved GET responses, so
/// a list or detail read from the device already contains what the user did
/// offline (REST shape: `POST /x` adds to `GET /x`, `PATCH|PUT /x/:id`
/// edits it, `DELETE /x/:id` removes it).
abstract final class OfflineOverlay {
  static const String tempIdPrefix = 'offline-';

  /// Keys whose list holds the records of a wrapped list response.
  static const List<String> _listKeys = [
    'items',
    'results',
    'rows',
    'records',
    'entries',
    'messages',
    'notes',
    'comments',
  ];

  static bool isTempId(String value) => value.startsWith(tempIdPrefix);

  /// Signed-in person (`id`, `email`, `name`), shown as the author of
  /// records created offline. Wired by the offline bootstrap.
  static Map<String, dynamic>? Function()? currentAuthor;

  /// Server-like record for a queued write (never sent to the server).
  static Map<String, dynamic> recordFor(OutboxItem item) {
    final body = item.jsonBody;
    final at = item.occurredAt.toUtc().toIso8601String();
    final id = item.meta['tempId'] ??
        (item.method == 'POST' ? item.id : idFromPath(item.path));
    final record = <String, dynamic>{
      if (body is Map) ...body.cast<String, dynamic>(),
      if ((body is! Map || body['id'] == null) && id != null) 'id': id,
      if (body is! Map || body['createdAt'] == null) 'createdAt': at,
      'updatedAt': at,
      'offlinePending': true,
    };
    if (item.method == 'POST') {
      final author = currentAuthor?.call();
      final authorId = author?['id'] ?? item.userId;
      for (final key in const ['senderId', 'authorId', 'createdById']) {
        record.putIfAbsent(key, () => authorId);
      }
      if (author != null) {
        for (final key in const ['sender', 'author', 'createdBy']) {
          record.putIfAbsent(key, () => Map<String, dynamic>.of(author));
        }
      }
    }
    return record;
  }

  /// Record id in an update path (`/tasks/abc1/status` → `abc1`): the last
  /// segment that looks like an id (has a digit) rather than an action.
  static String? idFromPath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    for (final segment in segments.reversed) {
      if (RegExp(r'\d').hasMatch(segment)) return segment;
    }
    return null;
  }

  /// [body] with [items] applied. Items in [skipAppendTags] never add rows
  /// (their screens already list pending creates separately).
  static dynamic apply({
    required String path,
    required dynamic body,
    required Iterable<OutboxItem> items,
    Set<String> skipAppendTags = const {},
  }) {
    final target = _trim(path);
    final list = items.where((i) => !i.status.needsAttention).toList();
    if (list.isEmpty) return body;
    body = _jsonCopy(body);
    for (final item in list) {
      final itemPath = _trim(item.path);
      final patch = item.jsonBody is Map
          ? (item.jsonBody as Map).cast<String, dynamic>()
          : null;
      switch (item.method) {
        case 'POST':
          if (itemPath != target || skipAppendTags.contains(item.featureTag)) {
            continue;
          }
          final list = _listOf(body);
          if (list == null) continue;
          final record = recordFor(item);
          if (list.any((e) => e is Map && e['id'] == record['id'])) continue;
          if (_newestFirst(list)) {
            list.insert(0, record);
          } else {
            list.add(record);
          }
        case 'PATCH':
        case 'PUT':
          if (patch == null) continue;
          if (itemPath == target) {
            final detail = _detailOf(body);
            if (detail != null) detail.addAll(patch);
            continue;
          }
          final id = _childId(target, itemPath);
          if (id == null) continue;
          final list = _listOf(body);
          if (list == null) continue;
          for (final entry in list) {
            if (entry is Map && '${entry['id']}' == id) {
              entry.addAll(patch);
            }
          }
        case 'DELETE':
          final id = _childId(target, itemPath);
          if (id == null) continue;
          _listOf(body)?.removeWhere((e) => e is Map && '${e['id']}' == id);
      }
    }
    return body;
  }

  /// Response for a GET whose path contains a record created offline: the
  /// record itself (`/x/<temp>`), or the offline items added under it.
  static dynamic forTempPath(String path, Iterable<OutboxItem> items) {
    final target = _trim(path);
    for (final item in items) {
      if (item.method != 'POST') continue;
      final tempId = item.meta['tempId'];
      if (tempId != null && '${_trim(item.path)}/$tempId' == target) {
        return recordFor(item);
      }
    }
    return apply(path: target, body: <dynamic>[], items: items);
  }

  static dynamic _jsonCopy(dynamic node) {
    if (node is Map) {
      return <String, dynamic>{
        for (final e in node.entries) '${e.key}': _jsonCopy(e.value),
      };
    }
    if (node is List) return <dynamic>[for (final v in node) _jsonCopy(v)];
    return node;
  }

  static String _trim(String path) =>
      path.length > 1 && path.endsWith('/') ? path.substring(0, path.length - 1) : path;

  /// `/x/42` under `/x` → `42`; anything deeper or elsewhere → null.
  static String? _childId(String collection, String itemPath) {
    final prefix = '$collection/';
    if (!itemPath.startsWith(prefix)) return null;
    final rest = itemPath.substring(prefix.length);
    if (rest.isEmpty || rest.contains('/')) return null;
    return rest;
  }

  static List<dynamic>? _listOf(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return null;
    final data = body['data'];
    if (data is List) return data;
    final holder = data is Map ? data : body;
    for (final key in _listKeys) {
      final value = holder[key];
      if (value is List) return value;
    }
    return null;
  }

  static Map<dynamic, dynamic>? _detailOf(dynamic body) {
    if (body is! Map) return null;
    final data = body['data'];
    if (data is Map) return data;
    if (data is List) return null;
    return body;
  }

  static bool _newestFirst(List<dynamic> list) {
    DateTime? at(dynamic e) => e is Map
        ? DateTime.tryParse('${e['createdAt'] ?? e['sentAt'] ?? ''}')
        : null;
    if (list.length < 2) return false;
    final first = at(list.first);
    final last = at(list.last);
    if (first == null || last == null) return false;
    return first.isAfter(last);
  }
}
