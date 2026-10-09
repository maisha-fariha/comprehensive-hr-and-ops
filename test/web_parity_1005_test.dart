import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import 'package:comprehensive_hr_and_ops/features/hr/team_reports/data/mappers/team_reports_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/team_reports/domain/entities/staff_sensitive.dart';
import 'package:comprehensive_hr_and_ops/features/hr/team_reports/domain/repositories/team_reports_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/team_reports/presentation/widgets/staff_sensitive_card.dart';
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
  title: 'Fire door check',
  dueTimeLabel: '8:00 AM',
  location: 'Sunrise Home',
  status: TaskStatus.pending,
);

class _TasksRepo implements StaffTasksMessagesRepository {
  final bool requiresSignOff;
  final completions = <bool>[];

  _TasksRepo({required this.requiresSignOff});

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
      Result.success(StaffTaskDetail(
        id: taskId,
        title: _task.title,
        statusRaw: 'pending',
        requiresSignOff: requiresSignOff,
      ));

  @override
  Future<Result<void>> completeTask(String taskId, {bool signOff = false}) async {
    completions.add(signOff);
    return Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SensitiveRepo implements TeamReportsRepository {
  StaffSensitive current;
  final reveals = <bool>[];
  final updates = <Map<String, dynamic>>[];

  _SensitiveRepo(this.current);

  @override
  Future<Result<StaffSensitive>> getStaffSensitive(
    String staffId, {
    bool reveal = false,
  }) async {
    reveals.add(reveal);
    if (!reveal) return Result.success(current);
    return Result.success(const StaffSensitive(
      revealed: true,
      sinOnFile: true,
      sinValue: '046454286',
      bankingOnFile: true,
      institutionNumber: '001',
      transitNumber: '12345',
      accountNumber: '1234567',
    ));
  }

  @override
  Future<Result<StaffSensitive>> updateStaffSensitive(
    String staffId,
    Map<String, dynamic> body,
  ) async {
    updates.add(body);
    return Result.success(current);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _onFile = StaffSensitive(
  sinOnFile: true,
  sinMasked: '••• ••• 286',
  bankingOnFile: true,
  accountMasked: '••••567',
);

void main() {
  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('task sign-off', () {
    Future<_TasksRepo> openSheet(
      WidgetTester tester, {
      required bool requiresSignOff,
    }) async {
      phone(tester);
      final repo = _TasksRepo(requiresSignOff: requiresSignOff);
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
      return repo;
    }

    testWidgets('a sign-off task completes only after the confirmation',
        (tester) async {
      final repo = await openSheet(tester, requiresSignOff: true);

      expect(find.text('Complete'), findsNothing);
      expect(find.byKey(const Key('task-sign-off')), findsOneWidget);
      final submit = find.byKey(const Key('task-sign-off-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(repo.completions, isEmpty);

      await tester.tap(find.byKey(const Key('task-sign-off-confirm')));
      await tester.pump();
      await tester.tap(submit);
      await tester.pump();
      expect(repo.completions, [true]);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a normal task keeps the plain Complete button',
        (tester) async {
      final repo = await openSheet(tester, requiresSignOff: false);

      expect(find.byKey(const Key('task-sign-off')), findsNothing);
      await tester.tap(find.text('Complete'));
      await tester.pump();
      expect(repo.completions, [false]);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('SIN & banking', () {
    Future<_SensitiveRepo> pumpCard(
      WidgetTester tester, {
      StaffSensitive data = _onFile,
      bool canWrite = true,
    }) async {
      phone(tester);
      final repo = _SensitiveRepo(data);
      GetIt.I.registerSingleton<TeamReportsRepository>(repo);
      await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StaffSensitiveCard(staffId: 's1', canWrite: canWrite),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return repo;
    }

    test('maps the masked and revealed API shapes', () {
      final masked = TeamReportsMapper.staffSensitiveFrom({
        'success': true,
        'data': {
          'staffId': 's1',
          'revealed': false,
          'sin': {'onFile': true, 'masked': '••• ••• 286', 'value': null},
          'banking': {
            'onFile': false,
            'accountMasked': null,
            'institutionNumber': null,
            'transitNumber': null,
            'accountNumber': null,
          },
        },
      });
      expect(masked.sinLabel, '••• ••• 286');
      expect(masked.institutionLabel, 'Not on file');
      expect(masked.accountLabel, 'Not on file');

      final revealed = TeamReportsMapper.staffSensitiveFrom({
        'revealed': true,
        'sin': {'onFile': true, 'value': '046454286'},
        'banking': {
          'onFile': true,
          'institutionNumber': '001',
          'transitNumber': '12345',
          'accountNumber': '1234567',
        },
      });
      expect(revealed.sinLabel, '046 454 286');
      expect(revealed.transitLabel, '12345');
    });

    testWidgets('shows masked numbers and reveals then hides them',
        (tester) async {
      final repo = await pumpCard(tester);

      expect(find.text('••• ••• 286'), findsOneWidget);
      expect(find.text('•••'), findsOneWidget);
      expect(find.text('••••567'), findsOneWidget);
      expect(find.text('Viewing the full numbers is logged.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('staff-sensitive-reveal')));
      await tester.pumpAndSettle();
      expect(repo.reveals, [false, true]);
      expect(find.text('046 454 286'), findsOneWidget);
      expect(find.text('1234567'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('staff-sensitive-hide')));
      await tester.pumpAndSettle();
      expect(find.text('046 454 286'), findsNothing);
      expect(find.text('••• ••• 286'), findsOneWidget);
    });

    Future<void> tapSave(WidgetTester tester) async {
      final save = find.byKey(const ValueKey('staff-sensitive-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
    }

    testWidgets('edit follows the web rules for blank and partial banking',
        (tester) async {
      final repo = await pumpCard(tester);

      await tester.tap(find.byKey(const ValueKey('staff-sensitive-edit')));
      await tester.pumpAndSettle();
      await tapSave(tester);
      await tester.pump();
      expect(
        find.text('Type a new SIN or new banking details — blank boxes keep '
            'what is on file.'),
        findsOneWidget,
      );

      await tester.enterText(
          find.byKey(const ValueKey('staff-sensitive-transit')), '12345');
      await tapSave(tester);
      await tester.pump();
      expect(
        find.text(
            'Banking needs all three: institution, transit and account number.'),
        findsOneWidget,
      );
      expect(repo.updates, isEmpty);

      await tester.enterText(
          find.byKey(const ValueKey('staff-sensitive-sin')), ' 123456789 ');
      await tester.enterText(
          find.byKey(const ValueKey('staff-sensitive-institution')), '001');
      await tester.enterText(
          find.byKey(const ValueKey('staff-sensitive-account')), '7654321');
      await tapSave(tester);
      await tester.pump();
      expect(repo.updates.single, {
        'sin': '123456789',
        'banking': {
          'institutionNumber': '001',
          'transitNumber': '12345',
          'accountNumber': '7654321',
        },
      });
      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(const ValueKey('staff-sensitive-save')), findsNothing);
    });

    testWidgets('read-only users cannot edit; nothing on file hides Reveal',
        (tester) async {
      await pumpCard(
        tester,
        data: const StaffSensitive(),
        canWrite: false,
      );

      expect(find.text('Not on file'), findsNWidgets(4));
      expect(find.byKey(const ValueKey('staff-sensitive-reveal')), findsNothing);
      expect(find.byKey(const ValueKey('staff-sensitive-edit')), findsNothing);
    });
  });
}
