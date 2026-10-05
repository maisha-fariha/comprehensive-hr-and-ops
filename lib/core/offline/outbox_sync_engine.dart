import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:get/get.dart';

import 'offline_config.dart';
import 'outbox_attachments.dart';
import 'outbox_feature.dart';
import 'outbox_item.dart';
import 'outbox_store.dart';

/// Signed-in owner of queued writes. Items only replay for their owner.
class OutboxScope {
  final String userId;
  final String tenant;

  const OutboxScope({required this.userId, required this.tenant});

  bool get isValid => userId.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is OutboxScope && other.userId == userId && other.tenant == tenant;

  @override
  int get hashCode => Object.hash(userId, tenant);
}

enum OutboxSendKind {
  success,

  /// No connection, timeout, 408, 429 or 5xx — retry later, keep order.
  retryable,

  /// 401 after a refresh attempt — wait for the user to sign in again.
  unauthorized,

  /// 400 / 403 / 404 / 422 and other 4xx — the server will not accept it.
  rejected,

  /// 409 — server copy changed; needs a human decision.
  conflict,
}

class OutboxSendResult {
  final OutboxSendKind kind;
  final int? statusCode;
  final String? message;
  final dynamic body;

  const OutboxSendResult({
    required this.kind,
    this.statusCode,
    this.message,
    this.body,
  });

  bool get isSuccess => kind == OutboxSendKind.success;

  static OutboxSendKind classify(int? statusCode, {bool success = false}) {
    if (success) return OutboxSendKind.success;
    final code = statusCode ?? 0;
    if (code >= 200 && code < 300) return OutboxSendKind.success;
    if (code == 0 || code == 408 || code == 429 || code >= 500) {
      return OutboxSendKind.retryable;
    }
    if (code == 401) return OutboxSendKind.unauthorized;
    if (code == 409) return OutboxSendKind.conflict;
    return OutboxSendKind.rejected;
  }
}

/// Raw request channel used for replays (no queueing, no dialogs).
abstract interface class OutboxTransport {
  Future<OutboxSendResult> send({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    dynamic data,
    required Map<String, String> headers,
  });
}

class OutboxSyncSummary {
  final int sent;
  final int needsAttention;
  final int remaining;
  final bool stoppedEarly;

  const OutboxSyncSummary({
    this.sent = 0,
    this.needsAttention = 0,
    this.remaining = 0,
    this.stoppedEarly = false,
  });

  static const empty = OutboxSyncSummary();

  bool get hasNews => sent > 0 || needsAttention > 0;
}

/// Replays the outbox for the signed-in user, oldest first.
class OutboxSyncEngine {
  final OutboxStore store;
  final StagedUploadStore uploads;
  final OutboxTransport transport;
  final OutboxScope? Function() scope;
  final bool Function() isOnline;
  final DateTime Function() _now;
  final Random _random;

  final RxBool isSyncing = false.obs;
  final RxInt inFlightRemaining = 0.obs;
  final Rxn<OutboxSyncSummary> lastSummary = Rxn<OutboxSyncSummary>();

  /// Bumped after every run that delivered at least one item, so screens can
  /// reload and swap pending rows for server records.
  final RxInt syncedGeneration = 0.obs;

  void Function(OutboxSyncSummary summary)? onSummary;

  Future<OutboxSyncSummary>? _inFlight;
  Timer? _retryTimer;
  bool _yieldRequested = false;

  OutboxSyncEngine({
    required this.store,
    required this.uploads,
    required this.transport,
    required this.scope,
    required this.isOnline,
    DateTime Function()? now,
    Random? random,
  })  : _now = now ?? DateTime.now,
        _random = random ?? Random();

  bool get isRunning => _inFlight != null;

  /// Asks a running flush to stop after the current item.
  void requestYield() => _yieldRequested = true;

  /// Single-flight: concurrent callers share the running flush.
  /// [ignoreBackoff] is used on reconnect / resume / manual "Sync now".
  Future<OutboxSyncSummary> flush({bool ignoreBackoff = false}) {
    final running = _inFlight;
    if (running != null) return running;
    final future = _run(ignoreBackoff: ignoreBackoff);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
  }

