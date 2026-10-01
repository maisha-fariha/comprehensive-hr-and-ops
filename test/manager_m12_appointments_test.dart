import 'dart:convert';

import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/appointments/data/mappers/hr_appointments_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/appointments/data/repositories/hr_appointments_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/hr/appointments/domain/entities/hr_appointment.dart';
import 'package:comprehensive_hr_and_ops/features/hr/appointments/domain/repositories/hr_appointments_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/appointments/presentation/controllers/hr_appointments_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/appointments/presentation/pages/hr_appointments_page.dart';
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
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Finder _inKey(String key, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: matching);

class _Session extends UserSession {
  final Set<String> denied;

  _Session({this.denied = const {}});

  @override
  bool can(String permission) => !denied.contains(permission);
}

// Live-shaped rows (GET /appointments on the demo tenant).
final _pendingVisit = HrAppointmentsMapper.appointmentFrom({
  'id': '921c17fb-a2be-42f4-9398-ac36d9b1d847',
  'type': 'family_visit',
  'clientId': 'c1',
  'client': {'id': 'c1', 'name': 'Ayaan Karim'},
  'residenceId': 'elm',
  'residence': {'id': 'elm', 'name': 'Elm House'},
  'requester': {'id': 'u1', 'name': 'Shirin Karim', 'email': 'family@demo.local'},
  'requesterRelationship': 'Mother',
  'status': 'pending',
  'scheduledAt': '2026-08-30T09:33:06.745Z',
  'location': 'Elm House lounge',
  'purpose': null,
  'notes': 'Saturday afternoon visit.',
  'decider': null,
})!;

final _cancelled = HrAppointmentsMapper.appointmentFrom({
  'id': '8c3c1df0-b786-4178-bb3b-8f9976a7067a',
  'type': 'family_visit',
  'clientId': 'c1',
  'client': {'id': 'c1', 'name': 'Ayaan Karim'},
  'residenceId': 'elm',
  'residence': {'id': 'elm', 'name': 'Elm House'},
  'requester': {'id': 'u1', 'name': 'Shirin Karim'},
  'requesterRelationship': 'Mother',
  'status': 'cancelled',
  'scheduledAt': '2026-09-03T06:53:00.000Z',
  'decider': {'id': 'm1', 'name': 'Shakib Hasan'},
  'decidedAt': '2026-09-02T06:53:41.252Z',
  'decisionReason': 'Clashes with the GP round',
})!;

final _external = HrAppointmentsMapper.appointmentFrom({
  'id': 'aa11bb22-0000-4000-8000-000000000003',
  'type': 'external',
  'clientId': 'c2',
  'client': {'id': 'c2', 'name': 'Nadia Islam'},
  'residenceId': 'elm',
  'residence': {'id': 'elm', 'name': 'Elm House'},
  'status': 'approved',
  'scheduledAt': '2026-10-05T10:00:00.000Z',
  'purpose': 'GP review',
})!;

class _FakeRepo implements HrAppointmentsRepository {
  List<HrAppointment> rows = [_pendingVisit, _cancelled, _external];
  final List<HrAppointmentQuery> queries = [];
  final List<String> calls = [];
  HrAppointmentInput? lastInput;
  String? failWith;
  List<HrAppointmentLogNote> notes = const [];

  @override
  Future<Result<HrAppointmentPage>> list(HrAppointmentQuery query) async {
    queries.add(query);
    final items = rows
        .where((r) => query.status == null || r.status == query.status)
        .where((r) => query.type == null || r.type == query.type)
        .toList();
    return Result.success(
      HrAppointmentPage(items: items, total: items.length, totalPages: items.isEmpty ? 0 : 1),
    );
  }

  @override
  Future<Result<HrAppointmentSummary>> summary() async => Result.success(
        const HrAppointmentSummary(
          pending: 1,
          approved: 4,
          rejected: 2,
          cancelled: 1,
          completed: 7,
          approvedToday: 3,
          upcomingVisits: 5,
          upcomingExternal: 6,
          total: 15,
        ),
      );

  Future<Result<void>> _log(String call) async {
    calls.add(call);
    final error = failWith;
    return error == null ? Result.success(null) : Result.failure(ApiError(message: error));
  }

