import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:hive_ce/hive_ce.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/network/connectivity_monitor.dart';
import 'package:comprehensive_hr_and_ops/core/network/response_cache.dart';
import 'package:comprehensive_hr_and_ops/core/network/tenant_store.dart';
import 'package:comprehensive_hr_and_ops/core/offline/offline_crawler.dart';
import 'package:comprehensive_hr_and_ops/core/offline/offline_outbox.dart';
import 'package:comprehensive_hr_and_ops/core/offline/offline_overlay.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_attachments.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_item.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_store.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_sync_engine.dart';

OutboxItem _item(
  String method,
  String path, {
  dynamic body,
  String? tempId,
  OutboxStatus status = OutboxStatus.pending,
  String tag = 'other',
  int seq = 1,
}) =>
    OutboxItem(
      id: 'item-$seq',
      seq: seq,
      userId: 'u1',
      tenant: 'acme',
      method: method,
      path: path,
      jsonBody: body,
      idempotencyKey: 'k$seq',
      occurredAt: DateTime.utc(2026, 10, 5, 9),
      createdAt: DateTime.utc(2026, 10, 5, 9),
      featureTag: tag,
      label: 'change',
      status: status,
      meta: {'tempId': ?tempId},
    );

class _Req {
  final String method;
  final String path;
  final dynamic data;
  _Req(this.method, this.path, this.data);
}

/// Records requests; answers from [handler] (default: 200 with `{}`).
class _FakeApi implements ApiService {
  final List<_Req> requests = [];
  ApiResponse<dynamic> Function(_Req req)? handler;

  ApiResponse<T> _answer<T>(String method, String path, dynamic data) {
    final req = _Req(method, path, data);
    requests.add(req);
    final res = handler?.call(req) ??
        ApiResponse<dynamic>.success(<String, dynamic>{}, statusCode: 200);
    return ApiResponse<T>(
      success: res.success,
      data: res.data as T?,
      message: res.message,
      statusCode: res.statusCode,
      errors: res.errors,
    );
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async =>
      _answer<T>('GET', endpoint, null);

  @override
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async =>
      _answer<T>('POST', endpoint, data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineOverlay', () {
    test('a create made offline appears in the saved list, newest-first kept',
        () {
      final body = {
        'data': [
          {'id': 'b', 'createdAt': '2026-10-04T10:00:00Z'},
          {'id': 'a', 'createdAt': '2026-10-01T10:00:00Z'},
        ],
      };
      final out = OfflineOverlay.apply(
        path: '/incidents',
        body: body,
        items: [
          _item('POST', '/incidents', body: {'title': 'Fall'}, tempId: 'offline-1'),
        ],
      );
      final list = (out as Map)['data'] as List;
      expect(list.first['id'], 'offline-1');
      expect(list.first['title'], 'Fall');
      expect(list.first['offlinePending'], isTrue);
    });

    test('oldest-first lists (threads) get the new item at the end', () {
      final out = OfflineOverlay.apply(
        path: '/conversations/c1/messages',
        body: [
          {'id': 'm1', 'createdAt': '2026-10-01T10:00:00Z'},
          {'id': 'm2', 'createdAt': '2026-10-02T10:00:00Z'},
        ],
        items: [
          _item('POST', '/conversations/c1/messages',
              body: {'body': 'Hi'}, tempId: 'offline-m'),
        ],
      ) as List;
      expect(out.last['body'], 'Hi');
      expect(out.length, 3);
    });

    test('edits merge into the list row and the detail; deletes remove', () {
      final list = OfflineOverlay.apply(
        path: '/tasks',
        body: {
          'items': [
            {'id': 't1', 'status': 'open'},
            {'id': 't2', 'status': 'open'},
          ],
        },
        items: [
          _item('PATCH', '/tasks/t1', body: {'status': 'completed'}, seq: 1),
          _item('DELETE', '/tasks/t2', seq: 2),
        ],
      ) as Map;
      expect(list['items'], [
        {'id': 't1', 'status': 'completed'},
      ]);

      final detail = OfflineOverlay.apply(
        path: '/tasks/t1',
        body: {
          'data': {'id': 't1', 'status': 'open', 'title': 'Mop'},
        },
        items: [_item('PATCH', '/tasks/t1', body: {'status': 'completed'})],
      ) as Map;
      expect(detail['data'], {'id': 't1', 'status': 'completed', 'title': 'Mop'});
    });

    test('changes that need attention and skipped features are not shown', () {
      final out = OfflineOverlay.apply(
        path: '/daily-logs',
        body: <dynamic>[],
        items: [
          _item('POST', '/daily-logs', body: {'a': 1}, tag: 'daily-logs'),
          _item('POST', '/daily-logs',
              body: {'b': 1}, status: OutboxStatus.failed, seq: 2),
        ],
        skipAppendTags: {'daily-logs'},
      );
      expect(out, isEmpty);
    });

    test('records created offline carry the signed-in author', () {
      OfflineOverlay.currentAuthor = () => {'id': 'u1', 'name': 'Sam'};
      addTearDown(() => OfflineOverlay.currentAuthor = null);
      final record = OfflineOverlay.recordFor(
        _item('POST', '/conversations/c1/messages',
            body: {'body': 'Hi'}, tempId: 'offline-m'),
      );
      expect(record['senderId'], 'u1');
      expect(record['sender'], {'id': 'u1', 'name': 'Sam'});
      final update = OfflineOverlay.recordFor(
        _item('PATCH', '/tasks/abc123/status', body: {'status': 'done'}),
      );
      expect(update['id'], 'abc123');
      expect(update.containsKey('senderId'), isFalse);
    });
  });