  Future<OutboxSyncSummary> _run({required bool ignoreBackoff}) async {
    _yieldRequested = false;
    final owner = scope();
    if (owner == null || !owner.isValid || !isOnline()) {
      return OutboxSyncSummary.empty;
    }

    var sent = 0;
    var attention = 0;
    var stoppedEarly = false;
    isSyncing.value = true;
    try {
      final queue = store
          .forScope(owner.userId, owner.tenant)
          .where((i) => i.status == OutboxStatus.pending)
          .toList();
      inFlightRemaining.value = queue.length;

      for (final queued in queue) {
        if (_yieldRequested || !isOnline()) {
          stoppedEarly = true;
          break;
        }
        final item = store.byId(queued.id);
        if (item == null || item.status != OutboxStatus.pending) {
          inFlightRemaining.value--;
          continue;
        }
        // Strict FIFO: a later item never overtakes one still backing off.
        if (!ignoreBackoff && !item.isDue(_now())) {
          stoppedEarly = true;
          break;
        }

        await store.put(item.copyWith(status: OutboxStatus.sending));
        final outcome = await _deliver(item);
        inFlightRemaining.value--;

        switch (outcome.kind) {
          case OutboxSendKind.success:
            await store.remove(item.id);
            await uploads.deleteFiles(item.attachments);
            sent++;
          case OutboxSendKind.retryable:
            final latest = store.byId(item.id) ?? item;
            final attempts = latest.attempts + 1;
            if (attempts >= OfflineConfig.maxNetworkAttempts) {
              await store.put(latest.copyWith(
                status: OutboxStatus.failed,
                attempts: attempts,
                lastError: outcome.message ??
                    'Could not reach the server after $attempts tries.',
                lastStatusCode: outcome.statusCode,
                clearNextAttempt: true,
              ));
              attention++;
            } else {
              await store.put(latest.copyWith(
                status: OutboxStatus.pending,
                attempts: attempts,
                nextAttemptAt: _now().add(backoffFor(attempts)),
                lastError: outcome.message,
                lastStatusCode: outcome.statusCode,
              ));
            }
            stoppedEarly = true;
          case OutboxSendKind.unauthorized:
            await store.put((store.byId(item.id) ?? item).copyWith(
              status: OutboxStatus.pending,
              lastError: 'Sign in again to send this change.',
              lastStatusCode: 401,
            ));
            stoppedEarly = true;
          case OutboxSendKind.rejected:
            await store.put((store.byId(item.id) ?? item).copyWith(
              status: OutboxStatus.failed,
              lastError: outcome.message ?? 'The server did not accept this change.',
              lastStatusCode: outcome.statusCode,
              clearNextAttempt: true,
            ));
            attention++;
          case OutboxSendKind.conflict:
            await store.put((store.byId(item.id) ?? item).copyWith(
              status: OutboxStatus.conflict,
              lastError: outcome.message ??
                  'This record was changed by someone else.',
              lastStatusCode: outcome.statusCode ?? 409,
              clearNextAttempt: true,
            ));
            attention++;
        }
        if (stoppedEarly) break;
      }
    } finally {
      isSyncing.value = false;
      inFlightRemaining.value = 0;
    }

    final remaining = store
        .forScope(owner.userId, owner.tenant)
        .where((i) => i.status == OutboxStatus.pending)
        .length;
    final summary = OutboxSyncSummary(
      sent: sent,
      needsAttention: attention,
      remaining: remaining,
      stoppedEarly: stoppedEarly,
    );
    lastSummary.value = summary;
    if (sent > 0) syncedGeneration.value++;
    _scheduleRetry(owner);
    if (summary.hasNews) onSummary?.call(summary);
    return summary;
  }

