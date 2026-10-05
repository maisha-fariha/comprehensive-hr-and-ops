import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:comprehensive_hr_and_ops/core/errors/app_error_mapper.dart';
import 'package:comprehensive_hr_and_ops/core/offline/offline_outbox.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_attachments.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_store.dart';
import 'package:comprehensive_hr_and_ops/core/offline/outbox_sync_engine.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/staff_task.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/staff_task_detail.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/task_stats.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/tasks_messages_enums.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/tasks_messages_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/repositories/staff_tasks_messages_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/presentation/controllers/tasks_messages_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/presentation/widgets/staff_task_detail_sheet.dart';

const _task = StaffTask(
  id: 't1',
  title: 'Restock kitchen',
  dueTimeLabel: '8:00 AM',
  location: 'Sunrise Home',
  status: TaskStatus.pending,
);

class _OfflineRepo implements StaffTasksMessagesRepository {
  final AppError detailError;
  _OfflineRepo(this.detailError);

  @override
  Future<Result<TasksMessagesOverview>> getOverview() async => Result.success(
        const TasksMessagesOverview(
          tasks: [_task],
          conversations: [],
          stats: TaskStats(),
        ),
      );

  @override
  Future<Result<StaffTaskDetail>> getTaskDetail(String taskId) async =>
      Result.failure(detailError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  final offlineUncached = AppErrorMapper.toFriendly(
    const NetworkError(message: 'No connection', code: 'offline_uncached'),
  );
  var boxId = 0;

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  Future<TasksMessagesController> openSheet(
    WidgetTester tester,
    AppError detailError,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _OfflineRepo(detailError);
    GetIt.I.registerSingleton<StaffTasksMessagesRepository>(repo);
    final controller = TasksMessagesController(repository: repo);

    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showStaffTaskDetailSheet(
              context,
              taskId: _task.id,
              controller: controller,
              summary: _task,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('offline with no saved detail shows the list summary, not an '
      'error', (tester) async {
    await openSheet(tester, offlineUncached);

    expect(find.byKey(const Key('task-detail-offline-summary')), findsOneWidget);
    expect(find.text('Restock kitchen'), findsOneWidget);
    expect(find.text('Due: 8:00 AM'), findsOneWidget);
    expect(find.text('Sunrise Home'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.textContaining('could not reach'), findsNothing);
  });

  testWidgets('a real server error still shows the error with Retry',
      (tester) async {
    await openSheet(
      tester,
      const ApiError(message: 'Task not found.', statusCode: 404),
    );

    expect(find.byKey(const Key('task-detail-offline-summary')), findsNothing);
    expect(find.text('Task not found.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('completion and notes made offline show as pending sync',
      (tester) async {
    late OfflineOutbox outbox;
    await tester.runAsync(() async {
      boxId++;
      final store = OutboxStore(
        await Hive.openBox<String>('sheet_outbox_$boxId', bytes: Uint8List(0)),
      );
      final uploads = StagedUploadStore(
        await Hive.openBox<String>('sheet_uploads_$boxId', bytes: Uint8List(0)),
        rootDir: () async => Directory.systemTemp,
      );
      const scope = OutboxScope(userId: 'u1', tenant: 'acme');
      outbox = OfflineOutbox(
        store: store,
        uploads: uploads,
        engine: OutboxSyncEngine(
          store: store,
          uploads: uploads,
          transport: _NoopTransport(),
          scope: () => scope,
          isOnline: () => false,
        ),
        scope: () => scope,
      );
      await outbox.enqueue(
        method: 'POST',
        path: '/tasks/t1/notes',
        data: {'body': 'Fridge restocked'},
        idempotencyKey: 'k-note',
      );
      await outbox.enqueue(
        method: 'PATCH',
        path: '/tasks/t1',
        data: {'status': 'completed'},
        idempotencyKey: 'k-done',
      );
    });
    Get.put<OfflineOutbox>(outbox);

    final controller = await openSheet(tester, offlineUncached);

    expect(controller.pendingCompletedTaskIds, {'t1'});
    expect(controller.filteredTasks.single.status, TaskStatus.done);
    expect(find.text('Completed · pending sync'), findsOneWidget);
    expect(find.text('Fridge restocked'), findsOneWidget);
  });
}
