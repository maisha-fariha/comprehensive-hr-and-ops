import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:comprehensive_hr_and_ops/core/errors/app_error_dialog.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';
import 'package:comprehensive_hr_and_ops/core/network/connectivity_monitor.dart';
import 'package:comprehensive_hr_and_ops/core/network/offline_banner.dart';
import 'package:comprehensive_hr_and_ops/core/offline/offline_outbox.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_attachments.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_item.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_store.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_sync_engine.dart';
import 'package:comprehensive_hr_and_ops/core/offline/presentation/pending_changes_page.dart';
import 'package:comprehensive_hr_and_ops/core/offline/presentation/pending_outbox_section.dart';
import 'package:comprehensive_hr_and_ops/core/offline/presentation/pending_sync_chip.dart';
import 'package:comprehensive_hr_and_ops/core/offline/presentation/sign_out_guard.dart';
import 'package:comprehensive_hr_and_ops/core/offline/presentation/unsent_changes_tile.dart';

class _NoopTransport implements OutboxTransport {
  @override
  Future<OutboxSendResult> send({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    dynamic data,
    required Map<String, String> headers,
  }) async =>
      const OutboxSendResult(kind: OutboxSendKind.success);
}

void main() {
  late OfflineOutbox outbox;
  late ConnectivityMonitor monitor;
  var boxId = 0;

  Future<void> setUpOutbox(WidgetTester tester) async {
    await tester.runAsync(() async {
      boxId++;
      final store = OutboxStore(
        await Hive.openBox<String>('ui_outbox_$boxId', bytes: Uint8List(0)),
      );
      final uploads = StagedUploadStore(
        await Hive.openBox<String>('ui_uploads_$boxId', bytes: Uint8List(0)),
        rootDir: () async => Directory.systemTemp,
      );
      const scope = OutboxScope(userId: 'u1', tenant: 'acme');
      final engine = OutboxSyncEngine(
        store: store,
        uploads: uploads,
        transport: _NoopTransport(),
        scope: () => scope,
        isOnline: () => false,
      );
      outbox = OfflineOutbox(
        store: store,
        uploads: uploads,
        engine: engine,
        scope: () => scope,
      );
    });
    Get.put<OfflineOutbox>(outbox);
    monitor = Get.put(ConnectivityMonitor(probe: () async => true));
  }

  Future<OutboxItem> add(
    WidgetTester tester,
    String path, {
    Map<String, dynamic>? body,
    OutboxStatus status = OutboxStatus.pending,
    String? error,
  }) async {
    late OutboxItem item;
    await tester.runAsync(() async {
      item = (await outbox.enqueue(
        method: 'POST',
        path: path,
        data: body ?? {'notes': 'hello'},
        idempotencyKey: 'k-$path',
      ))!;
      if (status != OutboxStatus.pending || error != null) {
        item = item.copyWith(status: status, lastError: error);
        await outbox.store.put(item);
      }
    });
    return item;
  }

  Widget app(Widget child) => GetMaterialApp(
        home: Scaffold(body: child),
        getPages: [
          GetPage(
            name: '/pending-changes',
            page: () => const PendingChangesPage(),
          ),
        ],
      );

  tearDown(() async {
    Get.reset();
  });

  testWidgets('PendingSyncChip labels each status', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [
        PendingSyncChip(),
        PendingSyncChip(status: OutboxStatus.failed),
        PendingSyncChip(status: OutboxStatus.conflict),
      ]),
    ));
    expect(find.text('Pending sync'), findsOneWidget);
    expect(find.text('Not sent'), findsOneWidget);
    expect(find.text('Conflict'), findsOneWidget);
  });

  testWidgets('pending section and profile tile take no space when empty',
      (tester) async {
    await setUpOutbox(tester);
    await tester.pumpWidget(app(const Column(children: [
      PendingOutboxSection(features: {'daily-logs'}),
      UnsentChangesTile(),
    ])));
    expect(find.byKey(const Key('pending-outbox-section')), findsNothing);
    expect(find.byKey(const Key('unsent-changes-tile')), findsNothing);

    await add(tester, '/daily-logs');
    await tester.pump();
    expect(find.byKey(const Key('pending-outbox-section')), findsOneWidget);
    expect(find.text('1 change saved on this device'), findsOneWidget);
    expect(find.byKey(const Key('unsent-changes-tile')), findsOneWidget);
  });

  testWidgets('pending section only lists its own features', (tester) async {
    await setUpOutbox(tester);
    await add(tester, '/tasks');
    await tester.pumpWidget(app(const PendingOutboxSection(
      features: {'daily-logs'},
    )));
    expect(find.byKey(const Key('pending-outbox-section')), findsNothing);
  });

  group('sync banner', () {
    testWidgets('hidden while online with nothing pending', (tester) async {
      await setUpOutbox(tester);
      await tester.pumpWidget(app(const OfflineBanner()));
      expect(find.byKey(const Key('sync-banner-offline')), findsNothing);
      expect(find.byKey(const Key('sync-banner-waiting')), findsNothing);
      expect(find.byKey(const Key('sync-banner-attention')), findsNothing);
    });

    testWidgets('offline shows the saved-changes count', (tester) async {
      await setUpOutbox(tester);
      await add(tester, '/daily-logs');
      monitor.isOnline.value = false;
      await tester.pumpWidget(app(const OfflineBanner()));
      expect(find.byKey(const Key('sync-banner-offline')), findsOneWidget);
      expect(
        find.textContaining('You are offline. Showing last saved information.'),
        findsOneWidget,
      );
      expect(find.textContaining('1 change saved on this device'),
          findsOneWidget);
    });

    testWidgets('online with a failed item asks for review and opens the list',
        (tester) async {
      await setUpOutbox(tester);
      await add(tester, '/tasks', status: OutboxStatus.failed, error: 'Bad');
      await tester.pumpWidget(app(const OfflineBanner()));
      expect(find.byKey(const Key('sync-banner-attention')), findsOneWidget);
      expect(find.text('1 change needs attention'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sync-banner-attention')));
      await tester.pumpAndSettle();
      expect(find.text('Unsent changes'), findsOneWidget);
      expect(find.text('Bad'), findsOneWidget);
    });
  });

  group('Unsent changes page', () {
    testWidgets('empty state', (tester) async {
      await setUpOutbox(tester);
      await tester.pumpWidget(app(const PendingChangesPage()));
      expect(find.byKey(const Key('pending-changes-empty')), findsOneWidget);
    });

    testWidgets('discard asks first, then removes the item', (tester) async {
      await setUpOutbox(tester);
      final item = await add(tester, '/daily-logs');
      await tester.pumpWidget(app(const PendingChangesPage()));
      expect(find.byKey(Key('outbox-item-${item.id}')), findsOneWidget);

      await tester.tap(find.byKey(Key('outbox-discard-${item.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('discard-change-dialog')), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('discard-change-confirm')));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();

      expect(outbox.store.items, isEmpty);
      expect(find.byKey(const Key('pending-changes-empty')), findsOneWidget);
    });

    testWidgets('edit updates the queued text and resets the status',
        (tester) async {
      await setUpOutbox(tester);
      final item = await add(
        tester,
        '/daily-logs',
        body: {'notes': 'tpyo', 'clientId': 'c1'},
        status: OutboxStatus.failed,
        error: 'Rejected',
      );
      await tester.pumpWidget(app(const PendingChangesPage()));

      await tester.tap(find.byKey(Key('outbox-edit-${item.id}')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-change-field-notes')),
        'typo fixed',
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('edit-change-save')));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();

      final updated = outbox.store.byId(item.id)!;
      expect(updated.jsonBody, {'notes': 'typo fixed', 'clientId': 'c1'});
      expect(updated.status, OutboxStatus.pending);
      expect(updated.lastError, isNull);
    });

    testWidgets('no Edit button when there is no text to correct',
        (tester) async {
      await setUpOutbox(tester);
      final item = await add(tester, '/attendance/clock-in', body: {'lat': 1});
      await tester.pumpWidget(app(const PendingChangesPage()));
      expect(find.byKey(Key('outbox-edit-${item.id}')), findsNothing);
      expect(find.byKey(Key('outbox-retry-${item.id}')), findsOneWidget);
    });
  });

  group('sign-out guard', () {
    testWidgets('no prompt when nothing is waiting', (tester) async {
      await setUpOutbox(tester);
      await tester.pumpWidget(app(const SizedBox()));
      late bool ok;
      await tester.runAsync(() async => ok = await SignOutGuard.confirm());
      expect(ok, isTrue);
      expect(find.byKey(const Key('sign-out-unsent-dialog')), findsNothing);
    });

    testWidgets('warns about unsent changes and keeps them on "stay"',
        (tester) async {
      await setUpOutbox(tester);
      await add(tester, '/daily-logs');
      await add(tester, '/tasks');
      await tester.pumpWidget(app(const SizedBox()));

      bool? result;
      SignOutGuard.confirm().then((v) => result = v);
      await tester.pumpAndSettle();
      expect(find.text('2 changes not yet sent'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sign-out-unsent-stay')));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(outbox.unsentCount, 2);

      SignOutGuard.confirm().then((v) => result = v);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sign-out-unsent-confirm')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(outbox.unsentCount, 2);
    });
  });

  group('offline errors', () {
    tearDown(() => AppErrorDialog.inlineOfflineNotices = false);

    testWidgets('are a non-blocking notice once offline mode runs',
        (tester) async {
      AppErrorDialog.inlineOfflineNotices = true;
      await tester.pumpWidget(app(const SizedBox()));
      unawaited(AppErrorDialog.showError(
        const NetworkError(message: 'x', code: 'offline_uncached'),
      ));
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Not on this device yet'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('server errors still use the dialog', (tester) async {
      AppErrorDialog.inlineOfflineNotices = true;
      await tester.pumpWidget(app(const SizedBox()));
      unawaited(AppErrorDialog.showError(
        const ApiError(message: 'Boom', statusCode: 500),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Care home is unavailable'), findsOneWidget);
      expect(find.byType(AppSheetDialog), findsOneWidget);
    });
  });
}