  @override
  Future<Result<void>> create(HrAppointmentInput input) {
    lastInput = input;
    return _log('create ${input.type} ${input.clientId}');
  }

  @override
  Future<Result<void>> reschedule(String id, HrAppointmentInput input) {
    lastInput = input;
    return _log('reschedule $id');
  }

  @override
  Future<Result<void>> update(String id, HrAppointmentInput input) {
    lastInput = input;
    return _log('update $id');
  }

  @override
  Future<Result<void>> approve(String id) => _log('approve $id');

  @override
  Future<Result<void>> reject(String id, {String? reason}) => _log('reject $id $reason');

  @override
  Future<Result<void>> cancel(String id, {String? reason}) => _log('cancel $id $reason');

  @override
  Future<Result<void>> delete(String id) => _log('delete $id');

  @override
  Future<Result<List<HrAppointmentOption>>> residences() async =>
      Result.success(const [HrAppointmentOption(id: 'elm', label: 'Elm House')]);

  @override
  Future<Result<List<HrAppointmentClient>>> clients() async => Result.success(const [
        HrAppointmentClient(id: 'c1', name: 'Ayaan Karim', code: '12', residence: 'Elm House', residenceId: 'elm'),
        HrAppointmentClient(id: 'c3', name: 'Rina Das', code: '4', residence: 'Oak Lodge', residenceId: 'oak'),
      ]);

  @override
  Future<Result<List<HrAppointmentLogNote>>> dayLog({
    required String clientId,
    required String residenceId,
    required String logDate,
  }) async {
    calls.add('dayLog $clientId $residenceId');
    return Result.success(notes);
  }

  @override
  Future<Result<List<int>>> exportCsv() async {
    calls.add('export');
    return Result.success(utf8.encode('Request\n'));
  }
}

final List<(String, List<int>)> _saved = [];

Future<_FakeRepo> _open(
  WidgetTester tester, {
  _FakeRepo? repo,
  Set<String> denied = const {},
}) async {
  _tallView(tester);
  final fake = repo ?? _FakeRepo();
  final session = _Session(denied: denied);
  GetIt.I.registerFactory<HrAppointmentsController>(
    () => HrAppointmentsController(
      repository: fake,
      session: session,
      saveFile: (name, bytes) async {
        _saved.add((name, bytes));
        return null;
      },
    ),
  );
  await tester.pumpWidget(_app(const HrAppointmentsPage()));
  await tester.pumpAndSettle();
  return fake;
}

Future<void> _openMenu(WidgetTester tester, HrAppointment a) =>
    _tap(tester, find.byKey(ValueKey('appointment-menu-${a.id}')));

class _FakeApi implements AppApiClient {
  final List<(String, String, Object?)> sent = [];
  final Map<String, Result<dynamic>> responses = {};