  group('OfflineCrawler', () {
    final now = DateTime(2026, 10, 5, 12);
    CachedRequest req(
      String path, {
      Map<String, String> query = const {},
      DateTime? savedAt,
      bool time = false,
    }) =>
        CachedRequest(
          path: path,
          query: query,
          savedAt: savedAt ?? now.subtract(const Duration(hours: 1)),
          lastAccess: savedAt ?? now.subtract(const Duration(hours: 1)),
          hasTimeParams: time,
        );

    test('learns per-record views from one opened record', () {
      final templates = OfflineCrawler.templates([
        req('/conversations/0b6f1c2e-1111-4a5b-9c8d-123456789abc/messages'),
        req('/incidents/clx9a8b7c6d5e4f3/activity'),
        req('/mar/due/2026-10-05'),
        req('/files/t1/docs/a.pdf'),
        req('/shifts/abc12345', time: true),
      ]);
      expect(
        templates.map((t) => t.key).toSet(),
        {'/conversations/{id}/messages?', '/incidents/{id}/activity?'},
      );
      expect(templates.first.pathFor('x9'), '/conversations/x9/messages');
    });

    test('refreshes opened screens, never links, searches or stale windows',
        () {
      final plan = OfflineCrawler.refreshPlan([
        req('/clients', query: {'page': '1'}),
        req('/clients', query: {'search': 'ann'}),
        req('/incidents/1/cir-pdf-link'),
        req('/shifts', time: true, savedAt: now.subtract(const Duration(days: 2))),
        req('/shifts', time: true),
        req('/residences', savedAt: now.subtract(const Duration(minutes: 2))),
      ], now: now);
      expect(plan.map((r) => '${r.path}${r.query}').toList(),
          ['/clients{page: 1}', '/shifts{}']);
    });

    test('reads record ids from wrapped lists', () {
      expect(
        OfflineCrawler.idsIn({
          'data': {
            'items': [
              {'id': 'c1234567'},
              {'id': '42'},
              {'name': 'no id'},
            ],
          },
        }),
        ['c1234567', '42'],
      );
    });
  });

  group('AppApiClient offline', () {
    late Directory tmp;
    late _FakeApi api;
    late AppApiClient client;
    late ConnectivityMonitor monitor;
    late OfflineOutbox outbox;
    late ResponseCache cache;
    var boxId = 0;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('offline_everywhere');
      Hive.init(tmp.path);
      boxId++;
      SharedPreferences.setMockInitialValues({});
      final tenant = TenantStore(await SharedPreferences.getInstance());
      api = _FakeApi();
      monitor = ConnectivityMonitor(probe: () async => true);
      cache = ResponseCache(
        values: await Hive.openBox<String>('c_$boxId', bytes: Uint8List(0)),
        meta: await Hive.openBox<String>('cm_$boxId', bytes: Uint8List(0)),
        scope: () => 'acme|u1',
      );
      client = AppApiClient(api, tenant, cache: cache, connectivity: monitor);
      final store = OutboxStore(
        await Hive.openBox<String>('o_$boxId', bytes: Uint8List(0)),
      );
      final uploads = StagedUploadStore(
        await Hive.openBox<String>('u_$boxId', bytes: Uint8List(0)),
        rootDir: () async => tmp,
      );
      const scope = OutboxScope(userId: 'u1', tenant: 'acme');
      final engine = OutboxSyncEngine(
        store: store,
        uploads: uploads,
        transport: client,
        scope: () => scope,
        isOnline: () => monitor.online,
      );
      outbox = OfflineOutbox(
        store: store,
        uploads: uploads,
        engine: engine,
        scope: () => scope,
      );
      client.outbox = outbox;
    });

