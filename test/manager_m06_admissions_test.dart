import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/admissions/data/mappers/admissions_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/admissions/data/repositories/admissions_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/hr/admissions/domain/entities/referral.dart';
import 'package:comprehensive_hr_and_ops/features/hr/admissions/domain/repositories/admissions_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/admissions/presentation/admissions_labels.dart';
import 'package:comprehensive_hr_and_ops/features/hr/admissions/presentation/controllers/admissions_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/admissions/presentation/pages/admissions_page.dart';
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
      designSize: const Size(
        ResponsiveHelper.baseWidth,
        ResponsiveHelper.baseHeight,
      ),
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
  tester.view.physicalSize = const Size(390, 3200);
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

Finder _key(String key) => find.byKey(ValueKey(key));

Finder _inKey(String key, Finder matching) =>
    find.descendant(of: _key(key), matching: matching);

Finder _input(String key) => _inKey(key, find.byType(TextField));

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(_input(key));
  await tester.enterText(_input(key), text);
  await tester.pump();
}

Future<void> _pick(WidgetTester tester, String key, String option) async {
  await _tap(tester, _key(key));
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, String key) {
  final inkWell = tester.widget<InkWell>(_inKey(key, find.byType(InkWell)).first);
  return inkWell.onTap != null;
}

class _Session extends UserSession {
  final Set<String>? only;
  final Set<String> denied;

  _Session({this.only, this.denied = const {}});

  @override
  bool can(String permission) =>
      (only == null || only!.contains(permission)) && !denied.contains(permission);
}

const _snapshot = TemplateSnapshot(
  name: 'Intake A',
  version: 1,
  fields: [
    IntakeField(key: 'diagnosis', label: 'Primary diagnosis', required: true),
    IntakeField(key: 'funding', label: 'Funding source'),
    IntakeField(key: 'consent_given', label: 'Consent given', type: 'checkbox'),
  ],
  checklist: [
    IntakeChecklistItem(key: 'consent', label: 'Consent form', required: true),
    IntakeChecklistItem(
      key: 'photo_id',
      label: 'Photo ID',
      required: true,
      requiresDocument: true,
    ),
    IntakeChecklistItem(key: 'gp_letter', label: 'GP letter', requiresDocument: true),
  ],
);

Referral _nabil({List<String> completed = const ['consent']}) => Referral(
      id: 'r1',
      firstName: 'Nabil',
      lastName: 'Rahim',
      status: 'waitlisted',
      dateOfBirth: DateTime.utc(2011, 9, 2),
      source: 'Regional agency',
      contactName: 'Case Worker',
      contactPhone: '+880-17-3333-3333',
      contactEmail: 'intake@agency.local',
      notes: 'Prefers a quiet room.',
      priority: 1,
      preferredResidenceId: 'elm',
      snapshot: _snapshot,
      payload: const {'diagnosis': 'ASD level 2', 'consent_given': true},
      completedChecklist: completed,
      waitlistedAt: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
      createdAt: DateTime(2026, 8, 27, 9, 33),
      assessments: [
        ReferralAssessment(
          id: 'a1',
          summary: 'Suitable for a group-home placement.',
          outcome: 'proceed',
          assessedAt: DateTime(2026, 8, 19, 9, 33),
        ),
      ],
      contacts: const [
        ReferralContact(
          id: 'c1',
          name: 'Rina Rahim',
          relationship: 'Mother',
          phone: '+880-17-1111-1111',
          isPrimaryGuardian: true,
          isEmergencyContact: true,
        ),
      ],
      documents: const [
        ReferralDocument(
          id: 'd1',
          name: 'gp.pdf',
          fileUrl: 'https://x/gp.pdf',
          checklistKey: 'gp_letter',
        ),
      ],
    );

final _puchan = Referral(
  id: 'r2',
  firstName: 'Puchan',
  lastName: 'Indha',
  status: 'admitted',
  priority: 100,
  preferredResidenceId: 'far',
  createdAt: DateTime(2026, 9, 3, 5, 35),
  events: [
    ReferralEvent(
      id: 'e1',
      event: 'admitted',
      fromStatus: 'new',
      toStatus: 'admitted',
      note: 'Admitted to Mala Box',
      actorName: 'Tenant Admin',
      createdAt: DateTime(2026, 9, 3, 5, 36),
    ),
  ],
);

const _templateA = IntakeTemplate(
  id: 't1',
  name: 'Intake A',
  provinceOrState: 'Ontario',
  version: 2,
  isActive: true,
  fields: [
    IntakeField(key: 'diagnosis', label: 'Primary diagnosis', required: true),
    IntakeField(
      key: 'funding',
      label: 'Funding',
      type: 'select',
      options: ['Ministry', 'Family'],
      target: 'funding_source',
    ),
    IntakeField(key: 'consent_given', label: 'Consent given', type: 'checkbox'),
  ],
  checklist: [
    IntakeChecklistItem(key: 'consent', label: 'Consent form', required: true),
    IntakeChecklistItem(key: 'photo_id', label: 'Photo ID', required: true),
    IntakeChecklistItem(key: 'gp_letter', label: 'GP letter'),
  ],
);

const _templateOld = IntakeTemplate(
  id: 't2',
  name: 'Old form',
  isActive: false,
  fields: [IntakeField(key: 'q', label: 'Q')],
);

