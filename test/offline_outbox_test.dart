import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:comprehensive_hr_and_ops/core/offline/offline_config.dart';
import 'package:comprehensive_hr_and_ops/core/offline/offline_outbox.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_attachments.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_context.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_item.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_store.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_sync_engine.dart';

class _Call {
  final String method;
  final String path;
  final dynamic data;
  final Map<String, String> headers;

  _Call(this.method, this.path, this.data, this.headers);
}

class _FakeTransport implements OutboxTransport {
  final List<_Call> calls = [];
  OutboxSendResult Function(_Call call)? respond;
  Completer<void>? gate;

  @override
  Future<OutboxSendResult> send({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    dynamic data,
    required Map<String, String> headers,
  }) async {
    final call = _Call(method, path, data, headers);
    calls.add(call);
    if (gate != null) await gate!.future;
    return respond?.call(call) ??
        const OutboxSendResult(kind: OutboxSendKind.success, statusCode: 200);
  }
}

void main() {
  late Directory tmp;
  late Box<String> outboxBox;
  late Box<String> uploadsBox;
  late OutboxStore store;
  late StagedUploadStore uploads;
  late _FakeTransport transport;
  late OutboxSyncEngine engine;
  late OfflineOutbox outbox;
  OutboxScope? scope;
  var online = true;
  var boxCounter = 0;

  Future<void> build() async {
    boxCounter++;
    outboxBox = await Hive.openBox<String>('outbox_$boxCounter');
    uploadsBox = await Hive.openBox<String>('uploads_$boxCounter');
    store = OutboxStore(outboxBox);
    uploads = StagedUploadStore(
      uploadsBox,
      rootDir: () async => Directory('${tmp.path}/files'),
    );
    transport = _FakeTransport();
    engine = OutboxSyncEngine(
      store: store,
      uploads: uploads,
      transport: transport,
      scope: () => scope,
      isOnline: () => online,
      random: Random(1),
    );
    outbox = OfflineOutbox(
      store: store,
      uploads: uploads,
      engine: engine,
      scope: () => scope,
    );
  }

  Future<OutboxItem> queue(
    String path, {
    Map<String, dynamic>? body,
    String method = 'POST',
  }) async {
    final item = await outbox.enqueue(
      method: method,
      path: path,
      data: body ?? {'n': path},
      idempotencyKey: 'key-$path',
    );
    expect(item, isNotNull, reason: 'expected $path to be queueable');
    return item!;
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('outbox_test');
    Hive.init(tmp.path);
    scope = const OutboxScope(userId: 'u1', tenant: 'acme');
    online = true;
    await build();
  });

  tearDown(() async {
    engine.dispose();
    await Hive.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('OutboxStore', () {
    test('items survive a restart, in FIFO order', () async {
      await queue('/daily-logs');
      await queue('/tasks');
      await queue('/incidents');
      final name = outboxBox.name;
      await outboxBox.close();

      final reopened = OutboxStore(await Hive.openBox<String>(name));
      expect(
        reopened.items.map((i) => i.path).toList(),
        ['/daily-logs', '/tasks', '/incidents'],
      );
    });

    test('recoverInterrupted puts "sending" items back to pending', () async {
      final item = await queue('/tasks');
      await store.put(item.copyWith(status: OutboxStatus.sending));
      await store.recoverInterrupted();
      expect(store.byId(item.id)!.status, OutboxStatus.pending);
    });
  });

  group('OfflineOutbox.enqueue', () {
    test('never queues excluded paths, FormData or without a signed-in user',
        () async {
      expect(
        await outbox.enqueue(
          method: 'POST',
          path: '/auth/login',
          data: {'email': 'a'},
          idempotencyKey: 'k',
        ),
        isNull,
      );
      expect(
        await outbox.enqueue(
          method: 'POST',
          path: '/daily-logs',
          data: FormData.fromMap({'a': 'b'}),
          idempotencyKey: 'k',
        ),
        isNull,
      );
      scope = null;
      expect(
        await outbox.enqueue(
          method: 'POST',
          path: '/daily-logs',
          data: {'a': 'b'},
          idempotencyKey: 'k',
        ),
        isNull,
      );
      expect(store.items, isEmpty);
    });

    test('records owner, feature, label and context meta', () async {
      final item = await OutboxContext.run(
        () => queue('/mar/administrations'),
        meta: {'doseId': 'd1'},
      );
      expect(item.userId, 'u1');
      expect(item.tenant, 'acme');
      expect(item.featureTag, 'mar');
      expect(item.meta['doseId'], 'd1');
      expect(item.label, isNotEmpty);
    });
  });

  group('OutboxSyncEngine', () {
    test('sends oldest first with the idempotency + occurred-at headers',
        () async {
      final a = await queue('/daily-logs');
      await queue('/tasks');

      final summary = await engine.flush();

      expect(summary.sent, 2);
      expect(store.items, isEmpty);
      expect(transport.calls.map((c) => c.path), ['/daily-logs', '/tasks']);
      final headers = transport.calls.first.headers;
      expect(headers[OfflineConfig.idempotencyHeader], a.idempotencyKey);
      expect(
        headers[OfflineConfig.occurredAtHeader],
        a.occurredAt.toUtc().toIso8601String(),
      );
      expect(engine.syncedGeneration.value, 1);
    });

    test('a retryable failure stops the batch and backs off (strict FIFO)',
        () async {
      await queue('/a');
      final b = await queue('/b');
      await queue('/c');
      transport.respond = (call) => call.path == '/b'
          ? const OutboxSendResult(
              kind: OutboxSendKind.retryable,
              statusCode: 503,
            )
          : const OutboxSendResult(kind: OutboxSendKind.success);

      final summary = await engine.flush();

      expect(summary.sent, 1);
      expect(transport.calls.map((c) => c.path), ['/a', '/b']);
      final retried = store.byId(b.id)!;
      expect(retried.status, OutboxStatus.pending);
      expect(retried.attempts, 1);
      expect(retried.nextAttemptAt, isNotNull);
      expect(store.items.map((i) => i.path), ['/b', '/c']);

      // Not due yet: a normal flush does not overtake /b.
      transport.calls.clear();
      await engine.flush();
      expect(transport.calls, isEmpty);
    });

    test('4xx marks the item failed and continues; 409 marks conflict',
        () async {
      final a = await queue('/a');
      final b = await queue('/b');
      await queue('/c');
      transport.respond = (call) => switch (call.path) {
            '/a' => const OutboxSendResult(
                kind: OutboxSendKind.rejected,
                statusCode: 422,
                message: 'Invalid',
              ),
            '/b' => const OutboxSendResult(
                kind: OutboxSendKind.conflict,
                statusCode: 409,
              ),
            _ => const OutboxSendResult(kind: OutboxSendKind.success),
          };

      final summary = await engine.flush();

      expect(summary.sent, 1);
      expect(summary.needsAttention, 2);
      expect(store.byId(a.id)!.status, OutboxStatus.failed);
      expect(store.byId(a.id)!.lastError, 'Invalid');
      expect(store.byId(b.id)!.status, OutboxStatus.conflict);
      expect(outbox.attentionCount, 2);
    });

    test('401 keeps the item pending and pauses the queue', () async {
      final a = await queue('/a');
      await queue('/b');
      transport.respond = (_) => const OutboxSendResult(
            kind: OutboxSendKind.unauthorized,
            statusCode: 401,
          );

      await engine.flush();

      expect(transport.calls.length, 1);
      expect(store.byId(a.id)!.status, OutboxStatus.pending);
      expect(store.items.length, 2);
    });

    test('gives up after the max number of network attempts', () async {
      final a = await queue('/a');
      await store.put(
        a.copyWith(attempts: OfflineConfig.maxNetworkAttempts - 1),
      );
      transport.respond = (_) => const OutboxSendResult(
            kind: OutboxSendKind.retryable,
            statusCode: 0,
          );

      await engine.flush(ignoreBackoff: true);

      expect(store.byId(a.id)!.status, OutboxStatus.failed);
    });

    test('only replays items owned by the signed-in user', () async {
      await queue('/mine');
      scope = const OutboxScope(userId: 'u2', tenant: 'acme');
      await queue('/theirs');
      scope = const OutboxScope(userId: 'u1', tenant: 'acme');

      await engine.flush();

      expect(transport.calls.map((c) => c.path), ['/mine']);
      expect(store.items.single.path, '/theirs');
      expect(outbox.unsentCount, 0);
    });

    test('does nothing while offline or signed out', () async {
      await queue('/a');
      online = false;
      await engine.flush();
      online = true;
      scope = null;
      await engine.flush();
      expect(transport.calls, isEmpty);
    });

    test('concurrent flushes share one run (single-flight)', () async {
      await queue('/a');
      transport.gate = Completer<void>();

      final first = engine.flush();
      final second = engine.flush();
      expect(engine.isRunning, isTrue);
      transport.gate!.complete();
      final results = await Future.wait([first, second]);

      expect(identical(results[0], results[1]), isTrue);
      expect(transport.calls.length, 1);
    });

    test('backoff grows exponentially with jitter and is capped', () {
      final base = OfflineConfig.backoffBase.inMilliseconds;
      final cap = OfflineConfig.backoffCap.inMilliseconds;
      for (var attempt = 1; attempt <= 12; attempt++) {
        final raw = min(base * pow(2, attempt - 1), cap.toDouble());
        final wait = engine.backoffFor(attempt).inMilliseconds;
        expect(wait, greaterThanOrEqualTo((raw * 0.5).floor()));
        expect(wait, lessThanOrEqualTo(raw.ceil()));
      }
    });

    test('retry, edit and discard', () async {
      final a = await queue('/a', body: {'notes': 'old'});
      await store.put(a.copyWith(
        status: OutboxStatus.failed,
        attempts: 3,
        lastError: 'x',
      ));

      await engine.updateBody(a.id, {'notes': 'new'});
      final edited = store.byId(a.id)!;
      expect(edited.jsonBody, {'notes': 'new'});
      expect(edited.status, OutboxStatus.pending);
      expect(edited.attempts, 0);

      await engine.discard(a.id);
      expect(store.items, isEmpty);
    });
  });

  group('Offline attachments', () {
    Future<Map<String, dynamic>> stagePhoto() async {
      final file = File('${tmp.path}/photo.jpg')
        ..writeAsBytesSync(List<int>.filled(32, 7));
      final staged = await outbox.stageUpload(
        form: FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: 'photo.jpg'),
        }),
        path: '/uploads',
        query: const {'category': 'daily-logs'},
      );
      expect(staged, isNotNull);
      return staged!;
    }

    test('staged file is uploaded first and its token replaced', () async {
      final staged = await stagePhoto();
      final token = staged['fileUrl'] as String;
      expect(StagedUploadStore.isToken(token), isTrue);
      expect(staged['fileName'], 'photo.jpg');

      final item = await queue('/daily-logs', body: {
        'notes': 'x',
        'attachments': [
          {'fileUrl': token, 'fileName': 'photo.jpg'},
        ],
      });
      expect(item.attachments, hasLength(1));
      expect(File(item.attachments.single.localPath).existsSync(), isTrue);

      transport.respond = (call) => call.path == '/uploads'
          ? const OutboxSendResult(
              kind: OutboxSendKind.success,
              body: {'data': {'fileUrl': 'https://cdn/x.jpg'}},
            )
          : const OutboxSendResult(kind: OutboxSendKind.success);

      await engine.flush();

      expect(transport.calls.map((c) => c.path), ['/uploads', '/daily-logs']);
      expect(transport.calls.first.data, isA<FormData>());
      expect(
        transport.calls.first.headers[OfflineConfig.idempotencyHeader],
        startsWith('${item.idempotencyKey}:'),
      );
      final sent = transport.calls.last.data as Map;
      expect((sent['attachments'] as List).first['fileUrl'], 'https://cdn/x.jpg');
      expect(store.items, isEmpty);
      expect(File(item.attachments.single.localPath).existsSync(), isFalse);
    });

    test('an upload that already succeeded is not repeated', () async {
      final staged = await stagePhoto();
      await queue('/daily-logs', body: {'fileUrl': staged['fileUrl']});
      transport.respond = (call) => call.path == '/uploads'
          ? const OutboxSendResult(
              kind: OutboxSendKind.success,
              body: {'url': 'https://cdn/y.jpg'},
            )
          : const OutboxSendResult(
              kind: OutboxSendKind.retryable,
              statusCode: 503,
            );

      await engine.flush();
      transport.respond = null;
      transport.calls.clear();
      await engine.flush(ignoreBackoff: true);

      expect(transport.calls.map((c) => c.path), ['/daily-logs']);
      expect((transport.calls.single.data as Map)['fileUrl'], 'https://cdn/y.jpg');
    });

    test('a placeholder without its file is never sent to the server',
        () async {
      await queue('/daily-logs', body: {
        'fileUrl': StagedUploadStore.tokenFor('missing-id', 'a.jpg'),
      });

      final summary = await engine.flush();

      expect(transport.calls, isEmpty);
      expect(summary.needsAttention, 1);
      expect(store.items.single.status, OutboxStatus.failed);
    });

    test('orphaned staged files are purged', () async {
      await stagePhoto();
      expect(uploadsBox.length, 1);
      await uploads.purgeOrphans(ttl: Duration.zero);
      expect(uploadsBox.length, 0);
    });
  });

  group('MAR duplicate guard', () {
    test('matches the same scheduled dose, not another slot', () async {
      await OutboxContext.run(
        () => queue('/mar/administrations', body: {
          'clientId': 'c1',
          'medicationId': 'm1',
        }),
        meta: {
          'doseId': 'dose-am',
          'clientId': 'c1',
          'medicationId': 'm1',
          'slot': 'Morning',
        },
      );

      expect(
        outbox.hasUnsentDose(
          doseId: 'dose-am',
          clientId: 'c1',
          medicationId: 'm1',
          slot: 'Morning',
        ),
        isTrue,
      );
      expect(
        outbox.hasUnsentDose(
          doseId: 'dose-pm',
          clientId: 'c1',
          medicationId: 'm1',
          slot: 'Evening',
        ),
        isFalse,
      );
    });

    test('legacy items without a dose id match by resident + medicine + day',
        () async {
      await queue('/mar/administrations', body: {
        'clientId': 'c1',
        'medicationId': 'm1',
      });
      expect(
        outbox.hasUnsentDose(
          doseId: 'dose-am',
          clientId: 'c1',
          medicationId: 'm1',
          slot: 'Morning',
        ),
        isTrue,
      );
      expect(
        outbox.hasUnsentDose(
          doseId: 'dose-x',
          clientId: 'c2',
          medicationId: 'm1',
          slot: 'Morning',
        ),
        isFalse,
      );
    });
  });

  test('status classification', () {
    expect(OutboxSendResult.classify(201), OutboxSendKind.success);
    expect(OutboxSendResult.classify(0), OutboxSendKind.retryable);
    expect(OutboxSendResult.classify(408), OutboxSendKind.retryable);
    expect(OutboxSendResult.classify(429), OutboxSendKind.retryable);
    expect(OutboxSendResult.classify(503), OutboxSendKind.retryable);
    expect(OutboxSendResult.classify(401), OutboxSendKind.unauthorized);
    expect(OutboxSendResult.classify(409), OutboxSendKind.conflict);
    expect(OutboxSendResult.classify(422), OutboxSendKind.rejected);
  });
}
