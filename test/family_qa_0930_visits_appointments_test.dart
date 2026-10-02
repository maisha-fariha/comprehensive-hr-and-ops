import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/family/appointments/data/mappers/family_appointments_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/family/appointments/domain/entities/family_appointment.dart';
import 'package:comprehensive_hr_and_ops/features/family/appointments/domain/entities/family_appointments_enums.dart';
import 'package:comprehensive_hr_and_ops/features/family/appointments/domain/repositories/family_appointments_repository.dart';
import 'package:comprehensive_hr_and_ops/features/family/appointments/presentation/controllers/appointment_request_controller.dart';
import 'package:comprehensive_hr_and_ops/features/family/appointments/presentation/controllers/family_appointments_controller.dart';
import 'package:comprehensive_hr_and_ops/features/family/appointments/presentation/pages/family_appointments_list_page.dart';
import 'package:comprehensive_hr_and_ops/features/family/profile_settings/domain/entities/family_linked_client.dart';
import 'package:comprehensive_hr_and_ops/features/family/visit_requests/data/mappers/family_visit_requests_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/family/visit_requests/domain/entities/family_visit_requests_enums.dart';
import 'package:comprehensive_hr_and_ops/features/family/visit_requests/domain/entities/family_visit_requests_overview.dart';
import 'package:comprehensive_hr_and_ops/features/family/visit_requests/domain/entities/visit_request_detail.dart';
import 'package:comprehensive_hr_and_ops/features/family/visit_requests/domain/repositories/visit_requests_repository.dart';
import 'package:comprehensive_hr_and_ops/features/family/visit_requests/presentation/controllers/family_visit_requests_controller.dart';
import 'package:comprehensive_hr_and_ops/features/family/visit_requests/presentation/pages/family_visit_requests_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

const _successToast = 'Visit requested! The care team will review and confirm.';
const _dateRequired = 'Please select a date for your visit.';
const _residentRequired = 'Choose who you would like to visit.';

String _iso(DateTime value) => value.toUtc().toIso8601String();

/// Live-shaped `GET /family/appointments` row (demo tenant).
Map<String, dynamic> _row(
  String id,
  String status, {
  DateTime? at,
  String? location = 'Elm House lounge',
  String? decisionReason,
}) =>
    {
      'id': id,
      'purpose': null,
      'type': 'family_visit',
      'clientId': '1d9afca5-5520-4bc6-aa4e-770206ff9d27',
      'residenceId': '7f4957af-1d56-47d7-ac16-0838a4e8ae68',
      'requestedBy': 'c05426f7-1d5f-4f33-a90a-54a5169ee233',
      'status': status,
      'scheduledAt': _iso(at ?? DateTime.now().add(const Duration(days: 3))),
      'location': location,
      'notes': 'Saturday afternoon visit.',
      'decidedBy': decisionReason == null ? null : 'ff744e88-d2bf-4ecb-b178-8dd608d3254d',
      'decidedAt': decisionReason == null ? null : '2026-09-30T08:07:06.979Z',
      'decisionReason': decisionReason,
      'client': {
        'id': '1d9afca5-5520-4bc6-aa4e-770206ff9d27',
        'firstName': 'Ayaan',
        'lastName': 'Karim',
      },
      'residence': {'id': '7f4957af-1d56-47d7-ac16-0838a4e8ae68', 'name': 'Elm House'},
    };

class _CreateCall {
  final String type;
  final String clientId;
  final DateTime scheduledAt;
  final String location;
  final String? notes;

  _CreateCall(this.type, this.clientId, this.scheduledAt, this.location, this.notes);
}

/// One backing store for both repositories, like the single
/// `/family/appointments` endpoint the web and app read.
class _FakeStore implements FamilyAppointmentsRepository, VisitRequestsRepository {
  List<Map<String, dynamic>> rows;
  List<FamilyLinkedClient> residents;
  final List<_CreateCall> creates = [];
  int listCalls = 0;

  _FakeStore({
    required this.rows,
    this.residents = const [
      FamilyLinkedClient(
        id: '1d9afca5-5520-4bc6-aa4e-770206ff9d27',
        initials: 'AK',
        name: 'Ayaan Karim',
        subtitle: 'Elm House',
        statusLabel: 'Active',
      ),
    ],
  });

  Map<String, dynamic> get _body => {'success': true, 'data': rows};

  @override
  Future<Result<List<FamilyAppointment>>> getAppointments() async {
    listCalls++;
    return Result.success(FamilyAppointmentsMapper.listFrom(_body));
  }