    tearDown(() async {
      outbox.engine.dispose();
      Get.reset();
      await Hive.close();
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('writes marked allowQueue:false are kept offline with a usable reply',
        () async {
      monitor.isOnline.value = false;
      final result = await client.post(
        '/conversations',
        data: {'type': 'direct', 'title': 'Night shift'},
        allowQueue: false,
      );
      expect(result.isSuccess, isTrue);
      final body = result.value as Map;
      expect(body['offlineQueued'], isTrue);
      expect(body['title'], 'Night shift');
      expect('${body['id']}', startsWith('offline-'));
      expect(api.requests, isEmpty);
      expect(outbox.store.items.single.path, '/conversations');
    });

    test('sign-in and other excluded writes still fail offline', () async {
      monitor.isOnline.value = false;
      final result = await client.post(
        '/mobile/auth/login',
        data: {'email': 'a'},
        allowQueue: false,
      );
      expect(result.isFailure, isTrue);
      expect(outbox.store.items, isEmpty);
    });

    test('create offline, add to it offline, then sync with the server id',
        () async {
      monitor.isOnline.value = false;
      final created = await client.post(
        '/conversations',
        data: {'title': 'Night shift'},
        allowQueue: false,
      );
      final tempId = '${(created.value as Map)['id']}';
      await client.post(
        '/conversations/$tempId/messages',
        data: {'body': 'Hello'},
        allowQueue: false,
      );

      final thread = await client.get('/conversations/$tempId/messages');
      expect((thread.value as List).single['body'], 'Hello');
      expect(api.requests, isEmpty);

      api.handler = (req) => req.path == '/conversations'
          ? ApiResponse<dynamic>.success({
              'data': {'id': 'srv-1'},
            }, statusCode: 201)
          : ApiResponse<dynamic>.success(<String, dynamic>{}, statusCode: 201);
      monitor.isOnline.value = true;
      final summary = await outbox.engine.flush(ignoreBackoff: true);

      expect(summary.sent, 2);
      expect(api.requests.map((r) => r.path).toList(),
          ['/conversations', '/conversations/srv-1/messages']);
      expect(outbox.engine.resolvedTempIds[tempId], 'srv-1');

      api.requests.clear();
      api.handler = null;
      await client.get('/conversations/$tempId/messages');
      expect(api.requests.single.path, '/conversations/srv-1/messages');
    });

    test('online writes that point at an unsent record wait in the queue',
        () async {
      monitor.isOnline.value = false;
      final created = await client.post('/tasks', data: {'title': 'Mop'});
      final tempId = '${(created.value as Map)['id']}';
      api.handler = (_) => const ApiResponse<dynamic>(
            success: false,
            statusCode: 503,
          );
      monitor.isOnline.value = true;
      await client.post('/tasks/$tempId/notes', data: {'body': 'Done'});
      await outbox.engine.flush();
      expect(api.requests.map((r) => r.path), ['/tasks']);
      expect(
        outbox.store.items.map((i) => i.path).toList(),
        ['/tasks', '/tasks/$tempId/notes'],
      );
    });

    test('saved lists show offline creates and edits', () async {
      await cache.put(
        method: 'GET',
        path: '/appointments',
        body: {
          'data': [
            {'id': 'a1', 'status': 'pending'},
          ],
        },
      );
      monitor.isOnline.value = false;
      await client.patch(
        '/appointments/a1',
        data: {'status': 'approved'},
        allowQueue: false,
      );
      await client.post('/appointments', data: {'title': 'GP visit'});

      final list = await client.get('/appointments');
      final rows = (list.value as Map)['data'] as List;
      expect(rows.first, containsPair('status', 'approved'));
      expect(rows.last, containsPair('title', 'GP visit'));
    });

    Future<FormData> form(String name) async {
      final file = File('${tmp.path}/$name')..writeAsBytesSync([1, 2, 3]);
      return FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: name),
      });
    }

    test('file uploads made offline are kept on the device', () async {
      monitor.isOnline.value = false;
      final result = await client.post(
        '/uploads',
        data: await form('photo.jpg'),
        query: const {'category': 'incidents'},
        allowQueue: false,
      );
      expect(result.isSuccess, isTrue);
      final url = '${(result.value as Map)['fileUrl']}';
      expect(StagedUploadStore.isToken(url), isTrue);
      expect(api.requests, isEmpty);

      final local = outbox.localPathForUpload(url);
      expect(local, isNotNull);
      expect(File(local!).readAsBytesSync(), [1, 2, 3]);

      await client.post('/incidents', data: {'evidence': url});
      expect(outbox.store.items.single.attachments, hasLength(1));
      expect(outbox.localPathForUpload(url), local);
    });

    test('avatar uploads are not kept offline', () async {
      monitor.isOnline.value = false;
      final result = await client.post(
        '/uploads',
        data: await form('me.jpg'),
        query: const {'category': 'avatars'},
        allowQueue: false,
        silent: true,
      );
      expect(result.isFailure, isTrue);
      expect(api.requests, isEmpty);
    });
  });
}
