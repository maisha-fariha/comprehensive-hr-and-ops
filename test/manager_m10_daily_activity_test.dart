import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_activity/data/mappers/daily_activity_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_activity/data/repositories/daily_activity_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_activity/domain/entities/daily_activity.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_activity/domain/repositories/daily_activity_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_activity/presentation/controllers/daily_activity_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_activity/presentation/daily_activity_labels.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_activity/presentation/pages/daily_activity_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

Future<void> _loadOutfitFont() async {
  final data = await rootBundle.load('assets/fonts/outfit/Outfit-Variable.ttf');
  final loader = FontLoader('Outfit')..addFont(Future.value(data));
  await loader.load();
}

Widget _app(Widget home) => ScreenUtilInit(
      designSize: const Size(ResponsiveHelper.baseWidth, ResponsiveHelper.baseHeight),
      minTextAdapt: true,
      builder: (_, _) => GetMaterialApp(
        home: home,
        theme: ThemeData(
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
      ),
    );

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _inKey(String key, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: matching);

Future<void> _choose(WidgetTester tester, String key, String option) async {
  await _tap(tester, find.byKey(ValueKey(key)));
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

class _Session extends UserSession {
  final Set<String> denied;

  _Session({this.denied = const {}});

  @override
  bool can(String permission) => !denied.contains(permission);
}

final _pending = DailyActivity(
  id: 'f4672d0b-1547-426a-959f-1a9e28facab6',
  clientId: 'c1',
  clientName: 'Puchan Indha',
  clientResidence: 'Mala Box',
  clientLevel: 'High',
  activityType: 'care_activity',
  status: 'pending_review',
  description: 'Walked to the park with staff.',
  notes: 'Asked to go again tomorrow.',
  recordedByStaffId: 's1',
  recordedByStaffName: 'Shakib Hasan',
  authorName: 'Jamal Uddin',
  activityDate: '2026-09-29',
  occurredAt: DateTime(2026, 9, 29, 14, 30),
  createdAt: DateTime(2026, 9, 29, 15, 0),
  updatedAt: DateTime(2026, 9, 29, 16, 5),
  attachments: const [
    DailyActivityAttachment(fileUrl: '/files/a.pdf', fileType: 'park-photo.pdf'),
  ],
);

const _school = DailyActivity(
  id: '46678cb6-3a7a-4af4-97f3-3c82f1b04bc7',
  clientId: 'c2',
  clientName: 'Ayaan Karim',
  clientResidence: 'Elm House',
  clientLevel: 'medium',
  activityType: 'school',
  status: 'present',
  authorName: 'Jamal Uddin',
  activityDate: '2026-08-27',
);

class _FakeRepo implements DailyActivityRepository {
  List<DailyActivity> rows = [_pending, _school];
  int total = 2;
  bool failList = false;
  String? saveError;
  DailyActivityStats stats = const DailyActivityStats(
    todaysActivities: 5,
    activeClients: 3,
    staffEntries: 4,
    pendingReview: 1,
  );
  DailyActivityMonthSummary summary = const DailyActivityMonthSummary(
    byStatus: [('completed', 8), ('present', 2)],
    byType: [('care_activity', 7), ('school', 2)],
  );
  final List<Map<String, Object?>> listQueries = [];
  final List<String> calls = [];
  DailyActivityDraft? created;
  (String, DailyActivityDraft)? updated;
  final List<String> uploads = [];

  @override
  Future<Result<DailyActivityListResult>> list({
    required int page,
    required int limit,
    String? search,
    String? clientId,
    String? recordedByStaffId,
    String? activityType,
    String? status,
    String? from,
    String? to,
  }) async {
    listQueries.add({
      'page': page,
      'limit': limit,
      'search': search,
      'clientId': clientId,
      'staff': recordedByStaffId,
      'type': activityType,
      'status': status,
      'from': from,
      'to': to,
    });
    if (failList) return Result.failure(const ApiError(message: 'Server unreachable'));
    final items = clientId == null ? rows : rows.where((r) => r.clientId == clientId).toList();
    return Result.success(
      DailyActivityListResult(
        items: items,
        total: clientId == null ? total : items.length,
        totalPages: 1,
        stats: stats,
      ),
    );
  }

  @override
  Future<Result<DailyActivityMonthSummary>> monthSummary({
    required String clientId,
    required String month,
  }) async {
    calls.add('summary $clientId $month');
    return Result.success(summary);
  }

  @override
  Future<Result<void>> create(DailyActivityDraft draft) async {
    if (saveError != null) return Result.failure(ApiError(message: saveError!));
    created = draft;
    return Result.success(null);
  }

  @override
  Future<Result<void>> update(String id, DailyActivityDraft draft) async {
    updated = (id, draft);
    return Result.success(null);
  }

  @override
  Future<Result<void>> markReviewed(String id) async {
    calls.add('reviewed $id');
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    calls.add('delete $id');
    return Result.success(null);
  }

  @override
  Future<Result<List<DailyActivityOption>>> clients() async => Result.success(const [
        DailyActivityOption(
          id: 'c1',
          name: 'Puchan Indha',
          subtitle: 'Mala Box · Room 30',
          residenceName: 'Mala Box',
          level: 'High',
        ),
        DailyActivityOption(
          id: 'c2',
          name: 'Ayaan Karim',
          subtitle: 'Elm House',
          residenceName: 'Elm House',
          level: 'medium',
        ),
      ]);

  @override
  Future<Result<List<DailyActivityOption>>> staff() async => Result.success(const [
        DailyActivityOption(id: 's1', name: 'Shakib Hasan', subtitle: 'Staff'),
        DailyActivityOption(id: 's2', name: 'Ruma Begum', subtitle: 'Care worker'),
      ]);

  @override
  Future<Result<String>> upload(DailyActivityLocalFile file) async {
    uploads.add(file.name);
    return Result.success('/files/${file.name}');
  }

  @override
  Future<Result<List<int>>> download(String fileUrl) async => Result.success(const [1]);
}

Future<_FakeRepo> _open(
  WidgetTester tester, {
  _FakeRepo? repo,
  Set<String> denied = const {},
  DailyActivityPage page = const DailyActivityPage(),
}) async {
  _tallView(tester);
  final fake = repo ?? _FakeRepo();
  final session = _Session(denied: denied);
  GetIt.I.registerFactory<DailyActivityController>(
    () => DailyActivityController(
      repository: fake,
      session: session,
      now: () => DateTime(2026, 9, 30, 10),
    ),
  );
  await tester.pumpWidget(_app(page));
  await tester.pumpAndSettle();
  return fake;
}

class _FakeApi implements AppApiClient {
  final List<(String, String, Map<String, dynamic>?, Object?)> requests = [];

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) async {
    requests.add(('GET', path, query, null));
    return Result.success({'success': true, 'data': [], 'meta': {'total': 0}});
  }

  @override
  Future<Result<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) async {
    requests.add(('PATCH', path, query, data));
    return Result.success({'success': true});
  }

  @override
  Future<Result<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) async {
    requests.add(('DELETE', path, query, data));
    return Result.success({'success': true});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('data', () {
    test('mapper reads the live /client-activities payload and meta.summary', () {
      final page = DailyActivityMapper.pageFrom({
        'success': true,
        'data': [
          {
            'id': '69fdb3e6-0000-0000-0000-000000000000',
            'clientId': 'c1',
            'activityDate': '2026-09-29T00:00:00.000Z',
            'activityType': 'care_activity',
            'status': 'completed',
            'notes': 'notes probe',
            'description': 'Probe',
            'occurredAt': '2026-09-29T14:30:00.000Z',
            'recordedByStaffId': 's1',
            'attachmentsJson': [
              {'fileUrl': 'https://example.com/a.pdf', 'fileType': 'a.pdf'},
              {'fileUrl': 'https://example.com/b.pdf'},
            ],
            'createdAt': '2026-09-29T06:29:36.665Z',
            'updatedAt': '2026-09-29T06:29:36.665Z',
            'client': {
              'id': 'c1',
              'firstName': 'Puchan',
              'lastName': 'Indha',
              'level': 'High',
              'residence': {'id': 'r1', 'name': 'Mala Box'},
            },
            'recordedByStaff': {'id': 's1', 'firstName': 'Shakib', 'lastName': 'Hasan'},
            'author': {'id': 'u1', 'name': 'Jamal Uddin'},
          },
          {
            'id': '46678cb6',
            'clientId': 'c2',
            'activityDate': '2026-08-27T00:00:00.000Z',
            'activityType': 'school',
            'status': 'present',
            'description': null,
            'occurredAt': null,
            'client': null,
            'recordedByStaff': null,
            'author': {'id': 'u1', 'name': 'Jamal Uddin'},
          },
        ],
        'meta': {
          'total': 16,
          'totalPages': 6,
          'summary': {
            'todaysActivities': 1,
            'activeClients': 3,
            'staffEntries': 2,
            'pendingReview': 4,
          },
        },
      });
      expect((page.total, page.totalPages), (16, 6));
      expect(
        (
          page.stats.todaysActivities,
          page.stats.activeClients,
          page.stats.staffEntries,
          page.stats.pendingReview,
        ),
        (1, 3, 2, 4),
      );
      final a = page.items.first;
      expect(a.code, 'ACT-69FDB3E6');
      expect(a.clientName, 'Puchan Indha');
      expect(a.clientResidence, 'Mala Box');
      expect(a.activityDate, '2026-09-29');
      expect(a.recordedByName, 'Shakib Hasan');
      expect(a.enteredBy, 'Entered by Jamal Uddin');
      expect(a.attachments.map((f) => f.name), ['a.pdf', 'Attachment']);
      expect(a.timeline.map((t) => t.description), ['Activity took place', 'Recorded by Shakib Hasan']);

      final b = page.items.last;
      expect(b.clientName, isNull);
      expect(b.recordedByName, 'Jamal Uddin');
      expect(b.enteredBy, '');
      expect(DailyActivityLabels.dateTime(b), '27/08/2026');
    });

    test('month summary keeps API order; types add present and absent', () {
      final s = DailyActivityMapper.monthSummaryFrom({
        'success': true,
        'data': {
          'byType': {
            'care_activity': {'present': 0, 'absent': 7},
            'school': {'present': 2, 'absent': 0},
          },
          'byStatus': {'completed': 8, 'present': 2},
        },
      });
      expect(s.byStatus, [('completed', 8), ('present', 2)]);
      expect(s.byType, [('care_activity', 7), ('school', 2)]);
    });

    test('picker options use the web subtitles', () {
      final clients = DailyActivityMapper.clientsFrom({
        'data': [
          {
            'id': 'c1',
            'firstName': 'Encoderit',
            'lastName': 'Naeem',
            'roomNumber': '30',
            'residence': {'name': 'Mala Box'},
          },
          {'id': 'c2', 'firstName': 'Nadia', 'lastName': null},
        ],
      });
      expect([for (final c in clients) (c.name, c.subtitle)], [
        ('Encoderit Naeem', 'Mala Box · Room 30'),
        ('Nadia', ''),
      ]);
      final staff = DailyActivityMapper.staffFrom({
        'data': [
          {'id': 's1', 'firstName': 'September', 'lastName': 'Stone', 'category': null},
          {'id': 's2', 'firstName': 'Ruma', 'lastName': 'Begum', 'category': {'name': 'Nurse'}},
        ],
      });
      expect([for (final s in staff) s.subtitle], ['Staff', 'Nurse']);
    });

    test('repository sends search (not q), drops blanks and patches the review', () async {
      final api = _FakeApi();
      final repo = DailyActivityRepositoryImpl(api: api);
      await repo.list(
        page: 2,
        limit: 25,
        search: ' park ',
        clientId: '',
        activityType: 'school',
        from: '2026-09-01',
        to: '2026-09-30',
      );
      await repo.monthSummary(clientId: 'c1', month: '2026-09');
      await repo.markReviewed('a1');
      await repo.delete('a1');
      expect([for (final r in api.requests) '${r.$1} ${r.$2}'], [
        'GET /client-activities',
        'GET /client-activities/summary',
        'PATCH /client-activities/a1',
        'DELETE /client-activities/a1',
      ]);
      expect(api.requests[0].$3, {
        'page': 2,
        'limit': 25,
        'search': 'park',
        'activityType': 'school',
        'from': '2026-09-01',
        'to': '2026-09-30',
      });
      expect(api.requests[1].$3, {'clientId': 'c1', 'month': '2026-09'});
      expect(api.requests[2].$4, {'status': 'reviewed'});
    });

    test('draft body matches the web form payload', () {
      final occurred = DateTime(2026, 9, 29, 14, 30);
      final draft = DailyActivityDraft(
        clientId: 'c1',
        activityDate: '2026-09-29',
        activityType: 'school',
        status: 'present',
        description: '  School day  ',
        notes: '   ',
        occurredAt: occurred,
        recordedByStaffId: '',
        attachments: const [DailyActivityAttachment(fileUrl: '/f/a.pdf', fileType: 'a.pdf')],
      );
      expect(draft.toJson(), {
        'clientId': 'c1',
        'activityDate': '2026-09-29',
        'activityType': 'school',
        'status': 'present',
        'description': 'School day',
        'occurredAt': occurred.toUtc().toIso8601String(),
        'attachments': [
          {'fileUrl': '/f/a.pdf', 'fileType': 'a.pdf'},
        ],
      });
    });

    test('date filter ranges start the week on Monday', () {
      final now = DateTime(2026, 9, 30, 10);
      expect(DailyActivityLabels.range('today', now), ('2026-09-30', '2026-09-30'));
      expect(DailyActivityLabels.range('week', now), ('2026-09-28', '2026-09-30'));
      expect(DailyActivityLabels.range('month', now), ('2026-09-01', '2026-09-30'));
      expect(DailyActivityLabels.range(null, now), (null, null));
      expect(DailyActivityLabels.monthBounds('2026-02'), ('2026-02-01', '2026-02-28'));
    });
  });

  group('registry', () {
    testWidgets('header, KPI tiles, tabs, filters, rows and pagination match the web',
        (tester) async {
      final repo = await _open(tester);

      expect(find.text('Daily Activity'), findsOneWidget);
      expect(find.byKey(const ValueKey('daily-activity-record')), findsOneWidget);
      expect(find.text('Record activity'), findsOneWidget);

      for (final (key, value, label, caption) in [
        ('today', '5', "TODAY'S ACTIVITIES", 'Activities recorded today'),
        ('clients', '3', 'ACTIVE CLIENTS', 'Clients with activity updates'),
        ('staff', '4', 'STAFF ENTRIES', 'Staff submitted updates'),
        ('pending', '1', 'PENDING REVIEW', 'Activities requiring attention'),
      ]) {
        expect(_inKey('daily-activity-kpi-$key', find.text(value)), findsOneWidget);
        expect(_inKey('daily-activity-kpi-$key', find.text(label)), findsOneWidget);
        expect(_inKey('daily-activity-kpi-$key', find.text(caption)), findsOneWidget);
      }

      expect(find.text('Activity registry'), findsOneWidget);
      expect(find.text('Resident history'), findsOneWidget);
      expect(find.text('Search what was written…'), findsOneWidget);
      for (final label in ['All residents', 'All staff', 'All types', 'Any date', 'All statuses']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      expect(find.text('Client Activity Registry'), findsOneWidget);
      expect(find.text('Most recent activity first'), findsOneWidget);
      expect(find.text('1 pending review'), findsOneWidget);

      final row = find.byKey(ValueKey('daily-activity-${_pending.id}'));
      for (final text in [
        'ACT-F4672D0B',
        'Pending review',
        'Puchan Indha',
        'Mala Box',
        'Care activity',
        'Walked to the park with staff.',
        'SH',
        'Shakib Hasan',
        '29/09/2026 · 14:30',
        'RECORDED BY',
        'DATE & TIME',
      ]) {
        expect(find.descendant(of: row, matching: find.text(text)), findsOneWidget, reason: text);
      }
      final school = find.byKey(ValueKey('daily-activity-${_school.id}'));
      for (final text in ['Present', 'School', '—', '27/08/2026', 'Jamal Uddin']) {
        expect(find.descendant(of: school, matching: find.text(text)), findsOneWidget, reason: text);
      }
      expect(find.text('Showing 1 to 2 of 2 entries'), findsOneWidget);
      expect(repo.listQueries.first, {
        'page': 1,
        'limit': 10,
        'search': '',
        'clientId': null,
        'staff': null,
        'type': null,
        'status': null,
        'from': null,
        'to': null,
      });
    });

    testWidgets('every filter is sent to the list and resets to page 1', (tester) async {
      final repo = await _open(tester);

      await tester.enterText(find.byKey(const ValueKey('daily-activity-search')), 'park');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(repo.listQueries.last['search'], 'park');

      await _choose(tester, 'daily-activity-filter-resident', 'Ayaan Karim');
      expect(repo.listQueries.last['clientId'], 'c2');
      await _choose(tester, 'daily-activity-filter-staff', 'Ruma Begum');
      expect(repo.listQueries.last['staff'], 's2');

      await _tap(tester, find.byKey(const ValueKey('daily-activity-filter-type')));
      for (final (_, label) in DailyActivityLabels.types) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      await tester.tap(find.text('Programme').last);
      await tester.pumpAndSettle();
      expect(repo.listQueries.last['type'], 'program');

      await _choose(tester, 'daily-activity-filter-date', 'This week');
      expect((repo.listQueries.last['from'], repo.listQueries.last['to']),
          ('2026-09-28', '2026-09-30'));

      await _tap(tester, find.byKey(const ValueKey('daily-activity-filter-status')));
      for (final label in ['Partly done', 'Could not be done', 'Pending review', 'Absent']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      await tester.tap(find.text('Refused').last);
      await tester.pumpAndSettle();
      expect(repo.listQueries.last['status'], 'refused');
      expect(repo.listQueries.last['page'], 1);

      await _choose(tester, 'daily-activity-filter-type', 'All types');
      expect(repo.listQueries.last['type'], isNull);
    });

    testWidgets('empty and failed lists use the web empty states', (tester) async {
      final repo = _FakeRepo()
        ..rows = []
        ..total = 0;
      await _open(tester, repo: repo);
      expect(find.text('Nothing recorded'), findsOneWidget);
      expect(find.text('Outings, programmes and observations appear here.'), findsOneWidget);
      expect(find.textContaining('Showing'), findsNothing);

      repo.failList = true;
      await Get.find<DailyActivityController>().load();
      await tester.pumpAndSettle();
      expect(find.text('Activities could not be loaded'), findsOneWidget);
      expect(find.text('Server unreachable'), findsOneWidget);
    });

    testWidgets('Delete asks first, then deletes and toasts', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, find.byKey(ValueKey('daily-activity-actions-${_school.id}')));
      expect(find.text('View'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this activity record?'), findsOneWidget);
      expect(
        find.text('It leaves the registry. What was written is kept rather than destroyed, '
            'so it can be restored.'),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const ValueKey('daily-activity-delete-confirm')));
      expect(repo.calls, ['delete ${_school.id}']);
      expect(find.text('Activity record deleted'), findsOneWidget);
    });

    testWidgets('without client-activities:write the page is read-only', (tester) async {
      await _open(tester, denied: {'client-activities:write'});
      expect(find.byKey(const ValueKey('daily-activity-record')), findsNothing);

      await _tap(tester, find.byKey(ValueKey('daily-activity-actions-${_pending.id}')));
      expect(find.text('View'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      expect(find.text('Activity Details'), findsOneWidget);
      expect(find.byKey(const ValueKey('daily-activity-mark-reviewed')), findsNothing);
      expect(find.byKey(const ValueKey('daily-activity-detail-edit')), findsNothing);
      expect(find.byKey(const ValueKey('daily-activity-detail-close')), findsOneWidget);
    });
  });

  group('detail', () {
    testWidgets('shows resident, information, notes, attachments and timeline; '
        'Mark reviewed patches the status', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, find.text('Walked to the park with staff.'));

      for (final text in [
        'Activity Details',
        'ACT-F4672D0B · Recorded 29/09/2026 · 14:30',
        'PI',
        'Mala Box',
        'Activity Information',
        'ACTIVITY TYPE',
        'RECORDED BY',
        'Shakib Hasan · Entered by Jamal Uddin',
        'DESCRIPTION',
        'DATE',
        '29/09/2026',
        'TIME',
        '14:30',
        'Additional Notes',
        'Asked to go again tomorrow.',
        'Attachments',
        'park-photo.pdf',
        'Open',
        'Activity Timeline',
        '29/09/2026 · 14:30',
        'Activity took place',
        '29/09/2026 · 15:00',
        'Recorded by Shakib Hasan',
        '29/09/2026 · 16:05',
        'Record corrected',
        'Close',
        'Mark reviewed',
        'Edit Activity',
      ]) {
        expect(find.text(text, findRichText: true), findsWidgets, reason: text);
      }
      expect(find.text('Care Level: High', findRichText: true), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('daily-activity-mark-reviewed')));
      expect(repo.calls, ['reviewed ${_pending.id}']);
      expect(find.text('Marked reviewed'), findsOneWidget);
      expect(find.text('Activity Details'), findsNothing);
    });

    testWidgets('a record without time, notes or files says so', (tester) async {
      await _open(tester);
      await _tap(tester, find.byKey(ValueKey('daily-activity-actions-${_school.id}')));
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(find.text('Time not recorded'), findsOneWidget);
      expect(find.text('Additional Notes'), findsNothing);
      expect(find.text('Attachments'), findsNothing);
      expect(find.text('Activity Timeline'), findsNothing);
      expect(find.text('Care Level: Medium', findRichText: true), findsOneWidget);
      expect(find.text('Mark reviewed'), findsNothing);
    });

    testWidgets('Edit Activity opens the filled form and saves with the kept attachments',
        (tester) async {
      final repo = await _open(tester);
      await _tap(tester, find.text('Walked to the park with staff.'));
      await _tap(tester, find.byKey(const ValueKey('daily-activity-detail-edit')));

      expect(find.text('Edit Daily Activity'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(_inKey('daily-activity-form-resident', find.text('Puchan Indha')), findsOneWidget);
      expect(_inKey('daily-activity-form-resident', find.text('Selected')), findsOneWidget);
      expect(_inKey('daily-activity-form-staff', find.text('Shakib Hasan')), findsOneWidget);
      expect(_inKey('daily-activity-form-type', find.text('Care activity')), findsOneWidget);
      expect(_inKey('daily-activity-form-status', find.text('Pending review')), findsOneWidget);
      expect(_inKey('daily-activity-form-date', find.text('29/09/2026')), findsOneWidget);
      expect(_inKey('daily-activity-form-time', find.text('14:30')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('daily-activity-form-description')),
        'Walked to the park and fed the ducks.',
      );
      await _tap(tester, find.byKey(const ValueKey('daily-activity-form-save')));

      final (id, draft) = repo.updated!;
      expect(id, _pending.id);
      expect(draft.toJson(), {
        'clientId': 'c1',
        'activityDate': '2026-09-29',
        'activityType': 'care_activity',
        'status': 'pending_review',
        'description': 'Walked to the park and fed the ducks.',
        'notes': 'Asked to go again tomorrow.',
        'occurredAt': DateTime(2026, 9, 29, 14, 30).toUtc().toIso8601String(),
        'recordedByStaffId': 's1',
        'attachments': [
          {'fileUrl': '/files/a.pdf', 'fileType': 'park-photo.pdf'},
        ],
      });
      expect(find.text('Activity updated'), findsOneWidget);
      expect(find.text('Edit Daily Activity'), findsNothing);
    });
  });

  group('record activity', () {
    testWidgets('requires a resident and a description, uploads the file, then creates',
        (tester) async {
      final repo = await _open(
        tester,
        page: DailyActivityPage(
          pickFile: () async => (
            const DailyActivityLocalFile(path: '/tmp/outing.pdf', name: 'outing.pdf'),
            2048,
          ),
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('daily-activity-record')));

      for (final text in [
        'Add Daily Activity',
        'Separate from the daily log — this is what they did, not how care went.',
        'Select Resident *',
        'Search select resident...',
        'Type to search select resident',
        'Activity Type *',
        'How it went *',
        'A refusal or a partial is the one somebody reads',
        'Activity Description *',
        'Describe the activity performed or observation recorded...',
        'Additional Notes (Optional)',
        'Add additional observations or comments...',
        'Upload Document (Optional)',
        'Click to upload or drag & drop',
        'PDF, DOC, JPG or PNG · up to 15MB',
        'Recorded by',
        'Search recorded by...',
        'Date *',
        'Time',
        'Optional — without it the record is placed to the day',
        'Cancel',
        'Save Activity',
      ]) {
        expect(find.text(text, findRichText: true), findsWidgets, reason: text);
      }
      expect(_inKey('daily-activity-form-type', find.text('Care activity')), findsOneWidget);
      expect(_inKey('daily-activity-form-status', find.text('Completed')), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('daily-activity-form-save')));
      expect(find.text('Select a resident'), findsOneWidget);
      expect(find.text('Say what happened'), findsOneWidget);
      expect(repo.created, isNull);

      final residentField = _inKey('daily-activity-form-resident', find.byType(TextField));
      await _tap(tester, residentField);
      expect(_inKey('daily-activity-form-resident', find.text('Mala Box · Room 30')), findsOneWidget);
      await tester.enterText(residentField, 'zz');
      await tester.pumpAndSettle();
      expect(_inKey('daily-activity-form-resident', find.text('No matches found')), findsOneWidget);
      await tester.enterText(residentField, 'aya');
      await tester.pumpAndSettle();
      expect(_inKey('daily-activity-form-resident', find.text('Puchan Indha')), findsNothing);
      await _tap(tester, _inKey('daily-activity-form-resident', find.text('Ayaan Karim')));
      expect(_inKey('daily-activity-form-resident', find.text('Selected')), findsOneWidget);
      expect(find.text('Select a resident'), findsNothing);

      await _choose(tester, 'daily-activity-form-type', 'School');
      await _choose(tester, 'daily-activity-form-status', 'Partly done');
      await tester.enterText(
        find.byKey(const ValueKey('daily-activity-form-description')),
        'Left school at lunch.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('daily-activity-form-notes')),
        'Tired after PE.',
      );
      await _tap(tester, find.byKey(const ValueKey('daily-activity-form-upload')));
      expect(_inKey('daily-activity-form-file', find.text('outing.pdf')), findsOneWidget);

      final staffField = _inKey('daily-activity-form-staff', find.byType(TextField));
      await _tap(tester, staffField);
      expect(_inKey('daily-activity-form-staff', find.text('Care worker')), findsOneWidget);
      await _tap(tester, _inKey('daily-activity-form-staff', find.text('Ruma Begum')));

      await _tap(tester, find.byKey(const ValueKey('daily-activity-form-save')));
      expect(repo.uploads, ['outing.pdf']);
      expect(repo.created!.toJson(), {
        'clientId': 'c2',
        'activityDate': DailyActivityLabels.ymd(DateTime.now()),
        'activityType': 'school',
        'status': 'partially_completed',
        'description': 'Left school at lunch.',
        'notes': 'Tired after PE.',
        'recordedByStaffId': 's2',
        'attachments': [
          {'fileUrl': '/files/outing.pdf', 'fileType': 'outing.pdf'},
        ],
      });
      expect(find.text('Activity recorded'), findsOneWidget);
      expect(find.text('Add Daily Activity'), findsNothing);
    });

    testWidgets('files over 10MB are refused; a failed save shows the API message',
        (tester) async {
      final repo = _FakeRepo()..saveError = 'Resident is not in your residence';
      await _open(
        tester,
        repo: repo,
        page: DailyActivityPage(
          pickFile: () async => (
            const DailyActivityLocalFile(path: '/tmp/big.pdf', name: 'big.pdf'),
            11 * 1024 * 1024,
          ),
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('daily-activity-record')));
      await _tap(tester, find.byKey(const ValueKey('daily-activity-form-upload')));
      expect(find.text('"big.pdf" exceeds the 10MB limit'), findsOneWidget);
      expect(find.byKey(const ValueKey('daily-activity-form-file')), findsNothing);

      final residentField = _inKey('daily-activity-form-resident', find.byType(TextField));
      await _tap(tester, residentField);
      await _tap(tester, _inKey('daily-activity-form-resident', find.text('Puchan Indha')));
      await tester.enterText(
        find.byKey(const ValueKey('daily-activity-form-description')),
        'Lunch out.',
      );
      await _tap(tester, find.byKey(const ValueKey('daily-activity-form-save')));
      expect(
        _inKey('daily-activity-form-error', find.text('Resident is not in your residence')),
        findsOneWidget,
      );
      expect(find.text('Add Daily Activity'), findsOneWidget);
      expect(repo.uploads, isEmpty);
    });

    testWidgets('closing a changed form asks to discard; an untouched one just closes',
        (tester) async {
      await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('daily-activity-record')));
      await _tap(tester, find.byKey(const ValueKey('daily-activity-form-cancel')));
      expect(find.text('Add Daily Activity'), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('daily-activity-record')));
      await tester.enterText(
        find.byKey(const ValueKey('daily-activity-form-description')),
        'Draft',
      );
      await _tap(tester, find.byKey(const ValueKey('daily-activity-form-cancel')));
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(
        find.text("You have unsaved edits on this form. If you leave now, they'll be lost."),
        findsOneWidget,
      );
      await _tap(tester, find.text('Keep editing'));
      expect(find.text('Add Daily Activity'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('daily-activity-form-cancel')));
      await _tap(tester, find.byKey(const ValueKey('daily-activity-discard')));
      expect(find.text('Add Daily Activity'), findsNothing);
    });
  });

  group('resident history', () {
    testWidgets('asks for a resident, then shows the month summary and records',
        (tester) async {
      final repo = await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('daily-activity-tab-history')));

      expect(find.text('Search what was written…'), findsNothing);
      expect(find.text('Choose a resident'), findsWidgets);
      expect(find.text('Their month appears here — what was recorded, and how it went.'),
          findsOneWidget);
      expect(_inKey('daily-activity-history-month', find.text('September 2026')), findsOneWidget);

      await _choose(tester, 'daily-activity-history-resident', 'Puchan Indha');
      expect(find.text('Mala Box · High'), findsOneWidget);
      expect(repo.calls, ['summary c1 2026-09']);
      expect(repo.listQueries.last, {
        'page': 1,
        'limit': 100,
        'search': null,
        'clientId': 'c1',
        'staff': null,
        'type': null,
        'status': null,
        'from': '2026-09-01',
        'to': '2026-09-30',
      });

      expect(find.text('How the month went'), findsOneWidget);
      expect(_inKey('daily-activity-month-status', find.text('Completed · 8')), findsOneWidget);
      expect(_inKey('daily-activity-month-status', find.text('Present · 2')), findsOneWidget);
      expect(find.text('What they did'), findsOneWidget);
      expect(_inKey('daily-activity-month-type', find.text('Care activity')), findsOneWidget);
      expect(_inKey('daily-activity-month-type', find.text('7')), findsOneWidget);
      expect(_inKey('daily-activity-month-type', find.text('School')), findsOneWidget);

      expect(find.text('Puchan Indha — 2026-09'), findsOneWidget);
      expect(find.text('Everything recorded for this resident in the month shown'), findsOneWidget);
      expect(find.text('1 pending review'), findsOneWidget);
      expect(find.byKey(ValueKey('daily-activity-${_pending.id}')), findsOneWidget);

      await _tap(tester, find.byKey(ValueKey('daily-activity-actions-${_pending.id}')));
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await _tap(tester, find.byKey(const ValueKey('daily-activity-history-month')));
      await _tap(tester, find.byKey(const ValueKey('daily-activity-month-prev-year')));
      await tester.tap(find.text('Mar'));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'summary c1 2025-03');
      expect(repo.listQueries.last['from'], '2025-03-01');
      expect(repo.listQueries.last['to'], '2025-03-31');
    });

    testWidgets('an empty month uses the web empty copy', (tester) async {
      final repo = _FakeRepo()..summary = const DailyActivityMonthSummary();
      await _open(tester, repo: repo);
      await _tap(tester, find.byKey(const ValueKey('daily-activity-tab-history')));
      repo.rows = [];
      await _choose(tester, 'daily-activity-history-resident', 'Ayaan Karim');
      expect(find.text('Nothing recorded this month.'), findsNWidgets(2));
      expect(find.text('Nothing this month'), findsOneWidget);
      expect(find.text('Pick another month, or record the first activity.'), findsOneWidget);
      expect(find.text('0 pending review'), findsOneWidget);
    });
  });
}
