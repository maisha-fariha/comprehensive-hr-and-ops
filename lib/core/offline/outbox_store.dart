import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive_ce/hive_ce.dart';

import 'outbox_item.dart';

/// Durable outbox: one encrypted Hive record per queued write, keyed by id.
///
/// Every mutation writes a single record, so a crash mid-sync can never drop
/// other items (the legacy queue rewrote one JSON blob for the whole list).
class OutboxStore {
  final Box<String> _box;
  final RxList<OutboxItem> items = <OutboxItem>[].obs;
  int _lastSeq = 0;

  OutboxStore(this._box) {
    _reload();
  }

  void _reload() {
    final loaded = <OutboxItem>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        loaded.add(
          OutboxItem.fromJson(
            (jsonDecode(raw) as Map).cast<String, dynamic>(),
          ),
        );
      } catch (_) {
        // Unreadable record: keep it on disk, skip it in memory.
      }
    }
    loaded.sort((a, b) => a.seq.compareTo(b.seq));
    for (final item in loaded) {
      if (item.seq > _lastSeq) _lastSeq = item.seq;
    }
    items.assignAll(loaded);
  }

  /// Monotonic sequence so FIFO order survives identical timestamps.
  int nextSeq() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastSeq = now > _lastSeq ? now : _lastSeq + 1;
    return _lastSeq;
  }

  List<OutboxItem> get all => List.unmodifiable(items);

  OutboxItem? byId(String id) => items.firstWhereOrNull((i) => i.id == id);

  /// Items owned by [userId] in [tenant], oldest first.
  List<OutboxItem> forScope(String userId, String tenant) =>
      items.where((i) => i.belongsTo(userId, tenant)).toList();

  Future<void> put(OutboxItem item) async {
    await _box.put(item.id, jsonEncode(item.toJson()));
    final index = items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
      items.sort((a, b) => a.seq.compareTo(b.seq));
    }
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    items.removeWhere((i) => i.id == id);
  }

  /// Items left in `sending` by a crash/kill go back to `pending`.
  Future<void> recoverInterrupted() async {
    for (final item in List<OutboxItem>.of(items)) {
      if (item.status == OutboxStatus.sending) {
        await put(item.copyWith(status: OutboxStatus.pending));
      }
    }
  }

  Future<void> close() => _box.close();
}
