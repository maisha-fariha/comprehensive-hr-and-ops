import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/network/tenant_store.dart';
import 'package:comprehensive_hr_and_ops/core/network/token_store.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/core/theme/app_theme.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/data/mappers/emergency_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/domain/entities/emergency_alert.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/domain/repositories/emergency_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/presentation/controllers/emergency_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/presentation/pages/emergency_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/presentation/widgets/raise_emergency_sheet.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/data/mappers/incidents_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/data/repositories/incidents_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_category_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_cir_template_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_client_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_residence_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_staff_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/repositories/incidents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/presentation/controllers/incident_creation_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/presentation/widgets/steps/step1_details_form.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/presentation/widgets/steps/step2_people_form.dart';
import 'package:comprehensive_hr_and_ops/features/hr/presentation/manager_destinations.dart';
import 'package:comprehensive_hr_and_ops/features/hr/team_reports/presentation/widgets/team_reports_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

Widget _app(Widget home, {ThemeData? theme}) => ScreenUtilInit(
      designSize: const Size(
        ResponsiveHelper.baseWidth,
        ResponsiveHelper.baseHeight,
      ),
      minTextAdapt: true,
      builder: (_, _) => GetMaterialApp(
        home: home,
        theme: theme ??
            ThemeData(
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

Finder _field(TextEditingController controller) => find.byWidgetPredicate(
      (w) => w is TextField && w.controller == controller,
    );

Finder _inKey(String key, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: matching);

class _Session extends UserSession {
  final Set<String> denied;

  _Session({this.denied = const {}});

  @override
  bool can(String permission) => !denied.contains(permission);

  @override
  String? get residenceId => 'elm';

  @override
  String? get residenceName => 'Elm House';

  @override
  String get displayName => 'Rafi Ahmed';
}

// ------------------------------------------------------------- BUG17 ----

final _active = EmergencyAlert(
  id: 'a1',
  type: 'security',
  status: 'active',
  priority: 'high',
  note: 'Unknown visitor refusing to leave the front step.',
  residenceName: 'Elm House',
  residencePhone: '+880-2-555-0100',
  residenceEmergencyPhone: '+880-2-555-0199',
  raiser: const EmergencyPerson(id: 'u1', name: 'Ruma Begum', phone: '+880-17-0000-0000'),
  createdAt: DateTime(2026, 8, 27, 9, 33),
);

final _resolved = EmergencyAlert(
  id: 'a2',
  type: 'medical',
  status: 'resolved',
  priority: 'standard',
  note: 'Suspected asthma attack in the lounge.',
  residenceName: 'Elm House',
  residencePhone: '+880-2-555-0100',
  clientName: 'Ayaan Karim',
  locationNote: 'Lounge',
  raiser: const EmergencyPerson(id: 'u2', name: 'Jamal Uddin'),
  acknowledger: const EmergencyPerson(id: 'u3', name: 'Priya Das'),
  assignee: const EmergencyPerson(id: 'u3', name: 'Priya Das'),
  acknowledgedAt: DateTime(2026, 8, 27, 2, 33),
  resolvedAt: DateTime.now(),
  resolutionNote: 'Inhaler administered, breathing settled.',
  createdAt: DateTime(2026, 8, 27, 1, 33),
);

class _FakeEmergencyRepo implements EmergencyRepository {
  List<EmergencyAlert> rows = [_active, _resolved];
  bool failList = false;
  List<EmergencyOption> homes = const [
    EmergencyOption(id: 'elm', label: 'Elm House'),
    EmergencyOption(id: 'oak', label: 'Oak Lodge'),
  ];
  final List<Map<String, Object?>> listQueries = [];
  final List<String> calls = [];
  Map<String, Object?>? raised;
  EmergencyAlert? detail;

  @override
  Future<Result<EmergencyAlertPage>> list({
    String? status,
    required int page,
    required int limit,
  }) async {
    listQueries.add({'status': status, 'page': page, 'limit': limit});
    if (failList && limit != 100) {
      return Result.failure(const ApiError(message: 'offline'));
    }
    final items = status == null ? rows : rows.where((r) => r.status == status).toList();
    return Result.success(EmergencyAlertPage(items: items, total: items.length));
  }

  @override
  Future<Result<EmergencyAlert>> byId(String id) async =>
      Result.success(detail ?? rows.firstWhere((r) => r.id == id));

  @override
  Future<Result<void>> raise({
    required String residenceId,
    required String type,
    String? note,
    String? locationNote,
    double? latitude,
    double? longitude,
  }) async {
    raised = {
      'residenceId': residenceId,
      'type': type,
      'note': note,
      'locationNote': locationNote,
      'latitude': latitude,
      'longitude': longitude,
    };
    return Result.success(null);
  }

  Future<Result<void>> _log(String call) async {
    calls.add(call);
    return Result.success(null);
  }

  @override
  Future<Result<void>> acknowledge(String id) => _log('acknowledge $id');

  @override
  Future<Result<void>> resolve(String id) => _log('resolve $id');

  @override
  Future<Result<void>> assign(String id, String userId) => _log('assign $id $userId');

  @override
  Future<Result<void>> setStatus(String id, String status) => _log('status $id $status');

  @override
  Future<Result<void>> addNote(String id, String note) => _log('note $id $note');

  @override
  Future<Result<void>> delete(String id) => _log('delete $id');

  @override
  Future<Result<List<EmergencyOption>>> residences() async => Result.success(homes);
}

Future<_FakeEmergencyRepo> _openEmergency(
  WidgetTester tester, {
  _FakeEmergencyRepo? repo,
  Set<String> denied = const {},
}) async {
  _tallView(tester);
  final fake = repo ?? _FakeEmergencyRepo();
  final session = Get.put<UserSession>(_Session(denied: denied));
  GetIt.I.registerFactory<EmergencyController>(
    () => EmergencyController(repository: fake, session: session),
  );
  await tester.pumpWidget(_app(const EmergencyPage()));
  await tester.pumpAndSettle();
  return fake;
}

// ------------------------------------------------------------- BUG18-20 ----

class _FakeIncidentsRepo implements IncidentsRepository {
  final List<String> searches = [];
  Map<String, dynamic>? detail;
  Map<String, dynamic>? updatedPayload;

  static const clients = [
    IncidentClientOption(id: 'c1', name: 'Ayaan Karim', subtitle: 'Client · Elm House'),
    IncidentClientOption(id: 'c2', name: 'Nadia Islam', subtitle: 'Client · Oak Lodge'),
  ];

  @override
  Future<Result<List<IncidentCategoryOption>>> getCategories() async =>
      Result.success(const [IncidentCategoryOption(id: 'cat', name: 'Fall')]);

  @override
  Future<Result<List<IncidentCirTemplateOption>>> getCirTemplates() async =>
      Result.success(const []);

  @override
  Future<Result<List<IncidentResidenceOption>>> getResidences() async =>
      Result.success(const [IncidentResidenceOption(id: 'elm', name: 'Elm House')]);

  @override
  Future<Result<List<IncidentStaffOption>>> getStaff() async => Result.success(const []);

  @override
  Future<Result<List<IncidentClientOption>>> searchClients(String search) async {
    searches.add(search);
    final q = search.trim().toLowerCase();
    return Result.success(
      clients.where((c) => c.name.toLowerCase().contains(q)).toList(),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getIncidentDetail(String incidentId) async =>
      Result.success(detail!);

  @override
  Future<Result<void>> updateIncident({
    required String incidentId,
    required String residenceId,
    required String clientId,
    required String categoryId,
    required String title,
    required String severity,
    required Map<String, dynamic> payload,
    String? cirTemplateId,
    String? status,
    String? reportedAt,
    bool residentChecked = false,
    bool supervisorNotified = false,
    bool familyNotified = false,
    bool carePlanReviewed = false,
  }) async {
    updatedPayload = payload;
    return Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<(IncidentCreationController, _FakeIncidentsRepo)> _openWizardStep(
  WidgetTester tester,
  Widget Function(IncidentCreationController) step, {
  _FakeIncidentsRepo? repo,
  String? editId,
}) async {
  _tallView(tester);
  final fake = repo ?? _FakeIncidentsRepo();
  final c = Get.put(
    IncidentCreationController(
      repository: fake,
      session: _Session(),
      editIncidentId: editId,
    ),
  );
  await tester.pumpWidget(
    _app(Scaffold(body: SingleChildScrollView(child: step(c)))),
  );
  await tester.pumpAndSettle();
  return (c, fake);
}

class _FakeApi implements AppApiClient {
  final List<Map<String, dynamic>?> queries = [];

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) async {
    queries.add(query);
    return Result.success({
      'data': [
        {'id': 'c1', 'firstName': 'Ayaan', 'lastName': 'Karim', 'residence': {'name': 'Elm House'}},
        {'id': 'c2', 'firstName': 'Nadia', 'lastName': 'Islam', 'residence': {'name': 'Oak Lodge'}},
      ],
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoTokens implements TokenStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoTenant implements TenantStore {
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

  group('BUG15/16 network error action', () {
    Color labelColor(WidgetTester tester, String text) =>
        tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color!;

    testWidgets('a teal button that only sets its background gets a white label '
        'from the app theme', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryTeal),
                child: const Text('Try again'),
              ),
            ),
          ),
          theme: AppTheme.lightTheme,
        ),
      );
      await tester.pumpAndSettle();
      expect(labelColor(tester, 'Try again'), Colors.white);
    });

    testWidgets('the Team & Reports error view shows a readable Retry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: TeamReportsErrorView(
              message: 'Could not reach the server.',
              onRetry: () async => retried++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(labelColor(tester, 'Retry'), Colors.white);
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });
  });

  group('BUG17 Emergency', () {
    test('mapper reads the live alert payload', () {
      final page = EmergencyMapper.pageFrom({
        'data': [
          {
            'id': 'b355',
            'type': 'medical',
            'status': 'resolved',
            'priority': 'high',
            'note': 'Suspected asthma attack in the lounge.',
            'locationNote': null,
            'acknowledgedAt': '2026-08-27T02:33:06.745Z',
            'resolvedAt': '2026-08-27T03:33:06.745Z',
            'resolutionNote': 'Inhaler administered.',
            'createdAt': '2026-08-27T09:33:09.149Z',
            'raiser': {'id': 'u2', 'name': 'Jamal Uddin', 'phone': '+880-17-0000-0000'},
            'acknowledger': {'id': 'u3', 'name': 'Priya Das'},
            'assignee': null,
            'residence': {
              'id': 'elm',
              'name': 'Elm House',
              'phone': '+880-2-555-0100',
              'emergencyPhone': '+880-2-555-0199',
            },
            'client': {'id': 'c1', 'firstName': 'Ayaan', 'lastName': 'Karim', 'name': 'Ayaan Karim'},
            'actions': [
              {
                'id': 'x1',
                'action': 'assigned',
                'actor': {'id': 'u3', 'name': 'Priya Das'},
                'targetUser': {'id': 'u4', 'name': 'Omar Faruk'},
                'note': null,
                'createdAt': '2026-08-27T02:40:00.000Z',
              },
            ],
            'attachments': [
              {'id': 'f1', 'fileUrl': 'https://x/uploads/photo.jpg'},
            ],
          },
        ],
        'meta': {'total': 7},
      });
      expect(page.total, 7);
      final a = page.items.single;
      expect(a.raiser!.phone, '+880-17-0000-0000');
      expect(a.clientName, 'Ayaan Karim');
      expect(a.houseLine, '+880-2-555-0199');
      expect(a.acknowledger!.name, 'Priya Das');
      expect(a.assignee, isNull);
      expect(a.actions.single.targetName, 'Omar Faruk');
      expect(a.attachments.single.fileName, 'photo.jpg');
      expect(a.isClosed, isTrue);
    });

    test('KPIs count active, acknowledged, in progress and resolved since midnight', () {
      final now = DateTime(2026, 9, 29, 10);
      EmergencyAlert alert(String status, {DateTime? resolvedAt}) =>
          EmergencyAlert(id: status, type: 'other', status: status, resolvedAt: resolvedAt);
      final stats = EmergencyStats.from([
        alert('active'),
        alert('active'),
        alert('acknowledged'),
        alert('in_progress'),
        alert('resolved', resolvedAt: DateTime(2026, 9, 29, 0, 5)),
        alert('resolved', resolvedAt: DateTime(2026, 9, 28, 23, 59)),
        alert('cancelled'),
      ], now: now);
      expect(
        (stats.active, stats.awaitingResponse, stats.inProgress, stats.resolvedToday),
        (2, 1, 1, 1),
      );
    });

    testWidgets('board opens on Active with the web KPIs, row lines, pills and actions',
        (tester) async {
      final repo = await _openEmergency(tester);

      expect(find.text('Emergency Alarms'), findsOneWidget);
      expect(_inKey('emergency-status-filter', find.text('Active')), findsOneWidget);
      expect(repo.listQueries, containsAll([
        {'status': 'active', 'page': 1, 'limit': 10},
        {'status': null, 'page': 1, 'limit': 100},
      ]));

      expect(_inKey('emergency-kpi-active', find.text('1')), findsOneWidget);
      expect(_inKey('emergency-kpi-active', find.text('UNANSWERED')), findsOneWidget);
      expect(find.text('Nobody has acknowledged these'), findsOneWidget);
      expect(_inKey('emergency-kpi-awaiting', find.text('AWAITING RESPONSE')), findsOneWidget);
      expect(find.text('Seen, but nobody is on the way yet'), findsOneWidget);
      expect(_inKey('emergency-kpi-in-progress', find.text('BEING HANDLED')), findsOneWidget);
      expect(find.text('Somebody is dealing with it now'), findsOneWidget);
      expect(_inKey('emergency-kpi-resolved', find.text('1')), findsOneWidget);
      expect(find.text('Closed since midnight'), findsOneWidget);

      final row = find.byKey(const ValueKey('emergency-a1'));
      for (final text in ['Active', 'High', 'Security', 'Elm House', 'Open', 'Acknowledge',
          'Resolve', 'Unknown visitor refusing to leave the front step.',
          'House line: +880-2-555-0199']) {
        expect(find.descendant(of: row, matching: find.text(text)), findsOneWidget, reason: text);
      }
      expect(
        find.descendant(of: row, matching: find.textContaining('Raised by Ruma Begum · +880-17-0000-0000 · ')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('emergency-delete-a1')), findsOneWidget);
      expect(find.text('Showing 1 to 1 of 1 entries'), findsOneWidget);
    });

    testWidgets('All shows resolved rows without Acknowledge / Resolve; standard priority '
        'has no pill', (tester) async {
      final repo = await _openEmergency(tester);
      await _tap(tester, find.byKey(const ValueKey('emergency-status-filter')));
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      expect(repo.listQueries.last, {'status': null, 'page': 1, 'limit': 10});

      final row = find.byKey(const ValueKey('emergency-a2'));
      for (final text in ['Resolved', 'Medical emergency', 'Resident: Ayaan Karim',
          'Where: Lounge', 'Assigned to Priya Das',
          'Resolution: Inhaler administered, breathing settled.']) {
        expect(find.descendant(of: row, matching: find.text(text)), findsOneWidget, reason: text);
      }
      expect(find.descendant(of: row, matching: find.text('Standard')), findsNothing);
      expect(find.descendant(of: row, matching: find.textContaining('Acknowledged by Priya Das · ')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('emergency-acknowledge-a2')), findsNothing);
      expect(find.byKey(const ValueKey('emergency-resolve-a2')), findsNothing);
      expect(find.byKey(const ValueKey('emergency-delete-a2')), findsOneWidget);
    });

    testWidgets('Acknowledge, Resolve and Delete (after the web confirm) call the endpoints',
        (tester) async {
      final repo = await _openEmergency(tester);
      await _tap(tester, find.byKey(const ValueKey('emergency-acknowledge-a1')));
      expect(find.text('Alarm acknowledged — the raiser can see you are coming'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('emergency-resolve-a1')));
      expect(find.text('Alarm resolved'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('emergency-delete-a1')));
      expect(find.text('Delete this alert?'), findsOneWidget);
      expect(
        find.text('It leaves the board. The alert, its actions and who answered it are '
            'kept rather than destroyed, so it can be restored.'),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const ValueKey('emergency-delete-confirm')));
      expect(repo.calls, ['acknowledge a1', 'resolve a1', 'delete a1']);
      expect(find.text('Alert deleted'), findsOneWidget);
    });

    testWidgets('detail: what was reported, response timeline, note, hand it to, '
        'I am on it and Resolve', (tester) async {
      final repo = _FakeEmergencyRepo();
      repo.detail = EmergencyAlert(
        id: 'a1',
        type: 'security',
        status: 'active',
        priority: 'high',
        residenceName: 'Elm House',
        residenceEmergencyPhone: '+880-2-555-0199',
        locationNote: 'Front step',
        raiser: const EmergencyPerson(id: 'u1', name: 'Ruma Begum', phone: '+880-17-0000-0000'),
        createdAt: DateTime(2026, 8, 27, 9, 33),
        actions: [
          EmergencyAction(
            id: 'x',
            action: 'raised',
            actorName: 'Ruma Begum',
            createdAt: DateTime(2026, 8, 27, 9, 33),
          ),
          const EmergencyAction(id: 'y', action: 'assigned', actorName: 'Priya Das',
              targetName: 'Jamal Uddin', note: 'Go now'),
        ],
      );
      await _openEmergency(tester, repo: repo);
      await _tap(tester, find.byKey(const ValueKey('emergency-open-a1')));

      expect(find.text('Security'), findsWidgets);
      expect(find.textContaining('Elm House · Front step · '), findsOneWidget);
      for (final text in ['What was reported', 'No description was given.', 'RAISED BY',
          'Ruma Begum', 'RESIDENT', 'Not about a resident', 'WHERE IN THE BUILDING',
          'ASSIGNED TO', 'Nobody yet', 'HOUSE LINE', '+880-2-555-0199', "REPORTER'S PHONE",
          'Response', 'Alarm raised', 'Assigned', '→ Jamal Uddin', 'Go now',
          'Add to the response', 'Hand it to', 'Choose who is going',
          'The person who saw the alarm is often not the person who can go',
          'Close', 'I am on it']) {
        expect(find.text(text), findsWidgets, reason: text);
      }

      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('emergency-note')), matching: find.byType(TextField)),
        'Police called',
      );
      await tester.pump();
      await _tap(tester, find.byKey(const ValueKey('emergency-add-note')));
      expect(find.text('Added to the response'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('emergency-hand-to')));
      for (final person in ['Ruma Begum', 'Jamal Uddin', 'Priya Das']) {
        expect(find.text(person), findsWidgets);
      }
      await tester.tap(find.text('Priya Das').last);
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('emergency-assign')));
      expect(find.text('Assigned — they have been told directly'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('emergency-on-it')));
      expect(find.text('Marked as being handled'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('emergency-detail-resolve')));
      expect(find.text('What was reported'), findsNothing);
      expect(repo.calls, [
        'note a1 Police called',
        'assign a1 u3',
        'status a1 in_progress',
        'resolve a1',
      ]);
    });

    testWidgets('a resolved alarm opens read-only', (tester) async {
      await _openEmergency(tester);
      await _tap(tester, find.byKey(const ValueKey('emergency-status-filter')));
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('emergency-open-a2')));
      expect(find.text('What was reported'), findsOneWidget);
      expect(find.text('Add to the response'), findsNothing);
      expect(find.byKey(const ValueKey('emergency-on-it')), findsNothing);
      expect(find.byKey(const ValueKey('emergency-detail-resolve')), findsNothing);
    });

    testWidgets('without emergency:respond only Open remains; without raise there is no '
        'Emergency button', (tester) async {
      await _openEmergency(tester, denied: {'emergency:respond', 'emergency:raise'});
      expect(find.byKey(const ValueKey('emergency-open-a1')), findsOneWidget);
      expect(find.byKey(const ValueKey('emergency-acknowledge-a1')), findsNothing);
      expect(find.byKey(const ValueKey('emergency-resolve-a1')), findsNothing);
      expect(find.byKey(const ValueKey('emergency-delete-a1')), findsNothing);
      expect(find.byKey(const ValueKey('raise-emergency-button')), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('emergency-open-a1')));
      expect(find.text('Add to the response'), findsOneWidget);
      expect(find.text('Hand it to'), findsNothing);
      expect(find.byKey(const ValueKey('emergency-on-it')), findsNothing);
    });

    testWidgets('empty and failed lists use the web empty states', (tester) async {
      final repo = _FakeEmergencyRepo()..rows = [];
      await _openEmergency(tester, repo: repo);
      expect(find.text('Nothing to respond to'), findsOneWidget);
      expect(find.text('Raised alarms appear here the moment they come in.'), findsOneWidget);
      expect(find.textContaining('Showing'), findsNothing);

      repo.failList = true;
      Get.find<EmergencyController>().load();
      await tester.pumpAndSettle();
      expect(find.text('Alarms could not be loaded'), findsOneWidget);
      expect(find.text('The list will reappear on the next refresh.'), findsOneWidget);
    });

    testWidgets('Emergency button raises an alarm; a residence is required', (tester) async {
      final repo = await _openEmergency(tester);
      await _tap(tester, find.byKey(const ValueKey('raise-emergency-button')));

      expect(find.text('Raise emergency alarm'), findsOneWidget);
      expect(find.text('Everyone on the response team is notified immediately.'), findsOneWidget);
      expect(find.text('Choose a residence'), findsOneWidget);
      expect(_inKey('raise-emergency-type', find.text('Medical emergency')), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('raise-emergency-submit')));
      expect(find.text('Choose where help is needed.'), findsOneWidget);
      expect(repo.raised, isNull);

      await _tap(tester, find.byKey(const ValueKey('raise-emergency-type')));
      for (final kind in ['Fall', 'Resident behaviour', 'Missing resident', 'Safety concern',
          'Fire or facility', 'Security', 'Other']) {
        expect(find.text(kind), findsWidgets, reason: kind);
      }
      await tester.tap(find.text('Fall').last);
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('raise-emergency-residence')));
      await tester.tap(find.text('Oak Lodge').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('raise-emergency-where')), matching: find.byType(TextField)),
        'Room 102',
      );
      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('raise-emergency-what')), matching: find.byType(TextField)),
        'Resident on the floor',
      );
      await tester.tap(find.byKey(const ValueKey('raise-emergency-submit')));
      await tester.pump();
      expect(find.text('Raising…'), findsOneWidget);
      // No location plugin in tests: the 3 s limit gives up on the position.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(repo.raised, {
        'residenceId': 'oak',
        'type': 'fall',
        'note': 'Resident on the floor',
        'locationNote': 'Room 102',
        'latitude': null,
        'longitude': null,
      });
      expect(find.text('Raise emergency alarm'), findsNothing);
      expect(find.text('Alarm raised — the response team has been alerted'), findsOneWidget);
    });

    testWidgets('one residence is chosen automatically and the position is sent', (tester) async {
      _tallView(tester);
      final repo = _FakeEmergencyRepo()
        ..homes = const [EmergencyOption(id: 'elm', label: 'Elm House')];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: RaiseEmergencySheet(
              repository: repo,
              locate: () async => (latitude: 23.78, longitude: 90.40),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_inKey('raise-emergency-residence', find.text('Elm House')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('raise-emergency-submit')));
      expect(repo.raised, {
        'residenceId': 'elm',
        'type': 'medical',
        'note': null,
        'locationNote': null,
        'latitude': 23.78,
        'longitude': 90.40,
      });
    });

    test('the manager menu lists Emergency only with emergency:read', () {
      Get.put<UserSession>(_Session());
      expect(managerDestinations().where((d) => d.title == 'Emergency'), hasLength(1));
      expect(managerDestinations().firstWhere((d) => d.title == 'Emergency').matches('alarm'),
          isTrue);
      Get.reset();
      Get.put<UserSession>(_Session(denied: {'emergency:read'}));
      expect(managerDestinations().where((d) => d.title == 'Emergency'), isEmpty);
    });
  });

  group('BUG18 incident client search', () {
    test('clients with only firstName / lastName are named, subtitled like the web', () {
      final options = IncidentsMapper.clientsFrom({
        'data': [
          {'id': 'c1', 'firstName': 'Ayaan', 'lastName': 'Karim', 'residence': {'name': 'Elm House'}},
          {'id': 'c2', 'firstName': 'Nadia', 'lastName': null},
          {'id': 'c3', 'name': 'Legacy Name'},
        ],
      });
      expect([for (final o in options) (o.name, o.subtitle)], [
        ('Ayaan Karim', 'Client · Elm House'),
        ('Nadia', 'Client'),
        ('Legacy Name', 'Client'),
      ]);
    });

    test('the repository loads 100 clients once, without a residence filter, and '
        'matches names locally', () async {
      final api = _FakeApi();
      final repo = IncidentsRepositoryImpl(
        api: api,
        session: _Session(),
        tokens: _NoTokens(),
        tenant: _NoTenant(),
      );
      final kar = await repo.searchClients('kar');
      final all = await repo.searchClients('');
      final none = await repo.searchClients('zzz');
      expect(kar.value!.map((c) => c.name), ['Ayaan Karim']);
      expect(all.value!.map((c) => c.name), ['Ayaan Karim', 'Nadia Islam']);
      expect(none.value, isEmpty);
      expect(api.queries, [
        {'page': 1, 'limit': 100},
      ]);
    });

    testWidgets('tapping Client / Resident lists every client; typing filters; the choice '
        'shows as Selected and X clears it', (tester) async {
      final (c, repo) = await _openWizardStep(tester, (c) => Step1DetailsForm(controller: c));
      expect(find.text('Type to search client'), findsOneWidget);

      await _tap(tester, _field(c.clientController));
      expect(find.text('Ayaan Karim'), findsOneWidget);
      expect(find.text('Client · Elm House'), findsOneWidget);
      expect(find.text('Nadia Islam'), findsOneWidget);

      await tester.enterText(_field(c.clientController), 'zz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('No matches found'), findsOneWidget);

      await tester.enterText(_field(c.clientController), 'nad');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Ayaan Karim'), findsNothing);
      await _tap(tester, find.text('Nadia Islam'));

      expect(c.selectedClient.value!.id, 'c2');
      expect(find.text('Selected'), findsOneWidget);
      expect(find.text('Client · Oak Lodge'), findsOneWidget);
      expect(find.text('NI'), findsOneWidget);
      expect(repo.searches, ['', 'zz', 'nad']);

      await _tap(tester, find.byTooltip('Change client'));
      expect(c.selectedClient.value, isNull);
      expect(find.text('Selected'), findsNothing);
      expect(_field(c.clientController), findsOneWidget);
    });

    testWidgets('step 2 Involved Client uses the same picker', (tester) async {
      final (c, _) = await _openWizardStep(tester, (c) => Step2PeopleForm(controller: c));
      await _tap(tester, _field(c.involvedClientController));
      expect(find.text('Client · Oak Lodge'), findsOneWidget);
      await _tap(tester, find.text('Ayaan Karim'));
      expect(c.selectedInvolvedClient.value!.id, 'c1');
      expect(find.text('Selected'), findsOneWidget);
      await _tap(tester, find.byTooltip('Change client'));
      expect(c.selectedInvolvedClient.value, isNull);
    });
  });

  group('BUG19 Time Ended', () {
    testWidgets('an optional Time Ended picker sits under Date / Time and can be cleared',
        (tester) async {
      final (c, _) = await _openWizardStep(tester, (c) => Step1DetailsForm(controller: c));
      expect(find.text('Time Ended (optional)', findRichText: true), findsOneWidget);
      expect(c.endTimeController.text, isEmpty);

      await _tap(tester, _field(c.endTimeController));
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(c.endTimeController.text, matches(RegExp(r'^\d{2}:\d{2}$')));

      await _tap(tester, find.byTooltip('Clear time ended'));
      expect(c.endTimeController.text, isEmpty);
      expect(find.byTooltip('Clear time ended'), findsNothing);
    });
  });

  group('BUG20 CFS Details', () {
    testWidgets('step 2 has the CFS Details card; statuses add and remove as chips',
        (tester) async {
      final (c, _) = await _openWizardStep(tester, (c) => Step2PeopleForm(controller: c));
      expect(find.text('CFS Details  (optional)', findRichText: true), findsOneWidget);
      for (final label in ["Child's I.D. Number", 'CFS Status',
          'Child Intervention Practitioner (CIP)', 'CIP Office', 'Add status']) {
        expect(find.text(label, findRichText: true), findsWidgets, reason: label);
      }

      await _tap(tester, find.text('Add status'));
      for (final s in IncidentCreationController.cfsStatusOptions) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      await tester.tap(find.text('PGO'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Add status'));
      expect(find.text('PGO'), findsOneWidget);
      await tester.tap(find.text('ICO'));
      await tester.pumpAndSettle();
      expect(c.cfsStatuses, ['PGO', 'ICO']);

      await _tap(tester, find.text('PGO'));
      expect(c.cfsStatuses, ['ICO']);
    });

    testWidgets('edit mode loads end time and CFS from payloadJson and saves the web keys',
        (tester) async {
      final repo = _FakeIncidentsRepo()
        ..detail = {
          'id': 'inc-1',
          'title': 'Fall in lounge',
          'status': 'open',
          'severity': 'high',
          'categoryId': 'cat',
          'clientId': 'c1',
          'client': {'id': 'c1', 'name': 'Ayaan Karim'},
          'residenceId': 'elm',
          'reportedAt': '2026-09-29T08:15:00.000Z',
          'payloadJson': {
            'endTime': '09:40',
            'childIdNumber': 'CH-123',
            'cfsStatus': ['tgo', 'SFP', 'XYZ'],
            'childInterventionPractitioner': 'Sara Khan',
            'cipOffice': 'North',
          },
        };
      final (c, _) = await _openWizardStep(
        tester,
        (c) => Step2PeopleForm(controller: c),
        repo: repo,
        editId: 'inc-1',
      );
      expect(c.endTimeController.text, '09:40');
      expect(c.childIdController.text, 'CH-123');
      expect(c.cfsStatuses, ['TGO', 'SFP']);
      expect(c.cipController.text, 'Sara Khan');
      expect(c.cipOfficeController.text, 'North');
      expect(find.text('TGO'), findsOneWidget);

      expect(await c.submit(), isTrue);
      expect(repo.updatedPayload, containsPair('endTime', '09:40'));
      expect(repo.updatedPayload, containsPair('childIdNumber', 'CH-123'));
      expect(repo.updatedPayload, containsPair('cfsStatus', ['TGO', 'SFP']));
      expect(repo.updatedPayload, containsPair('cipName', 'Sara Khan'));
      expect(repo.updatedPayload, containsPair('cipOffice', 'North'));
      expect(repo.updatedPayload!.containsKey('childInterventionPractitioner'), isFalse);
    });
  });
}