  Result<dynamic> _reply(String method, String path, Object? payload) {
    sent.add((method, path, payload));
    return responses['$method $path'] ?? Result.success({'data': <String, dynamic>{}});
  }

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) async =>
      _reply('GET', path, query);

  @override
  Future<Result<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) async =>
      _reply('POST', path, data);

  @override
  Future<Result<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) async =>
      _reply('PATCH', path, data);

  @override
  Future<Result<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) async =>
      _reply('DELETE', path, data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    _saved.clear();
    Get.reset();
    await GetIt.I.reset();
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('mapper', () {
    test('derives the web table fields from a live row', () {
      final a = _pendingVisit;
      expect(a.reference, 'APT-921C17FB');
      expect(a.typeLabel, 'Family Visit');
      expect(a.statusLabel, 'Pending');
      expect(a.requestedBy, 'Shirin Karim');
      expect(a.requesterEmail, 'family@demo.local');
      expect(a.relationshipLabel, 'Mother');
      expect(a.purposeColumn, 'Saturday afternoon visit.');
      expect(a.isDecidable, isTrue);
      expect(a.isLive, isTrue);
      expect(_cancelled.isLive, isFalse);
      expect(_cancelled.isDecidable, isFalse);
      expect(_external.isDecidable, isFalse);
      expect(_external.typeLabel, 'External');

      final bare = HrAppointmentsMapper.appointmentFrom({'id': 'x', 'type': 'external', 'status': 'pending'})!;
      expect(bare.requestedBy, 'The home');
      expect(bare.requestedDate, 'No date proposed');
      expect(bare.time, '—');
      expect(bare.client, '—');
    });

    test('summary, empty day log and clients', () {
      final s = HrAppointmentsMapper.summaryFrom({
        'data': {'pending': 1, 'rejected': 2, 'cancelled': 3, 'total': 9, 'upcomingVisits': 4},
      });
      expect(s.pending, 1);
      expect(s.cancelledOrRejected, 5);
      expect(s.upcomingVisits, 4);
      expect(HrAppointmentsMapper.dayLogFrom({'success': true, 'data': null}), isEmpty);

      final notes = HrAppointmentsMapper.dayLogFrom({
        'data': {
          'entries': [
            {'id': 'e1', 'body': 'Took meds', 'logType': 'medication', 'author': {'name': 'Ruma'}},
            {'id': 'e2', 'body': 'Upset', 'logType': 'general', 'flag': {'resolvedAt': null}},
            {'id': 'e3', 'body': 'Old', 'isSuperseded': true},
          ],
        },
      });
      expect(notes.map((n) => n.tag), ['Medication', 'Behavior', 'General']);
      expect(notes.first.title, 'Ruma');
      expect(notes[1].title, 'Care note');

      final clients = HrAppointmentsMapper.clientsFrom({
        'data': [
          {'id': 'c1', 'firstName': 'Ayaan', 'lastName': 'Karim', 'roomNumber': '12', 'residenceId': 'elm', 'residence': {'name': 'Elm House'}},
        ],
      });
      expect(clients.single.name, 'Ayaan Karim');
      expect(clients.single.code, '12');
      expect(clients.single.residence, 'Elm House');
    });
  });

  group('repository', () {
    test('list drops blank filters; bodies match the web', () async {
      final api = _FakeApi();
      final repo = HrAppointmentsRepositoryImpl(api: api);
      await repo.list(const HrAppointmentQuery(page: 2, limit: 20, status: 'pending', type: '', search: ' '));
      expect(api.sent.last.$3, {'page': 2, 'limit': 20, 'status': 'pending'});

      final at = DateTime.utc(2026, 10, 5, 10);
      await repo.create(HrAppointmentInput(type: 'external', clientId: 'c1', residenceId: 'elm', scheduledAt: at));
      expect(api.sent.last.$2, '/appointments');
      expect(api.sent.last.$3, {
        'type': 'external',
        'clientId': 'c1',
        'residenceId': 'elm',
        'scheduledAt': '2026-10-05T10:00:00.000Z',
      });

      await repo.update('a1', HrAppointmentInput(type: 'external', clientId: 'c1', scheduledAt: at, purpose: 'GP'));
      expect(api.sent.last.$1, 'PATCH');
      expect(api.sent.last.$3, {
        'scheduledAt': '2026-10-05T10:00:00.000Z',
        'location': null,
        'purpose': 'GP',
        'notes': null,
      });

      await repo.reschedule('a1', HrAppointmentInput(type: 'family_visit', clientId: 'c1', scheduledAt: at));
      expect(api.sent.last.$2, '/appointments/a1/reschedule');
      expect(api.sent.last.$3, {'scheduledAt': '2026-10-05T10:00:00.000Z'});

      await repo.reject('a1', reason: 'Busy day');
      expect(api.sent.last.$2, '/appointments/a1/reject');
      expect(api.sent.last.$3, {'reason': 'Busy day'});
      await repo.cancel('a1');
      expect(api.sent.last.$3, <String, dynamic>{});
      await repo.approve('a1');
      expect(api.sent.last.$2, '/appointments/a1/approve');
      await repo.delete('a1');
      expect(api.sent.last.$1, 'DELETE');
    });

    test('export falls back to a local CSV when the poll is forbidden', () async {
      final api = _FakeApi()
        ..responses['POST /reports/exports'] = Result.success({
          'data': {'id': 'x1', 'status': 'queued'},
        })
        ..responses['GET /reports/exports/x1'] =
            Result.failure(const ApiError(message: 'Missing permission'))
        ..responses['GET /appointments'] = Result.success({
          'data': [
            {
              'id': '921c17fb-a2be',
              'type': 'family_visit',
              'status': 'pending',
              'client': {'name': 'Ayaan Karim'},
              'notes': 'Bring cake, please',
            },
          ],
          'meta': {'total': 1, 'totalPages': 1},
        });
      final repo = HrAppointmentsRepositoryImpl(api: api, pollInterval: Duration.zero);
      final result = await repo.exportCsv();
      expect(api.sent.first.$3, {'reportKey': 'appointment_log', 'format': 'csv'});
      final csv = utf8.decode(result.value!);
      expect(csv, startsWith('Request,Residence,Resident,Requested By'));
      expect(csv, contains('APT-921C17FB'));
      expect(csv, contains('"Bring cake, please"'));
    });
  });

  group('page', () {
    testWidgets('header, KPI tiles and tab counts come from the summary', (tester) async {
      final repo = await _open(tester);
      expect(find.text('Family Appointments & Approvals'), findsOneWidget);
      expect(find.text('Create Appointment'), findsOneWidget);
      expect(find.text('Export List'), findsOneWidget);
      expect(_inKey('appointments-kpi-pending', find.text('1')), findsOneWidget);
      expect(_inKey('appointments-kpi-pending', find.text('Needs review')), findsOneWidget);
      expect(_inKey('appointments-kpi-approved-today', find.text('3')), findsOneWidget);
      expect(_inKey('appointments-kpi-external', find.text('6')), findsOneWidget);
      expect(_inKey('appointments-kpi-family', find.text('5')), findsOneWidget);
      expect(_inKey('appointments-kpi-closed', find.text('3')), findsOneWidget);
      expect(_inKey('appointments-kpi-completed', find.text('7')), findsOneWidget);
      expect(_inKey('appointments-tab-approved', find.text('4')), findsOneWidget);
      expect(_inKey('appointments-tab-closed', find.text('Rejected')), findsOneWidget);
      expect(_inKey('appointments-tab-closed', find.text('2')), findsOneWidget);
      expect(_inKey('appointments-tab-all', find.text('15')), findsOneWidget);
      expect(_inKey('appointments-tab-family', find.byType(Text)), findsOneWidget);

      // Opens on Pending.
      expect(repo.queries.first.status, 'pending');
      expect(find.text('APT-921C17FB'), findsOneWidget);
      expect(find.text('1 request'), findsOneWidget);
    });

    testWidgets('tabs, filters, clear filters and search drive the query', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('appointments-tab-family')));
      expect(repo.queries.last.type, 'family_visit');
      expect(repo.queries.last.status, isNull);
      expect(find.text('2 requests'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('appointments-filters-toggle')));
      await _tap(tester, find.byKey(const ValueKey('appointments-filter-status')));
      await _tap(tester, find.text('Cancelled').last);
      expect(repo.queries.last.status, 'cancelled');
      expect(repo.queries.last.type, 'family_visit');

      await _tap(tester, find.byKey(const ValueKey('appointments-filter-residenceId')));
      await _tap(tester, find.text('Elm House').last);
      expect(repo.queries.last.residenceId, 'elm');

      await tester.enterText(find.byKey(const ValueKey('appointments-search')), 'Ayaan');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(repo.queries.last.search, 'Ayaan');

      await _tap(tester, find.byKey(const ValueKey('appointments-clear-filters')));
      final q = repo.queries.last;
      expect(q.status, 'pending');
      expect(q.type, isNull);
      expect(q.residenceId, '');
      expect(q.search, '');
    });

    testWidgets('row actions follow the web gating', (tester) async {
      await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('appointments-tab-all')));

      await _openMenu(tester, _pendingVisit);
      for (final label in ['View Details', 'Approve', 'Reject', 'Edit', 'Cancel', 'Delete']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await _openMenu(tester, _cancelled);
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await _openMenu(tester, _external);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    });

    testWidgets('without write or export only viewing is offered', (tester) async {
      await _open(tester, denied: {'appointments:write', 'appointments:export'});
      expect(find.text('Create Appointment'), findsNothing);
      expect(find.text('Export List'), findsNothing);
      await _openMenu(tester, _pendingVisit);
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('approve from the row menu', (tester) async {
      final repo = await _open(tester);
      await _openMenu(tester, _pendingVisit);
      await _tap(tester, find.text('Approve'));
      expect(repo.calls, contains('approve ${_pendingVisit.id}'));
      expect(find.text('Visit approved — the family can see it'), findsOneWidget);
    });

    testWidgets('decline with a reason, and the error stays in the dialog', (tester) async {
      final repo = await _open(tester)..failWith = 'Appointment not found';
      await _openMenu(tester, _pendingVisit);
      await _tap(tester, find.text('Reject'));
      expect(find.text('Decline this visit?'), findsOneWidget);
      expect(find.text('Ayaan Karim · ${_pendingVisit.requestedDate} ${_pendingVisit.time}'), findsOneWidget);
      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('appointment-reason')), matching: find.byType(TextField)),
        'Clashes with the GP round',
      );
      await _tap(tester, find.byKey(const ValueKey('appointment-reason-submit')));
      expect(find.byKey(const ValueKey('appointment-reason-error')), findsOneWidget);
      expect(find.text('Appointment not found'), findsOneWidget);

      repo.failWith = null;
      await _tap(tester, find.byKey(const ValueKey('appointment-reason-submit')));
      expect(repo.calls.last, 'reject ${_pendingVisit.id} Clashes with the GP round');
      expect(find.text('Decline this visit?'), findsNothing);
      expect(find.text('Visit declined — the family has been told'), findsOneWidget);
    });

    testWidgets('cancel from the row menu sends no reason when blank', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('appointments-tab-approved')));
      await _openMenu(tester, _external);
      await _tap(tester, find.text('Cancel'));
      expect(find.text('Cancel this appointment?'), findsOneWidget);
      await _tap(tester, find.text('Cancel appointment'));
      expect(repo.calls.last, 'cancel ${_external.id} null');
      expect(find.text('Appointment cancelled'), findsOneWidget);
    });

    testWidgets('delete asks first', (tester) async {
      final repo = await _open(tester);
      await _openMenu(tester, _pendingVisit);
      await _tap(tester, find.text('Delete'));
      expect(find.text('Delete this appointment?'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('appointment-delete-confirm')));
      expect(repo.calls, contains('delete ${_pendingVisit.id}'));
      expect(find.text('Appointment deleted'), findsOneWidget);
    });

    testWidgets('detail of a pending visit: sections, day log and decide buttons', (tester) async {
      final repo = _FakeRepo()
        ..notes = [
          HrAppointmentLogNote(id: 'n1', body: 'Took morning meds', logType: 'medication', authorName: 'Ruma Begum', at: DateTime(2026, 10, 1, 8, 15)),
          const HrAppointmentLogNote(id: 'n2', body: 'Superseded', isSuperseded: true),
        ];
      await _open(tester, repo: repo);
      await _tap(tester, find.byKey(ValueKey('appointment-row-${_pendingVisit.id}')));
      expect(find.text('Resident & Requester'), findsOneWidget);
      expect(find.text('When & Where'), findsOneWidget);
      expect(find.text('What was asked for'), findsOneWidget);
      expect(find.text('family@demo.local'), findsOneWidget);
      expect(find.text('Not decided yet'), findsOneWidget);
      expect(find.text('Recent Daily Log Context'), findsOneWidget);
      expect(find.text("Today's care notes for Ayaan Karim"), findsOneWidget);
      expect(find.text('Took morning meds'), findsOneWidget);
      expect(find.text('Superseded'), findsNothing);
      expect(repo.calls, contains('dayLog c1 elm'));
      expect(find.byKey(const ValueKey('appointment-detail-approve')), findsOneWidget);
      expect(find.byKey(const ValueKey('appointment-detail-reject')), findsOneWidget);
      expect(find.byKey(const ValueKey('appointment-detail-cancel')), findsOneWidget);
      expect(find.byKey(const ValueKey('appointment-detail-edit')), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('appointment-detail-approve')));
      expect(repo.calls, contains('approve ${_pendingVisit.id}'));
      expect(find.text('Resident & Requester'), findsNothing);
    });

    testWidgets('detail Edit on a confirmed appointment opens the form and updates', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('appointments-tab-external')));
      await _tap(tester, find.byKey(ValueKey('appointment-row-${_external.id}')));
      expect(find.text('REVIEWED BY'), findsWidgets);
      expect(find.byKey(const ValueKey('appointment-detail-approve')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('appointment-detail-edit')));

      expect(find.text('Edit Appointment'), findsOneWidget);
      expect(find.text(_external.reference), findsWidgets);
      expect(find.byKey(const ValueKey('appointment-form-resident-selected')), findsOneWidget);
      expect(find.byKey(const ValueKey('appointment-form-change-resident')), findsNothing);
      expect(find.text('Save Changes'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('appointment-form-submit')));
      expect(repo.calls.last, 'update ${_external.id}');
      expect(repo.lastInput!.purpose, 'GP review');
      expect(repo.lastInput!.scheduledAt, _external.scheduledAt!.toLocal());
      expect(find.text('Appointment updated'), findsOneWidget);
    });

    testWidgets('editing a pending visit proposes a new time', (tester) async {
      final repo = await _open(tester);
      await _openMenu(tester, _pendingVisit);
      await _tap(tester, find.text('Edit'));
      await _tap(tester, find.byKey(const ValueKey('appointment-form-submit')));
      expect(repo.calls.last, 'reschedule ${_pendingVisit.id}');
      expect(find.text('A new time was proposed to the family'), findsOneWidget);
    });

    testWidgets('create: validation, resident picker, preview and save', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('appointments-create')));
      expect(find.text('Create Appointment'), findsWidgets);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Pending approval'), findsOneWidget);
      expect(find.text('No resident selected yet.'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('appointment-form-submit')));
      expect(find.text('1 field need attention'), findsOneWidget);
      expect(find.text('Choose the resident this is for'), findsOneWidget);
      expect(repo.calls.where((c) => c.startsWith('create')), isEmpty);

      await _tap(tester, find.byKey(const ValueKey('appointment-form-type')));
      await _tap(tester, find.text('External appointment').last);
      expect(find.text('An external appointment is confirmed as soon as it is booked.'), findsOneWidget);
      expect(find.text('Approved'), findsWidgets);

      await tester.enterText(find.byKey(const ValueKey('appointment-form-resident-search')), 'rin');
      await tester.pumpAndSettle();
      expect(find.text('#4 · Oak Lodge'), findsOneWidget);
      expect(find.text('#12 · Elm House'), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('appointment-form-resident-search')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No matching clients found'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('appointment-form-resident-search')), 'ayaan');
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('appointment-form-resident-c1')));
      expect(find.text('Selected'), findsOneWidget);
      expect(find.text('Elm House · 12'), findsOneWidget);
      expect(repo.calls, contains('dayLog c1 elm'));

      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('appointment-form-purpose')), matching: find.byType(TextField)),
        'GP review',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('appointment-form-ready')), findsOneWidget);
      expect(find.text('Ready to Submit'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('appointment-form-submit')));
      expect(repo.calls.last, 'create external c1');
      expect(repo.lastInput!.residenceId, 'elm');
      expect(repo.lastInput!.purpose, 'GP review');
      expect(repo.lastInput!.location, isNull);
      expect(repo.lastInput!.scheduledAt, isNotNull);
      expect(find.text('Appointment booked'), findsOneWidget);
    });

    testWidgets('a failed save keeps the form open with the server message', (tester) async {
      final repo = await _open(tester)..failWith = 'Invalid request';
      await _tap(tester, find.byKey(const ValueKey('appointments-create')));
      await tester.enterText(find.byKey(const ValueKey('appointment-form-resident-search')), 'ayaan');
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('appointment-form-resident-c1')));
      await _tap(tester, find.byKey(const ValueKey('appointment-form-submit')));
      expect(repo.calls.last, 'create family_visit c1');
      expect(find.text('This appointment could not be saved'), findsOneWidget);
      expect(find.text('Invalid request'), findsOneWidget);
    });

    testWidgets('export saves appointment_log.csv', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('appointments-export')));
      expect(repo.calls, contains('export'));
      expect(_saved.single.$1, 'appointment_log.csv');
      expect(find.text('Export ready'), findsOneWidget);
    });

    testWidgets('empty tab shows the web empty state', (tester) async {
      await _open(tester, repo: _FakeRepo()..rows = []);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Visit requests from families appear here as they arrive.'), findsOneWidget);
      expect(find.text('0 requests'), findsOneWidget);
    });
  });
}
