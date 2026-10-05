import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData;
import 'package:uuid/uuid.dart';

import 'outbox_attachments.dart';
import 'outbox_context.dart';
import 'outbox_feature.dart';
import 'outbox_item.dart';
import 'outbox_store.dart';
import 'outbox_sync_engine.dart';

/// App-facing entry point for offline writes: records items for the signed-in
/// user, stages offline uploads and exposes scoped state for the UI.
class OfflineOutbox {
  final OutboxStore store;
  final StagedUploadStore uploads;
  final OutboxSyncEngine engine;
  final OutboxScope? Function() scope;
  final Uuid _uuid;

  OfflineOutbox({
    required this.store,
    required this.uploads,
    required this.engine,
    required this.scope,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  String newIdempotencyKey() => _uuid.v4();

  /// Queues a JSON write. Returns null when it cannot be queued (no signed-in
  /// owner, excluded path or a body that is not JSON-encodable).
  Future<OutboxItem?> enqueue({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    dynamic data,
    required String idempotencyKey,
    DateTime? occurredAt,
  }) async {
    if (OutboxFeature.isNeverQueued(path)) return null;
    final owner = scope();
    if (owner == null || !owner.isValid) return null;
    if (data is FormData) return null;
    try {
      jsonEncode(data);
      jsonEncode(query);
    } catch (_) {
      return null;
    }

    final normalizedBody = data == null ? null : jsonDecode(jsonEncode(data));
    final attachments = await uploads.claim(normalizedBody);
    final now = DateTime.now();
    final item = OutboxItem(
      id: _uuid.v4(),
      seq: store.nextSeq(),
      userId: owner.userId,
      tenant: owner.tenant,
      method: method.toUpperCase(),
      path: path,
      query: query == null
          ? null
          : (jsonDecode(jsonEncode(query)) as Map).cast<String, dynamic>(),
      jsonBody: normalizedBody,
      attachments: attachments,
      idempotencyKey: idempotencyKey,
      occurredAt: occurredAt ?? now,
      createdAt: now,
      featureTag: OutboxFeature.tagFor(path),
      label: OutboxFeature.labelFor(method, path),
      meta: OutboxContext.meta,
    );
    await store.put(item);
    return item;
  }

  Future<Map<String, dynamic>?> stageUpload({
    required FormData form,
    required String path,
    Map<String, dynamic>? query,
  }) async {
    final owner = scope();
    if (owner == null || !owner.isValid) return null;
    try {
      return await uploads.stage(
        form: form,
        uploadPath: path,
        uploadQuery: query,
      );
    } catch (_) {
      return null;
    }
  }

  /// Items owned by the signed-in user, oldest first.
  List<OutboxItem> get scopedItems {
    final owner = scope();
    if (owner == null || !owner.isValid) return const [];
    return store.forScope(owner.userId, owner.tenant);
  }

  int get pendingCount => scopedItems
      .where((i) =>
          i.status == OutboxStatus.pending || i.status == OutboxStatus.sending)
      .length;

  int get attentionCount =>
      scopedItems.where((i) => i.status.needsAttention).length;

  int get unsentCount => scopedItems.length;

  List<OutboxItem> itemsFor(Set<String> featureTags) =>
      scopedItems.where((i) => featureTags.contains(i.featureTag)).toList();

  /// True when a scheduled dose was recorded on this device and has not yet
  /// reached the server (any outbox status).
  bool hasUnsentDose({
    required String doseId,
    required String clientId,
    required String medicationId,
    required String slot,
    DateTime? day,
  }) {
    final target = day ?? DateTime.now();
    for (final item in itemsFor({OutboxFeature.mar})) {
      if (item.method != 'POST') continue;
      final meta = item.meta;
      final itemDose = meta['doseId'];
      if (doseId.isNotEmpty && itemDose != null) {
        if (itemDose == doseId) return true;
        continue;
      }
      final body = item.jsonBody;
      final itemClient = meta['clientId'] ?? (body is Map ? '${body['clientId']}' : '');
      final itemMed =
          meta['medicationId'] ?? (body is Map ? '${body['medicationId']}' : '');
      if (itemClient != clientId || itemMed != medicationId) continue;
      final sameDay = item.occurredAt.year == target.year &&
          item.occurredAt.month == target.month &&
          item.occurredAt.day == target.day;
      if (!sameDay) continue;
      final itemSlot = meta['slot'];
      if (itemSlot == null || slot.isEmpty || itemSlot == slot) return true;
    }
    return false;
  }

  static OfflineOutbox? get maybe =>
      Get.isRegistered<OfflineOutbox>() ? Get.find<OfflineOutbox>() : null;
}