class _FakeRepo implements AdmissionsRepository {
  List<Referral> rows = [_nabil(), _puchan];
  Map<String, Referral> details = {};
  List<IntakeTemplate> forms = [_templateA, _templateOld];
  bool failList = false;
  bool failTemplates = false;
  ReferralBoard boardData = const ReferralBoard(
    pending: 4,
    awaitingDocuments: 2,
    assessmentPending: 1,
    admittedLast30Days: 3,
  );
  List<AdmissionOption> homes = const [
    AdmissionOption(id: 'elm', label: 'Elm House'),
    AdmissionOption(id: 'oak', label: 'Oak Lodge'),
  ];
  Map<String, List<AdmissionRoom>> roomsByHome = const {
    'elm': [
      AdmissionRoom(id: 'room101', name: '101', roomType: 'single', available: 1),
      AdmissionRoom(id: 'room102', name: '102', roomType: 'double', available: 0),
      AdmissionRoom(id: 'room103', name: '103', isActive: false, available: 1),
    ],
    'oak': [],
  };

  final List<Map<String, Object?>> queries = [];
  final List<bool> templateQueries = [];
  final List<String> calls = [];
  Map<String, dynamic>? created;
  Map<String, dynamic>? updated;
  List<Map<String, dynamic>>? contacts;
  Map<String, dynamic>? templateBody;
  AppError? admitError;

  Future<Result<void>> _log(String call) async {
    calls.add(call);
    return Result.success(null);
  }

  @override
  Future<Result<ReferralBoard>> board() async => Result.success(boardData);

  @override
  Future<Result<ReferralPage>> referrals({
    required int page,
    required int limit,
    String? search,
    String? status,
  }) async {
    queries.add({'page': page, 'limit': limit, 'search': search, 'status': status});
    if (failList) return Result.failure(const ApiError(message: 'Server unavailable'));
    final items = rows.where((r) => status == null || r.status == status).toList();
    return Result.success(ReferralPage(items: items, total: items.length, totalPages: 1));
  }

  @override
  Future<Result<Referral>> referral(String id) async =>
      Result.success(details[id] ?? rows.firstWhere((r) => r.id == id));

  @override
  Future<Result<void>> createReferral(Map<String, dynamic> body) async {
    created = body;
    return _log('create');
  }

  @override
  Future<Result<void>> updateReferral(String id, Map<String, dynamic> body) async {
    updated = body;
    return _log('update $id $body');
  }

  @override
  Future<Result<void>> setContacts(String id, List<Map<String, dynamic>> list) async {
    contacts = list;
    return _log('contacts $id');
  }

  @override
  Future<Result<void>> setChecklist(String id, List<String> completed) =>
      _log('checklist $id ${[...completed]..sort()}');

  @override
  Future<Result<void>> addAssessment(String id, {required String summary, String? outcome}) =>
      _log('assessment $id $summary / $outcome');

  @override
  Future<Result<void>> admit(
    String id, {
    required String residenceId,
    String? roomId,
    String? level,
  }) async {
    if (admitError != null) return Result.failure(admitError!);
    return _log('admit $id $residenceId $roomId $level');
  }

  @override
  Future<Result<void>> decline(String id, String reason) => _log('decline $id $reason');

  @override
  Future<Result<void>> deleteReferral(String id) => _log('delete $id');

  @override
  Future<Result<List<IntakeTemplate>>> templates({bool activeOnly = false}) async {
    templateQueries.add(activeOnly);
    if (failTemplates) return Result.failure(const ApiError(message: 'Forms offline'));
    return Result.success(
      activeOnly ? forms.where((t) => !t.isRetired).toList() : forms,
    );
  }

  @override
  Future<Result<void>> createTemplate(Map<String, dynamic> body) async {
    templateBody = body;
    return _log('create template');
  }

  @override
  Future<Result<void>> updateTemplate(String id, Map<String, dynamic> body) async {
    templateBody = body;
    return _log('template $id ${body.length == 1 ? body : 'form'}');
  }

  @override
  Future<Result<List<AdmissionOption>>> residences() async => Result.success(homes);

  @override
  Future<Result<List<AdmissionRoom>>> rooms(String residenceId) async =>
      Result.success(roomsByHome[residenceId] ?? const []);
}

Future<_FakeRepo> _open(
  WidgetTester tester, {
  _FakeRepo? repo,
  Set<String>? only,
  Set<String> denied = const {},
}) async {
  _tallView(tester);
  final fake = repo ?? _FakeRepo();
  final session = Get.put<UserSession>(_Session(only: only, denied: denied));
  GetIt.I.registerFactory<AdmissionsController>(
    () => AdmissionsController(repository: fake, session: session),
  );
  await tester.pumpWidget(_app(const AdmissionsPage()));
  await tester.pumpAndSettle();
  return fake;
}

class _FakeApi implements AppApiClient {
  final List<String> requests = [];
  final List<Object?> bodies = [];
  dynamic response = const {'data': []};