  @override
  Future<Result<FamilyVisitRequestsOverview>> getOverview() async {
    listCalls++;
    return Result.success(FamilyVisitRequestsMapper.overviewFrom(_body));
  }

  @override
  Future<Result<List<FamilyLinkedClient>>> getLinkedResidents() async =>
      Result.success(residents);

  @override
  Future<Result<void>> createAppointment({
    required String type,
    required String clientId,
    required DateTime scheduledAt,
    String location = '',
    String? notes,
  }) async {
    creates.add(_CreateCall(type, clientId, scheduledAt, location, notes));
    rows = [
      _row('new-visit-1', 'pending', at: scheduledAt, location: location),
      ...rows,
    ];
    return Result.success(null);
  }

  @override
  Future<Result<VisitRequestDetail>> getRequestDetail(String requestId) async =>
      Result.success(FamilyVisitRequestsMapper.detailFrom(
        rows.firstWhere((row) => row['id'] == requestId),
      ));

  @override
  Future<Result<void>> reschedule({
    String? requestId,
    String? appointmentId,
    required DateTime scheduledAt,
  }) async =>
      Result.success(null);

  @override
  Future<Result<void>> cancel(String id) async => Result.success(null);
}

Widget _app(Widget home) => ScreenUtilInit(
      designSize: const Size(ResponsiveHelper.baseWidth, ResponsiveHelper.baseHeight),
      minTextAdapt: true,
      builder: (_, _) => GetMaterialApp(
        home: home,
        theme: ThemeData(scaffoldBackgroundColor: AppColors.scaffoldBackground),
      ),
    );

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _register(_FakeStore store) {
  final getIt = GetIt.instance;
  getIt.registerSingleton<FamilyAppointmentsRepository>(store);
  getIt.registerSingleton<VisitRequestsRepository>(store);
  getIt.registerFactory<FamilyAppointmentsController>(
    () => FamilyAppointmentsController(repository: store),
  );
  getIt.registerFactory<FamilyVisitRequestsController>(
    () => FamilyVisitRequestsController(repository: store),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _flushToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Set<String> _visibleVisitRequestIds(WidgetTester tester) => tester
    .widgetList(find.byWidgetPredicate(
      (w) => w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('visit-request-') &&
          !(w.key! as ValueKey<String>).value.startsWith('visit-request-status-'),
    ))
    .map((w) => (w.key! as ValueKey<String>).value.substring('visit-request-'.length))
    .toSet();

String _tabCount(WidgetTester tester, String tab) {
  final texts = tester
      .widgetList<Text>(find.descendant(
        of: find.byKey(ValueKey('visit-requests-tab-$tab')),
        matching: find.byType(Text),
      ))
      .map((t) => t.data!)
      .toList();
  return texts.first;
}

Color _pillColor(WidgetTester tester, String id) {
  final box = tester.widget<Container>(
    find.byKey(ValueKey('family-appointment-status-$id')),
  );
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  setUp(() async {
    Get.reset();
    await GetIt.instance.reset();
    Get.testMode = true;
    Get.put(UserSession());
  });

  group('F05 - Request a Visit validation (web modal rules)', () {
    testWidgets('empty Date of Visit blocks submit with the web message', (tester) async {
      _tallView(tester);
      final store = _FakeStore(rows: [_row('a', 'pending')]);
      _register(store);
      await tester.pumpWidget(_app(const FamilyVisitRequestsListPage()));
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Request a Visit'));
      expect(find.text('Date of Visit'), findsOneWidget);
      expect(find.text('Afternoon (02:00 PM – 03:30 PM)'), findsOneWidget);
      expect(find.text("Resident's Private Room"), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('visit-form-submit')));

      expect(find.text(_dateRequired), findsOneWidget);
      expect(store.creates, isEmpty);
      expect(find.byKey(const ValueKey('visit-form-submit')), findsOneWidget);
      expect(find.text(_successToast), findsNothing);
    });

    testWidgets('no linked resident blocks submit with the web message', (tester) async {
      _tallView(tester);
      final store = _FakeStore(rows: const [], residents: const []);
      _register(store);
      await tester.pumpWidget(_app(const FamilyVisitRequestsListPage()));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Request a Visit'));

      Get.find<AppointmentRequestController>().selectDate(
        DateTime.now().add(const Duration(days: 2)),
      );
      await _tap(tester, find.byKey(const ValueKey('visit-form-submit')));

      expect(find.text(_residentRequired), findsOneWidget);
      expect(store.creates, isEmpty);
    });
  });

  group('F06 - submit confirms, leaves the form and refetches the list', () {
    testWidgets('success toast, back on Visit Requests, new request listed', (tester) async {
      _tallView(tester);
      final store = _FakeStore(rows: [_row('a', 'approved')]);
      _register(store);
      await tester.pumpWidget(_app(const FamilyVisitRequestsListPage()));
      await tester.pumpAndSettle();
      expect(_visibleVisitRequestIds(tester), {'a'});

      await _tap(tester, find.text('Request a Visit'));
      await _tap(tester, find.byKey(const ValueKey('visit-form-date')));
      await _tap(tester, find.text('OK'));
      expect(find.text('dd/mm/yyyy'), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('visit-form-submit')));

      expect(store.creates, hasLength(1));
      final call = store.creates.single;
      expect(call.type, 'family_visit');
      expect(call.clientId, '1d9afca5-5520-4bc6-aa4e-770206ff9d27');
      expect(call.location, 'Resident Room');
      expect(call.notes, 'Visitors: 2 people');
      expect(call.scheduledAt.hour, 14);

      expect(find.text(_successToast), findsOneWidget);
      expect(find.byKey(const ValueKey('visit-form-submit')), findsNothing);
      expect(find.byType(FamilyVisitRequestsListPage), findsOneWidget);
      expect(_visibleVisitRequestIds(tester), {'new-visit-1', 'a'});
      expect(
        tester.widget<Text>(find.descendant(
          of: find.byKey(const ValueKey('visit-request-status-new-visit-1')),
          matching: find.byType(Text),
        )).data,
        'Pending',
      );
      await _flushToast(tester);
    });

    testWidgets('from Appointments the new visit shows under Upcoming Visits', (tester) async {
      _tallView(tester);
      final store = _FakeStore(rows: const []);
      _register(store);
      await tester.pumpWidget(_app(const FamilyAppointmentsListPage()));
      await tester.pumpAndSettle();
      expect(find.text('No upcoming visits scheduled'), findsOneWidget);

      await _tap(tester, find.text('Request a Visit'));
      Get.find<AppointmentRequestController>().selectDate(
        DateTime.now().add(const Duration(days: 4)),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('visit-form-submit')));

      expect(find.text(_successToast), findsOneWidget);
      expect(find.byType(FamilyAppointmentsListPage), findsOneWidget);
      expect(find.byKey(const ValueKey('family-appointment-new-visit-1')), findsOneWidget);
      await _flushToast(tester);
    });
  });

  group('F07 - Visit Request status tabs filter exactly', () {
    testWidgets('each status tab lists only that status and counts match', (tester) async {
      _tallView(tester);
      final store = _FakeStore(rows: [
        _row('p1', 'pending'),
        _row('a1', 'approved'),
        _row('r1', 'rejected', decisionReason: 'Clashes with the GP round'),
        _row('r2', 'rejected'),
        _row('c1', 'cancelled'),
        _row('d1', 'completed', at: DateTime.now().subtract(const Duration(days: 5))),
      ]);
      _register(store);
      await tester.pumpWidget(_app(const FamilyVisitRequestsListPage()));
      await tester.pumpAndSettle();

      const expected = {
        'all': {'p1', 'a1', 'r1', 'r2', 'c1', 'd1'},
        'pending': {'p1'},
        'approved': {'a1'},
        'rejected': {'r1', 'r2'},
        'cancelled': {'c1'},
        'completed': {'d1'},
      };
      final controller = Get.find<FamilyVisitRequestsController>();
      for (final entry in expected.entries) {
        await _tap(tester, find.byKey(ValueKey('visit-requests-tab-${entry.key}')));
        expect(controller.visibleRequests.map((r) => r.id).toSet(), entry.value, reason: entry.key);
        final rendered = _visibleVisitRequestIds(tester);
        expect(rendered, isNotEmpty, reason: entry.key);
        expect(entry.value.containsAll(rendered), isTrue, reason: entry.key);
        if (entry.value.length <= 2) expect(rendered, entry.value, reason: entry.key);
        expect(_tabCount(tester, entry.key), '${entry.value.length}', reason: entry.key);
      }

      await _tap(tester, find.byKey(const ValueKey('visit-requests-tab-cancelled')));
      expect(find.text('Cancelled'), findsWidgets);
      expect(find.text('Pending'), findsOneWidget);
    });
  });

  group('F08 - cancelled / rejected never shown as Pending', () {
    test('mapper keeps the real status and a human title', () {
      final rejected = FamilyAppointmentsMapper.fromJson(_row('r', 'rejected'));
      final cancelled = FamilyAppointmentsMapper.fromJson(_row('c', 'cancelled'));
      final unknown = FamilyAppointmentsMapper.fromJson(_row('u', 'on_hold'));

      expect(rejected.status, FamilyAppointmentStatus.rejected);
      expect(rejected.statusLabel, 'Rejected');
      expect(cancelled.status, FamilyAppointmentStatus.cancelled);
      expect(cancelled.statusLabel, 'Cancelled');
      expect(unknown.status, FamilyAppointmentStatus.other);
      expect(unknown.statusLabel, 'On hold');
      expect(rejected.title, 'Family Visit');
      expect(rejected.location, 'Elm House lounge');
      expect(rejected.isPastAt(DateTime.now()), isTrue);
      expect(cancelled.isPastAt(DateTime.now()), isTrue);

      expect(
        FamilyVisitRequestsMapper.statusFrom('on_hold'),
        VisitRequestStatus.other,
      );
      expect(
        FamilyVisitRequestsMapper.detailFrom({'data': _row('r', 'rejected')}).purpose,
        'Family Visit',
      );
    });

    testWidgets('Upcoming / Past tabs, labels and colours follow the web', (tester) async {
      _tallView(tester);
      final soon = DateTime.now().add(const Duration(days: 1));
      final store = _FakeStore(rows: [
        _row('p1', 'pending', at: soon),
        _row('r1', 'rejected', at: soon, decisionReason: 'x'),
        _row('r2', 'rejected', at: soon.add(const Duration(hours: 2))),
        _row('c1', 'cancelled', at: soon),
      ]);
      _register(store);
      await tester.pumpWidget(_app(const FamilyAppointmentsListPage()));
      await tester.pumpAndSettle();

      expect(find.text('Visits & Appointments'), findsOneWidget);
      expect(find.text('Upcoming Visits'), findsOneWidget);
      expect(find.text('Past Visits'), findsOneWidget);
      expect(find.text('family_visit'), findsNothing);
      expect(find.text('Family Visit'), findsOneWidget);
      expect(find.byKey(const ValueKey('family-appointment-p1')), findsOneWidget);
      for (final id in ['r1', 'r2', 'c1']) {
        expect(find.byKey(ValueKey('family-appointment-$id')), findsNothing);
      }
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Waiting for the care home to confirm your slot.'), findsOneWidget);
      expect(_pillColor(tester, 'p1'), const Color(0xFFFFF7E8));

      await _tap(tester, find.byKey(const ValueKey('family-appointments-tab-past')));

      expect(find.byKey(const ValueKey('family-appointment-p1')), findsNothing);
      expect(find.text('Pending'), findsNothing);
      expect(find.text('Rejected'), findsNWidgets(2));
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('This visit was withdrawn.'), findsOneWidget);
      expect(
        find.text('The care home could not accommodate this specific time.'),
        findsNWidgets(2),
      );
      expect(_pillColor(tester, 'r1'), const Color(0xFFFBEAEA));
      expect(_pillColor(tester, 'c1'), const Color(0xFFF4F5F7));
      expect(find.text('Family Visit'), findsNWidgets(3));
      expect(find.text('family_visit'), findsNothing);
    });

    testWidgets('re-entering the screen refetches so a staff rejection replaces Pending', (tester) async {
      _tallView(tester);
      final store = _FakeStore(rows: [_row('v1', 'pending')]);
      _register(store);
      await tester.pumpWidget(_app(const FamilyAppointmentsListPage()));
      await tester.pumpAndSettle();
      expect(find.text('Pending'), findsOneWidget);

      store.rows = [_row('v1', 'rejected', decisionReason: 'Fully booked')];
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpWidget(_app(const FamilyAppointmentsListPage()));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsNothing);
      expect(find.byKey(const ValueKey('family-appointment-v1')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('family-appointments-tab-past')));
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('showing the shell tab again refetches (IndexedStack)', (tester) async {
      _tallView(tester);
      final store = _FakeStore(rows: [_row('v1', 'pending')]);
      _register(store);
      final index = ValueNotifier<int>(0);
      await tester.pumpWidget(_app(Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: index,
          builder: (_, value, _) => IndexedStack(
            index: value,
            children: const [FamilyAppointmentsListPage(), SizedBox()],
          ),
        ),
      )));
      await tester.pumpAndSettle();
      final before = store.listCalls;

      index.value = 1;
      await tester.pumpAndSettle();
      store.rows = [_row('v1', 'cancelled')];
      index.value = 0;
      await tester.pumpAndSettle();

      expect(store.listCalls, greaterThan(before));
      expect(find.text('Pending'), findsNothing);
      expect(Get.find<FamilyAppointmentsController>().pastAppointments.single.statusLabel, 'Cancelled');
    });
  });
}