  Future<OutboxSendResult> _deliver(OutboxItem item) async {
    var current = item;
    final urls = <String, String>{};
    for (var i = 0; i < current.attachments.length; i++) {
      final attachment = current.attachments[i];
      final done = attachment.uploadedUrl;
      if (done != null && done.isNotEmpty) {
        urls[attachment.id] = done;
        continue;
      }
      if (!File(attachment.localPath).existsSync()) {
        return const OutboxSendResult(
          kind: OutboxSendKind.rejected,
          message: 'An attached file is no longer on this device.',
        );
      }
      final result = await transport.send(
        method: 'POST',
        path: attachment.uploadPath,
        query: attachment.uploadQuery,
        data: StagedUploadStore.rebuildForm(attachment),
        headers: {
          OfflineConfig.idempotencyHeader:
              '${item.idempotencyKey}:${attachment.id}',
          OfflineConfig.occurredAtHeader:
              item.occurredAt.toUtc().toIso8601String(),
        },
      );
      if (!result.isSuccess) return result;
      final url = _uploadedUrl(result.body);
      if (url == null) {
        return const OutboxSendResult(
          kind: OutboxSendKind.rejected,
          message: 'Upload succeeded but the file URL was missing.',
        );
      }
      urls[attachment.id] = url;
      final updated = List<OutboxAttachment>.of(current.attachments)
        ..[i] = attachment.withUploadedUrl(url);
      current = current.copyWith(attachments: updated);
      await store.put(current);
    }

    var body = urls.isEmpty
        ? current.jsonBody
        : StagedUploadStore.replaceTokens(current.jsonBody, urls);
    if (StagedUploadStore.referencedIds(body).isNotEmpty) {
      return const OutboxSendResult(
        kind: OutboxSendKind.rejected,
        message: 'An attached file is no longer on this device.',
      );
    }
    if (OfflineConfig.includeOccurredAtInBody &&
        OutboxFeature.timeSensitive.contains(current.featureTag) &&
        body is Map &&
        !body.containsKey('clientOccurredAt')) {
      body = {
        ...body,
        'clientOccurredAt': current.occurredAt.toUtc().toIso8601String(),
      };
    }

    return transport.send(
      method: current.method,
      path: current.path,
      query: current.query,
      data: body,
      headers: {
        OfflineConfig.idempotencyHeader: current.idempotencyKey,
        OfflineConfig.occurredAtHeader:
            current.occurredAt.toUtc().toIso8601String(),
      },
    );
  }

  static String? _uploadedUrl(dynamic body) {
    dynamic node = body;
    if (node is Map && node['data'] is Map) node = node['data'];
    if (node is! Map) return null;
    for (final key in const ['fileUrl', 'url', 'publicUrl']) {
      final value = node[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// Exponential backoff (5 s → 15 min) with jitter in [50 %, 100 %].
  Duration backoffFor(int attempts) {
    final exp = attempts <= 1 ? 0 : min(attempts - 1, 20);
    final rawMs = OfflineConfig.backoffBase.inMilliseconds * pow(2, exp);
    final cappedMs = min(rawMs.toDouble(),
        OfflineConfig.backoffCap.inMilliseconds.toDouble());
    final jittered = cappedMs * (0.5 + _random.nextDouble() * 0.5);
    return Duration(milliseconds: jittered.round());
  }

  void _scheduleRetry(OutboxScope owner) {
    _retryTimer?.cancel();
    _retryTimer = null;
    DateTime? earliest;
    for (final item in store.forScope(owner.userId, owner.tenant)) {
      if (item.status != OutboxStatus.pending) continue;
      final at = item.nextAttemptAt;
      if (at == null) continue;
      if (earliest == null || at.isBefore(earliest)) earliest = at;
    }
    if (earliest == null) return;
    var wait = earliest.difference(_now());
    if (wait.isNegative) wait = Duration.zero;
    _retryTimer = Timer(wait, () => unawaited(flush()));
  }

  /// User asked to try a failed / conflicting / waiting item again.
  Future<void> retry(String id) async {
    final item = store.byId(id);
    if (item == null) return;
    await store.put(item.copyWith(
      status: OutboxStatus.pending,
      attempts: 0,
      clearNextAttempt: true,
      clearError: true,
    ));
    unawaited(flush(ignoreBackoff: true));
  }

  Future<void> discard(String id) async {
    final item = store.byId(id);
    if (item == null) return;
    await store.remove(id);
    await uploads.deleteFiles(item.attachments);
  }

  /// Replaces the body of a queued item (edit before retry).
  Future<void> updateBody(String id, dynamic jsonBody) async {
    final item = store.byId(id);
    if (item == null) return;
    await store.put(item.copyWith(
      jsonBody: jsonBody,
      status: OutboxStatus.pending,
      attempts: 0,
      clearNextAttempt: true,
      clearError: true,
    ));
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}