  Future<Result<dynamic>> _record(String line, Object? body) async {
    requests.add(line);
    bodies.add(body);
    return Result.success(response);
  }

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) =>
      _record('GET $path ${query ?? {}}', null);

  @override
  Future<Result<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) =>
      _record('POST $path', data);

  @override
  Future<Result<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) =>
      _record('PUT $path', data);

  @override
  Future<Result<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) =>
      _record('PATCH $path', data);

  @override
  Future<Result<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) =>
      _record('DELETE $path', data);

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
    test('mapper reads the live referral, board, template and room payloads', () {
      final page = AdmissionsMapper.pageFrom({
        'data': [
          {
            'id': '38da',
            'firstName': 'Nabil',
            'lastName': 'Rahim',
            'dateOfBirth': '2011-09-02T00:00:00.000Z',
            'source': 'Regional agency',
            'status': 'waitlisted',
            'admissionType': null,
            'templateSnapshotJson': {
              'fields': [
                {'key': 'diagnosis', 'type': 'text', 'label': 'Primary diagnosis', 'required': true},
              ],
              'version': 1,
            },
            'payloadJson': {'diagnosis': 'ASD level 2'},
            'checklistJson': {'consent': true, 'photo_id': false},
            'priority': 1,
            'waitlistedAt': '2026-08-17T09:33:06.745Z',
            'preferredResidenceId': '7f49',
            'createdAt': '2026-08-27T09:33:09.097Z',
          },
        ],
        'meta': {'page': 1, 'limit': 3, 'total': 7, 'totalPages': 3},
      });
      expect((page.total, page.totalPages), (7, 3));
      final r = page.items.single;
      expect(r.fullName, 'Nabil Rahim');
      expect(r.snapshot!.fields.single.required, isTrue);
      expect(r.snapshot!.checklist, isEmpty);
      expect(r.completedChecklist, isEmpty, reason: 'legacy checklist shape is ignored');
      expect(r.payload['diagnosis'], 'ASD level 2');
      expect(r.isClosed, isFalse);

      final detail = AdmissionsMapper.referralFrom({
        'id': '364d',
        'firstName': 'Puchan',
        'lastName': 'Indha',
        'status': 'admitted',
        'templateSnapshotJson': {
          'name': 'intake 2',
          'version': 1,
          'fields': [],
          'checklist': [
            {'key': 'padu', 'label': 'padu', 'required': true, 'requiresDocument': false},
          ],
        },
        'checklistJson': {'completed': ['padu']},
        'assessments': [
          {'id': 'a', 'summary': 'Suitable', 'outcome': 'proceed', 'assessedAt': '2026-08-19T09:33:06.745Z'},
        ],
        'contacts': [
          {'id': 'c', 'name': 'Rina', 'isPrimaryGuardian': true},
        ],
        'events': [
          {
            'id': 'e',
            'event': 'created',
            'fromStatus': null,
            'toStatus': 'new',
            'note': 'Referred by Ibna sina',
            'createdAt': '2026-09-03T05:35:35.454Z',
            'actor': {'id': 'u', 'name': 'Tenant Admin'},
          },
        ],
        'documents': [
          {'id': 'd', 'name': 'id.pdf', 'fileUrl': 'https://x/id.pdf', 'checklistKey': 'padu'},
        ],
      })!;
      expect(detail.isClosed, isTrue);
      expect(detail.outstanding, isEmpty);
      expect(detail.assessments.single.outcome, 'proceed');
      expect(detail.contacts.single.isPrimaryGuardian, isTrue);
      expect(detail.events.single.actorName, 'Tenant Admin');
      expect(detail.documentFor('padu')!.name, 'id.pdf');

      final board = AdmissionsMapper.boardFrom({
        'success': true,
        'data': {'pending': 1, 'awaitingDocuments': 0, 'assessmentPending': 2, 'admittedLast30Days': 5},
      });
      expect(
        (board.pending, board.awaitingDocuments, board.assessmentPending, board.admittedLast30Days),
        (1, 0, 2, 5),
      );

      final templates = AdmissionsMapper.templatesFrom({
        'data': [
          {
            'id': 'c48e',
            'name': 'addtional information',
            'provinceOrState': 'Dhaka',
            'fieldsJson': [
              {'key': 'hagu', 'type': 'textarea', 'label': 'hagu', 'target': 'medical', 'required': false},
            ],
            'checklistJson': [
              {'key': 'padu', 'label': 'padu', 'required': true, 'requiresDocument': false},
            ],
            'isActive': true,
            'version': 2,
          },
        ],
      });
      expect(templates.single.fields.single.target, 'medical');
      expect(templates.single.requiredChecklistCount, 1);

      final rooms = AdmissionsMapper.roomsFrom({
        'data': [
          {'id': 'x', 'name': '101', 'roomType': 'single', 'isActive': true, 'available': 1},
        ],
        'meta': {'summary': {}},
      });
      expect((rooms.single.name, rooms.single.available, rooms.single.isActive), ('101', 1, true));
    });

    test('repository calls the verified endpoints with the web bodies', () async {
      final api = _FakeApi();
      final repo = AdmissionsRepositoryImpl(api: api);
      await repo.board();
      await repo.referrals(page: 2, limit: 20, search: 'nab', status: 'waitlisted');
      await repo.referrals(page: 1, limit: 20);
      await repo.templates();
      await repo.templates(activeOnly: true);
      await repo.residences();
      await repo.rooms('elm');
      await repo.createReferral({'firstName': 'A', 'lastName': 'B', 'priority': 0});
      await repo.updateReferral('r1', {'status': 'screening'});
      await repo.setContacts('r1', [{'name': 'Rina'}]);
      await repo.setChecklist('r1', ['consent']);
      await repo.addAssessment('r1', summary: 'Fine');
      await repo.admit('r1', residenceId: 'elm', level: 'High');
      await repo.decline('r1', 'No bed');
      await repo.deleteReferral('r1');
      await repo.createTemplate({'name': 'F', 'fields': []});
      await repo.updateTemplate('t1', {'isActive': false});

      expect(api.requests, [
        'GET /referrals/board {}',
        'GET /referrals {page: 2, limit: 20, search: nab, status: waitlisted}',
        'GET /referrals {page: 1, limit: 20}',
        'GET /intake-templates {activeOnly: false}',
        'GET /intake-templates {activeOnly: true}',
        'GET /residences {page: 1, limit: 100}',
        'GET /residences/elm/rooms {}',
        'POST /referrals',
        'PATCH /referrals/r1',
        'PUT /referrals/r1/contacts',
        'PUT /referrals/r1/checklist',
        'POST /referrals/r1/assessments',
        'POST /referrals/r1/admit',
        'POST /referrals/r1/decline',
        'DELETE /referrals/r1',
        'POST /intake-templates',
        'PATCH /intake-templates/t1',
      ]);
      expect(api.bodies.sublist(9), [
        {'contacts': [{'name': 'Rina'}]},
        {'completed': ['consent']},
        {'summary': 'Fine'},
        {'residenceId': 'elm', 'level': 'High'},
        {'reason': 'No bed'},
        null,
        {'name': 'F', 'fields': []},
        {'isActive': false},
      ]);
    });

    test('labels: waiting days, slug keys and the plan-limit message', () {
      final now = DateTime(2026, 10, 1, 12);
      expect(AdmissionsLabels.waiting(null), '—');
      expect(AdmissionsLabels.waiting(DateTime(2026, 10, 1, 2), now: now), 'Today');
      expect(AdmissionsLabels.waiting(DateTime(2026, 9, 28, 11), now: now), '3d');
      expect(AdmissionsLabels.slug('  Primary diagnosis (ICD)! '), 'primary_diagnosis_icd');
      expect(
        AdmissionsLabels.error(const ApiError(
          message: 'Plan limit',
          statusCode: 402,
          responseData: {
            'error': {
              'code': 'PLAN_LIMIT_EXCEEDED',
              'details': {'limit': 10, 'current': 10},
            },
          },
        )),
        'This plan allows 10 residents and 10 are already active. '
        'Admitting needs a place freed or the plan upgraded.',
      );
    });
  });

  group('referrals board', () {
    testWidgets('opens with the web KPIs, tabs, row cells, pills and write actions',
        (tester) async {
      final repo = await _open(tester);

      expect(find.text('Admissions'), findsOneWidget);
      expect(repo.queries.first, {'page': 1, 'limit': 20, 'search': null, 'status': null});
      expect(_key('referral-new'), findsOneWidget);
      expect(find.text('Search referrals…'), findsOneWidget);
      expect(_inKey('admissions-stage-filter', find.text('Any stage')), findsOneWidget);

      for (final (key, value, label, caption) in [
        ('pending', '4', 'IN THE PIPELINE', 'Referrals still moving forward'),
        ('documents', '2', 'CANNOT BE ADMITTED', 'Something required is missing or unsigned'),
        ('assessment', '1', 'NOT YET ASSESSED', 'Nobody has written an assessment'),
        ('admitted', '3', 'ADMITTED', 'In the last 30 days'),
      ]) {
        final tile = 'admissions-kpi-$key';
        expect(_inKey(tile, find.text(value)), findsOneWidget, reason: key);
        expect(_inKey(tile, find.text(label)), findsOneWidget, reason: key);
        expect(_inKey(tile, find.text(caption)), findsOneWidget, reason: key);
      }
      expect(find.text('Referrals'), findsOneWidget);
      expect(find.text('Intake forms'), findsOneWidget);

      for (final text in ['Nabil Rahim', 'via Regional agency', 'Waitlisted', 'PREFERRED',
          'Elm House', 'WAITING', '3d', 'PRIORITY', '1', 'RECEIVED', '27/08/2026', 'Admit',
          'Decline']) {
        expect(_inKey('referral-r1', find.text(text)), findsOneWidget, reason: text);
      }
      for (final text in ['Puchan Indha', 'No source recorded', 'Admitted', 'Outside your access',
          '—', '100', '03/09/2026']) {
        expect(_inKey('referral-r2', find.text(text)), findsOneWidget, reason: text);
      }
      for (final action in ['edit', 'admit', 'decline', 'delete']) {
        expect(_key('referral-$action-r1'), findsOneWidget, reason: action);
      }
      expect(_key('referral-edit-r2'), findsNothing);
      expect(_key('referral-admit-r2'), findsNothing);
      expect(_key('referral-decline-r2'), findsNothing);
      expect(_key('referral-delete-r2'), findsOneWidget);
      expect(find.text('Showing 1 to 2 of 2 entries'), findsOneWidget);
    });

    testWidgets('admissions:read only (residence manager) hides every write action',
        (tester) async {
      await _open(tester, only: {'admissions:read', 'residences:read'});
      expect(_key('referral-new'), findsNothing);
      for (final action in ['edit', 'admit', 'decline', 'delete']) {
        expect(_key('referral-$action-r1'), findsNothing, reason: action);
      }
      await _tap(tester, _key('referral-open-r1'));
      expect(find.text('FAMILY AND GUARDIANS'), findsOneWidget);
      expect(find.text('Rina Rahim'), findsOneWidget);
      expect(find.text('Decides'), findsOneWidget);
      expect(find.text('Called first'), findsOneWidget);
      expect(_key('contacts-save'), findsNothing);
      expect(_key('assessment-record'), findsNothing);
      expect(find.text('MOVE IT ON'), findsNothing);
      final checkbox = tester.widget<Checkbox>(_inKey('checklist-photo_id', find.byType(Checkbox)));
      expect(checkbox.onChanged, isNull);

      await _tap(tester, _key('referral-detail-close'));
      await _tap(tester, _key('admissions-tab-forms'));
      expect(_key('template-new'), findsNothing);
      expect(_key('template-edit-t1'), findsNothing);
      expect(_key('template-toggle-t1'), findsNothing);
    });

    testWidgets('stage filter and debounced search drive the list query', (tester) async {
      final repo = await _open(tester);
      await _pick(tester, 'admissions-stage-filter', 'Screening');
      expect(repo.queries.last, {'page': 1, 'limit': 20, 'search': null, 'status': 'screening'});
      expect(find.text('No referrals'), findsOneWidget);
      expect(
        find.text('Someone enquiring about a place starts here and ends as a resident record.'),
        findsOneWidget,
      );

      await _pick(tester, 'admissions-stage-filter', 'Any stage');
      await tester.enterText(find.byKey(const ValueKey('admissions-search')), 'nab');
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.queries.last['search'], isNull);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(repo.queries.last, {'page': 1, 'limit': 20, 'search': 'nab', 'status': null});
    });

    testWidgets('a failed list shows the web error state', (tester) async {
      final repo = _FakeRepo()..failList = true;
      await _open(tester, repo: repo);
      expect(find.text('Referrals could not be loaded'), findsOneWidget);
      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.textContaining('Showing'), findsNothing);
    });

    testWidgets('Delete asks first, then soft-deletes', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('referral-delete-r1'));
      expect(find.text('Delete this referral?'), findsOneWidget);
      expect(
        find.text('Nabil Rahim leaves the pipeline. The referral and its history are kept '
            'rather than destroyed, so it can be restored.'),
        findsOneWidget,
      );
      await _tap(tester, _key('referral-delete-confirm'));
      expect(repo.calls, ['delete r1']);
      expect(find.text('Referral deleted'), findsOneWidget);
    });
  });

  group('referral detail', () {
    testWidgets('shows contact, intake snapshot, checklist, assessments and edits them',
        (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('referral-open-r1'));

      for (final text in ['Waitlisted · referred by Regional agency', 'CONTACT', 'Date of birth',
          '02/09/2011', 'Contact', 'Case Worker', 'Phone', '+880-17-3333-3333', 'Email',
          'intake@agency.local', 'Preferred residence', 'Waiting since', 'Prefers a quiet room.',
          'INTAKE — INTAKE A V1',
          'The form as it stood when this referral was taken. Editing the template later does '
              'not change what was answered here.',
          'Primary diagnosis', 'ASD level 2', 'Funding source', 'Consent given', 'Yes',
          'INTAKE CHECKLIST', 'Admission is blocked until these are done: Photo ID',
          'Consent form', 'Photo ID', 'GP letter', 'Needs a file', 'gp.pdf',
          'FAMILY AND GUARDIANS', 'ASSESSMENTS', '19/08/2026', 'Proceed',
          'Suitable for a group-home placement.', 'New assessment', 'Outcome', 'MOVE IT ON',
          'Stage',
          'Waitlisting starts the clock that orders the queue; leaving the waitlist clears it']) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('HISTORY'), findsNothing);

      await _tap(tester, _inKey('checklist-photo_id', find.byType(Checkbox)));
      expect(repo.calls.last, 'checklist r1 [consent, photo_id]');

      await _enter(tester, 'assessment-summary', 'Needs a quiet room');
      await _enter(tester, 'assessment-outcome', 'suitable');
      await _tap(tester, _key('assessment-record'));
      expect(repo.calls.last, 'assessment r1 Needs a quiet room / suitable');
      expect(find.text('Assessment recorded'), findsOneWidget);

      await _tap(tester, _key('referral-stage'));
      for (final stage in ['New', 'Screening', 'Assessment']) {
        expect(find.text(stage), findsWidgets, reason: stage);
      }
      expect(find.text('Declined'), findsNothing);
      await tester.tap(find.text('Assessment').last);
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'update r1 {status: assessment}');
      expect(find.text('Stage updated'), findsOneWidget);
    });

    testWidgets('family and guardians: add, validate, remove and save the whole list',
        (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('referral-open-r1'));
      expect(tester.widget<TextField>(_input('contact-name-0')).controller!.text, 'Rina Rahim');

      await _tap(tester, _key('contacts-add'));
      await _tap(tester, _key('contacts-save'));
      expect(find.text('Every contact needs a name.'), findsOneWidget);
      expect(repo.contacts, isNull);

      await _enter(tester, 'contact-name-1', 'Omar Rahim');
      await _enter(tester, 'contact-relationship-1', 'Uncle');
      await _tap(tester, _key('contact-emergency-1'));
      await _tap(tester, _key('contact-guardian-1'));
      await _tap(tester, _key('contacts-save'));
      expect(repo.contacts, [
        {
          'id': 'c1',
          'name': 'Rina Rahim',
          'relationship': 'Mother',
          'phone': '+880-17-1111-1111',
          'isPrimaryGuardian': true,
          'isEmergencyContact': true,
        },
        {
          'name': 'Omar Rahim',
          'relationship': 'Uncle',
          'isPrimaryGuardian': true,
          'isEmergencyContact': false,
        },
      ]);
      expect(find.text('Contacts saved'), findsOneWidget);

      await _tap(tester, _key('contact-remove-0'));
      await _tap(tester, _key('contacts-save'));
      expect(repo.contacts, [
        {
          'name': 'Omar Rahim',
          'relationship': 'Uncle',
          'isPrimaryGuardian': true,
          'isEmergencyContact': false,
        },
      ]);
    });

    testWidgets('a closed referral is read-only with its history', (tester) async {
      await _open(tester);
      await _tap(tester, _key('referral-open-r2'));
      expect(find.text('This referral is admitted and can no longer be changed.'), findsOneWidget);
      expect(find.text('None collected yet.'), findsOneWidget);
      expect(find.text('None recorded.'), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);
      expect(find.text('New → Admitted'), findsOneWidget);
      expect(find.textContaining('Tenant Admin · 03/09/2026'), findsOneWidget);
      expect(find.text('Admitted to Mala Box'), findsOneWidget);
      expect(find.text('Not stated'), findsOneWidget);
      expect(find.text('MOVE IT ON'), findsNothing);
      expect(_key('assessment-record'), findsNothing);
    });
  });

  group('referral form', () {
    testWidgets('New referral validates like the web and records the intake answers',
        (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('referral-new'));
      expect(find.text('New referral'), findsNWidgets(2));
      expect(
        find.text('Enough to hold someone\'s place in the queue — the intake form can be filled in later.'),
        findsOneWidget,
      );
      expect(repo.templateQueries, [true]);
      for (final text in ['Date of birth', 'Referred by', 'On what basis', 'Not decided yet',
          'Expected admission date', 'When they are expected, not when the referral arrived',
          'Reason for admission', 'Contact name', 'Contact phone', 'Contact email',
          'Preferred residence', 'No preference',
          'Waitlisting against a residence with a free bed alerts the intake team',
          'Priority', '0–100. Higher sits nearer the top of the waitlist.', 'Notes',
          'Intake form', 'None',
          'Only forms currently in use are offered — a retired one is refused']) {
        expect(find.text(text, findRichText: true), findsWidgets, reason: text);
      }

      await _tap(tester, _key('referral-form-save'));
      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Last name is required'), findsOneWidget);

      await _enter(tester, 'referral-first-name', 'Amina');
      await _enter(tester, 'referral-last-name', 'K4n');
      await _enter(tester, 'referral-contact-phone', 'abc');
      await _enter(tester, 'referral-contact-email', 'not-an-email');
      await _tap(tester, _key('referral-form-save'));
      expect(find.text('Last name can only contain letters'), findsOneWidget);
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(repo.created, isNull);

      await _enter(tester, 'referral-last-name', 'Khan');
      await _enter(tester, 'referral-contact-phone', '+880 1711 000000');
      await _enter(tester, 'referral-contact-email', 'family@example.com');
      await _enter(tester, 'referral-source', 'Dhaka Medical');
      await _pick(tester, 'referral-admission-type', 'Respite care');
      await _pick(tester, 'referral-preferred', 'Oak Lodge');
      await _enter(tester, 'referral-priority', '40');

      await _tap(tester, _key('referral-template'));
      expect(find.text('Old form'), findsNothing);
      await tester.tap(find.text('Intake A').last);
      await tester.pumpAndSettle();
      expect(find.text('Primary diagnosis *', findRichText: true), findsOneWidget);
      await _enter(tester, 'intake-field-diagnosis', 'Dementia');
      await _tap(tester, _key('intake-field-funding'));
      expect(find.text('The API rejects anything outside this list'), findsOneWidget);
      await tester.tap(find.text('Ministry').last);
      await tester.pumpAndSettle();
      await _tap(tester, _inKey('intake-field-consent_given', find.byType(Checkbox)));

      await _tap(tester, _key('referral-form-save'));
      expect(repo.created, {
        'firstName': 'Amina',
        'lastName': 'Khan',
        'source': 'Dhaka Medical',
        'admissionType': 'respite',
        'contactPhone': '+880 1711 000000',
        'contactEmail': 'family@example.com',
        'preferredResidenceId': 'oak',
        'priority': 40,
        'intakeTemplateId': 't1',
        'payload': {'diagnosis': 'Dementia', 'funding': 'Ministry', 'consent_given': true},
      });
      expect(_key('referral-form-save'), findsNothing);
      expect(find.text('Referral recorded'), findsOneWidget);
    });

    testWidgets('Edit referral is prefilled, has no intake form and patches details',
        (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('referral-edit-r1'));
      expect(find.text('Edit referral'), findsOneWidget);
      expect(
        find.text('Corrects what was recorded — the stage and intake answers are changed elsewhere.'),
        findsOneWidget,
      );
      expect(_key('referral-template'), findsNothing);
      expect(_inKey('referral-dob', find.text('02/09/2011')), findsOneWidget);
      expect(_inKey('referral-preferred', find.text('Elm House')), findsOneWidget);

      await _enter(tester, 'referral-notes', '');
      await _enter(tester, 'referral-source', 'Hospital');
      await _tap(tester, _key('referral-form-save'));
      expect(repo.updated, {
        'firstName': 'Nabil',
        'lastName': 'Rahim',
        'dateOfBirth': '2011-09-02',
        'source': 'Hospital',
        'contactName': 'Case Worker',
        'contactPhone': '+880-17-3333-3333',
        'contactEmail': 'intake@agency.local',
        'preferredResidenceId': 'elm',
        'priority': 1,
      });
      expect(find.text('Referral updated'), findsOneWidget);
    });
  });

  group('admit and decline', () {
    testWidgets('Admit is blocked while a required checklist item is open', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('referral-admit-r1'));
      expect(find.text('Admit Nabil Rahim'), findsOneWidget);
      expect(
        find.text("Creates the resident record and closes the referral. Needs every required "
            "checklist item ticked, and counts against the plan's resident limit."),
        findsOneWidget,
      );
      expect(find.text('Admission is blocked until these are done: Photo ID'), findsOneWidget);
      await _pick(tester, 'admit-residence', 'Elm House');
      expect(_enabled(tester, 'admit-submit'), isFalse);
      expect(repo.calls, isEmpty);
    });

    testWidgets('Admit picks a residence, a room with a spare bed and a care level',
        (tester) async {
      final repo = _FakeRepo()
        ..details = {'r1': _nabil(completed: ['consent', 'photo_id'])};
      await _open(tester, repo: repo);
      await _tap(tester, _key('referral-admit-r1'));
      expect(find.text('Admission is blocked until these are done: Photo ID'), findsNothing);
      expect(_inKey('admit-room', find.text('Pick a residence first')), findsOneWidget);
      expect(find.text('A room belongs to one home — pick the home first'), findsOneWidget);
      expect(_enabled(tester, 'admit-submit'), isFalse);

      await _pick(tester, 'admit-residence', 'Oak Lodge');
      expect(
        find.text('This home has no rooms recorded yet — add them on the residence'),
        findsOneWidget,
      );

      await _pick(tester, 'admit-residence', 'Elm House');
      expect(find.text('Only rooms with a bed going spare are listed'), findsOneWidget);
      expect(_inKey('admit-room', find.text('No room yet')), findsOneWidget);
      await _tap(tester, _key('admit-room'));
      expect(find.text('101 — 1 free (single)'), findsOneWidget);
      expect(find.textContaining('102'), findsNothing);
      expect(find.textContaining('103'), findsNothing);
      await tester.tap(find.text('101 — 1 free (single)'));
      await tester.pumpAndSettle();
      await _enter(tester, 'admit-level', 'High support');
      await _tap(tester, _key('admit-submit'));
      expect(repo.calls, ['admit r1 elm room101 High support']);
      expect(find.text('Admit Nabil Rahim'), findsNothing);
      expect(find.text('Admitted — the resident record has been created'), findsOneWidget);
    });

    testWidgets('Admit shows the plan limit inline', (tester) async {
      final repo = _FakeRepo()
        ..details = {'r1': _nabil(completed: ['consent', 'photo_id'])}
        ..admitError = const ApiError(
          message: 'Plan limit',
          statusCode: 402,
          responseData: {
            'code': 'PLAN_LIMIT_EXCEEDED',
            'details': {'limit': 5, 'current': 5},
          },
        );
      await _open(tester, repo: repo);
      await _tap(tester, _key('referral-admit-r1'));
      await _pick(tester, 'admit-residence', 'Elm House');
      await _tap(tester, _key('admit-submit'));
      expect(
        find.text('This plan allows 5 residents and 5 are already active. Admitting needs a '
            'place freed or the plan upgraded.'),
        findsOneWidget,
      );
      expect(find.text('Admit Nabil Rahim'), findsOneWidget);
    });

    testWidgets('without clients:create / clients:write Admit stays disabled', (tester) async {
      final repo = _FakeRepo()
        ..details = {'r1': _nabil(completed: ['consent', 'photo_id'])};
      await _open(tester, repo: repo, denied: {'clients:write', 'clients:create'});
      await _tap(tester, _key('referral-admit-r1'));
      await _pick(tester, 'admit-residence', 'Elm House');
      expect(_enabled(tester, 'admit-submit'), isFalse);
    });

    testWidgets('Decline needs a reason', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('referral-decline-r1'));
      expect(find.text('Decline Nabil Rahim'), findsOneWidget);
      expect(
        find.text('Closes the referral. The API will not close one without a reason recorded.'),
        findsOneWidget,
      );
      expect(
        find.text('Recorded on the referral — the API will not close one without it'),
        findsOneWidget,
      );
      expect(_enabled(tester, 'decline-submit'), isFalse);
      await _enter(tester, 'decline-reason', 'No bed for six months');
      await _tap(tester, _key('decline-submit'));
      expect(repo.calls, ['decline r1 No bed for six months']);
      expect(find.text('Referral declined'), findsOneWidget);
    });
  });

  group('intake forms', () {
    testWidgets('lists forms with status, counts, retire (after confirm) and reinstate',
        (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('admissions-tab-forms'));
      expect(repo.templateQueries, [false]);
      expect(_key('referral-new'), findsNothing);
      expect(find.text('Search referrals…'), findsNothing);

      for (final text in ['Intake A', 'Ontario · v2', 'In use', 'QUESTIONS', '3', 'CHECKLIST',
          '3 · 2 required', 'Retire']) {
        expect(_inKey('template-t1', find.text(text)), findsOneWidget, reason: text);
      }
      for (final text in ['Old form', 'No region · v1', 'Retired', '1', '0', 'Reinstate']) {
        expect(_inKey('template-t2', find.text(text)), findsOneWidget, reason: text);
      }

      await _tap(tester, _key('template-toggle-t1'));
      expect(find.text('Retire this intake form?'), findsOneWidget);
      expect(
        find.text('"Intake A" stops being offered on new referrals. Existing referrals keep '
            'the answers they already gave — retiring does not touch them.'),
        findsOneWidget,
      );
      await _tap(tester, _key('template-retire-confirm'));
      expect(repo.calls, ['template t1 {isActive: false}']);
      expect(find.text('Form retired'), findsOneWidget);

      await _tap(tester, _key('template-toggle-t2'));
      expect(repo.calls.last, 'template t2 {isActive: true}');
      expect(find.text('Form back in use'), findsOneWidget);
    });

    testWidgets('New intake form validates and builds the web body', (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('admissions-tab-forms'));
      await _tap(tester, _key('template-new'));
      expect(find.text('New intake form'), findsWidgets);
      expect(
        find.text('Questions are stored as data, so this form can change without a release.'),
        findsOneWidget,
      );
      expect(find.text('Question 1'), findsOneWidget);

      await _tap(tester, _key('template-form-save'));
      expect(find.text('Give the form a name.'), findsOneWidget);
      await _enter(tester, 'template-name', 'Adult intake');
      await _tap(tester, _key('template-form-save'));
      expect(find.text('A form needs at least one question.'), findsOneWidget);

      await _enter(tester, 'question-label-0', 'Primary diagnosis');
      await _tap(tester, _key('question-add'));
      await _enter(tester, 'question-label-1', 'Primary  diagnosis');
      await _tap(tester, _key('template-form-save'));
      expect(find.text('Two questions share a key — rename one.'), findsOneWidget);

      await _enter(tester, 'question-label-1', 'Funding');
      await _pick(tester, 'question-type-1', 'Choice');
      await _tap(tester, _key('template-form-save'));
      expect(find.text('"Funding" is a choice question with no options.'), findsOneWidget);

      await _enter(tester, 'question-options-1', 'Ministry, Family, ');
      await _pick(tester, 'question-target-1', 'Funding source');
      await _tap(tester, _key('question-required-0'));
      await _tap(tester, _key('item-add'));
      await _enter(tester, 'item-label-0', 'Consent signed');
      await _tap(tester, _key('item-document-0'));
      await _tap(tester, _key('item-add'));
      await _enter(tester, 'item-label-1', 'Scratch');
      await _tap(tester, _key('item-remove-1'));
      await _enter(tester, 'template-region', 'Dhaka');
      await _tap(tester, _key('template-form-save'));

      expect(repo.templateBody, {
        'name': 'Adult intake',
        'provinceOrState': 'Dhaka',
        'fields': [
          {'key': 'primary_diagnosis', 'label': 'Primary diagnosis', 'type': 'text', 'required': true},
          {
            'key': 'funding',
            'label': 'Funding',
            'type': 'select',
            'required': false,
            'target': 'funding_source',
            'options': ['Ministry', 'Family'],
          },
        ],
        'checklist': [
          {'key': 'consent_signed', 'label': 'Consent signed', 'required': true, 'requiresDocument': true},
        ],
      });
      expect(find.text('Intake form created'), findsOneWidget);
    });

    testWidgets('Edit intake form keeps existing keys and patches the whole form',
        (tester) async {
      final repo = await _open(tester);
      await _tap(tester, _key('admissions-tab-forms'));
      await _tap(tester, _key('template-edit-t1'));
      expect(find.text('Edit intake form'), findsOneWidget);
      expect(tester.widget<TextField>(_input('template-name')).controller!.text, 'Intake A');
      expect(_inKey('question-target-1', find.text('Funding source')), findsOneWidget);
      expect(tester.widget<TextField>(_input('question-options-1')).controller!.text,
          'Ministry, Family');

      await _enter(tester, 'question-label-0', 'Main diagnosis');
      await _tap(tester, _key('template-form-save'));
      expect(repo.calls, ['template t1 form']);
      final body = repo.templateBody!;
      expect((body['fields'] as List).first,
          {'key': 'diagnosis', 'label': 'Main diagnosis', 'type': 'text', 'required': true});
      expect((body['checklist'] as List).map((c) => (c as Map)['key']),
          ['consent', 'photo_id', 'gp_letter']);
      expect(find.text('Intake form updated'), findsOneWidget);
    });

    testWidgets('empty and failed form lists use the web copy', (tester) async {
      final repo = _FakeRepo()..forms = [];
      await _open(tester, repo: repo);
      await _tap(tester, _key('admissions-tab-forms'));
      expect(find.text('No intake forms'), findsOneWidget);
      expect(
        find.text('A referral can be taken without one — a form adds the questions and the '
            'checklist that gate admission.'),
        findsOneWidget,
      );
      repo.failTemplates = true;
      await Get.find<AdmissionsController>().loadTemplates();
      await tester.pumpAndSettle();
      expect(find.text('Forms could not be loaded'), findsOneWidget);
      expect(find.text('Forms offline'), findsOneWidget);
    });
  });
}
