import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/data/mappers/clients_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/data/repositories/clients_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/entities/client_extras.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/entities/client_summary.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/repositories/clients_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/controllers/clients_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/pages/clients_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/presentation/widgets/handover_common.dart';
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

Future<void> _type(WidgetTester tester, String key, String text) async {
  final field = _inKey(key, find.byType(TextField));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

Future<void> _pickFirstOfMonth(WidgetTester tester, String key) async {
  await _tap(tester, find.byKey(ValueKey(key)));
  await tester.tap(
    find.descendant(of: find.byType(DatePickerDialog), matching: find.text('1')).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, String key) =>
    tester.widget<HandoverButton>(find.byKey(ValueKey(key))).onPressed != null;

class _Session extends UserSession {
  final Set<String> denied;

  _Session({this.denied = const {}});

  @override
  bool can(String permission) => !denied.contains(permission);
}

const _ada = ClientSummary(
  id: 'c1aaaaaa-1111-2222-3333-444444444444',
  firstName: 'Ada',
  lastName: 'Lovelace',
  status: 'Active',
  residenceId: 'elm',
  residenceName: 'Elm House',
  room: 'Room 4',
  roomId: 'r1',
  roomNumber: '4',
  careLevel: 'Medium',
  allergies: ['Peanuts'],
);

const _ben = ClientSummary(
  id: 'c2bbbbbb-1111-2222-3333-444444444444',
  firstName: 'Ben',
  lastName: 'Okafor',
  status: 'pending',
  residenceId: 'oak',
  residenceName: 'Oak Lodge',
);

class _FakeRepo implements ClientsRepository {
  List<ClientSummary> rows = [_ada, _ben];
  int? limit;
  final calls = <String>[];
  final created = <Map<String, dynamic>>[];
  final updated = <Map<String, dynamic>>[];
  final familyAdded = <Map<String, dynamic>>[];
  final deleted = <String>[];
  final transfers = <Map<String, dynamic>>[];
  final lastSearch = <String?>[];
  int exportCalls = 0;
  bool transferAtCapacityOnce = false;
  List<ClientFamilyMember> family = const [
    ClientFamilyMember(
      id: 'f1',
      name: 'Mary Benson',
      userId: 'u9',
      relationship: 'Daughter',
      phone: '+1 555 0100',
      isPrimaryGuardian: true,
      receiveNotifications: true,
      emergencyAlerts: true,
    ),
  ];

  @override
  Future<Result<ClientPage>> getClients({
    required int page,
    required int limit,
    String? search,
    String? residenceId,
  }) async {
    calls.add('list');
    lastSearch.add(search);
    final q = (search ?? '').toLowerCase();
    final items = rows
        .where((c) => q.isEmpty || c.fullName.toLowerCase().contains(q))
        .where((c) => residenceId == null || c.residenceId == residenceId)
        .toList();
    return Result.success(ClientPage(items: items, total: items.length, totalPages: 1));
  }

  @override
  Future<Result<ClientSummary>> getClient(String clientId) async =>
      Result.success(rows.firstWhere((c) => c.id == clientId));

  @override
  Future<Result<Map<String, String>>> getResidenceNames() async =>
      Result.success({'elm': 'Elm House', 'oak': 'Oak Lodge'});

  @override
  Future<Result<int?>> getClientLimit() async => Result.success(limit);

  @override
  Future<Result<ClientSummary>> createClient(Map<String, dynamic> body) async {
    created.add(body);
    return Result.success(
      ClientSummary(id: 'new1', firstName: '${body['firstName']}', lastName: '', status: 'Active'),
    );
  }

  @override
  Future<Result<ClientSummary>> updateClient(String clientId, Map<String, dynamic> body) async {
    updated.add(body);
    return Result.success(rows.firstWhere((c) => c.id == clientId));
  }

  @override
  Future<Result<void>> deleteClient(String clientId) async {
    deleted.add(clientId);
    return Result.success(null);
  }

  @override
  Future<Result<ClientSummary>> transferClient(
    String clientId,
    ClientTransferRequest request,
  ) async {
    transfers.add(request.toJson());
    if (transferAtCapacityOnce) {
      transferAtCapacityOnce = false;
      return Result.failure(
        const ApiError(message: 'Oak Lodge is at capacity', statusCode: 409),
      );
    }
    return Result.success(rows.firstWhere((c) => c.id == clientId));
  }

  @override
  Future<Result<List<ClientFamilyMember>>> getFamily(String clientId) async =>
      Result.success(family);

  @override
  Future<Result<void>> addFamilyMember(String clientId, Map<String, dynamic> body) async {
    familyAdded.add(body);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateFamilyMember(
    String clientId,
    String memberId,
    Map<String, dynamic> body,
  ) async =>
      Result.success(null);

  @override
  Future<Result<void>> removeFamilyMember(String clientId, String memberId) async =>
      Result.success(null);

  @override
  Future<Result<List<ClientRoom>>> getRooms(String residenceId) async => Result.success([
        ClientRoom(id: '${residenceId}_r2', name: 'Room 7', roomType: 'single', available: 1),
      ]);

  @override
  Future<Result<ClientSpend>> getSpend(String clientId) async => Result.success(
        ClientSpend(
          spend: 42.5,
          purchaseCount: 1,
          stockOnHandValue: 10,
          stockOnHandCount: 2,
          purchases: [
            ClientPurchase(
              item: 'Incontinence pads',
              quantity: 5,
              unitCost: 8.5,
              lineTotal: 42.5,
              orderedAt: DateTime(2026, 9, 3),
            ),
          ],
        ),
      );

  @override
  Future<Result<String>> uploadFile(ClientPickedFile file, String category) async =>
      Result.success('/uploads/${file.name}');

  @override
  Future<Result<void>> fileCarePlanDocument({
    required String clientId,
    required String name,
    required String fileUrl,
  }) async =>
      Result.success(null);

  @override
  Future<Result<List<int>>> exportRosterCsv() async {
    exportCalls++;
    return Result.success(
      ClientsRepositoryImpl.rosterCsv(rows).codeUnits,
    );
  }
}

late _FakeRepo _repo;
final _saved = <(String, List<int>)>[];

Future<void> _pumpPage(
  WidgetTester tester, {
  Set<String> denied = const {},
  int? limit,
  String? initialResidenceId,
}) async {
  _tallView(tester);
  _repo.limit = limit;
  Get.put(
    ClientsController(
      repository: _repo,
      session: _Session(denied: denied),
      saveCsv: (name, bytes) async {
        _saved.add((name, bytes));
        return null;
      },
    ),
  );
  await tester.pumpWidget(_app(ClientsPage(initialResidenceId: initialResidenceId)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadOutfitFont);

  setUp(() async {
    Get.reset();
    await GetIt.I.reset();
    _repo = _FakeRepo();
    _saved.clear();
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('M05 Client Directory header', () {
    testWidgets('shows Add Client and Export List with the web table rows', (tester) async {
      await _pumpPage(tester);

      expect(find.text('Client Directory'), findsOneWidget);
      expect(find.text('Add Client'), findsOneWidget);
      expect(find.text('Export List'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('ID: #c1aaaaaa'), findsOneWidget);
      expect(find.text('Elm House · Room 4'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Showing 1 to 2 of 2 entries'), findsOneWidget);
    });

    testWidgets('Add Client accepts clients:write when clients:create is missing', (tester) async {
      await _pumpPage(tester, denied: {'clients:create'});
      expect(find.text('Add Client'), findsOneWidget);
    });

    testWidgets('buttons are hidden without create/write and export', (tester) async {
      await _pumpPage(
        tester,
        denied: {'clients:create', 'clients:write', 'clients:export'},
      );
      expect(find.byKey(const ValueKey('clients-add')), findsNothing);
      expect(find.byKey(const ValueKey('clients-export')), findsNothing);
    });

    testWidgets('plan limit reached shows a disabled Limit Exceeded button', (tester) async {
      await _pumpPage(tester, limit: 2);
      expect(find.text('Add Client'), findsNothing);
      expect(find.text('Limit Exceeded'), findsOneWidget);
      expect(_enabled(tester, 'clients-add'), isFalse);
      expect(
        find.byTooltip('Plan limit reached (2/2 clients). Upgrade your plan to admit more.'),
        findsOneWidget,
      );
    });

    testWidgets('Export List saves the client_roster CSV and says so', (tester) async {
      await _pumpPage(tester);
      await _tap(tester, find.byKey(const ValueKey('clients-export')));

      expect(_repo.exportCalls, 1);
      expect(_saved, hasLength(1));
      expect(_saved.single.$1, startsWith('client_roster-'));
      expect(_saved.single.$1, endsWith('.csv'));
      final csv = String.fromCharCodes(_saved.single.$2);
      expect(csv, startsWith('Client Name,Client ID,Residence,Care Level,DOB,Room,Status'));
      expect(csv, contains('Ada Lovelace'));
      expect(find.text('Export ready'), findsOneWidget);
    });

    testWidgets('search is server side and the empty state uses the web copy', (tester) async {
      await _pumpPage(tester);
      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(_repo.lastSearch.last, 'zzz');
      expect(find.text('No clients found'), findsOneWidget);
      expect(find.text('No client matches these filters.'), findsOneWidget);
    });

    testWidgets('initialResidenceId pre-filters the list', (tester) async {
      await _pumpPage(tester, initialResidenceId: 'oak');
      expect(find.text('Ben Okafor'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsNothing);
      expect(find.text('Oak Lodge'), findsWidgets);
    });
  });

  group('M05 Add New Client wizard', () {
    testWidgets('Next validates the required fields and Create posts client + guardian',
        (tester) async {
      await _pumpPage(tester);
      await _tap(tester, find.byKey(const ValueKey('clients-add')));
      expect(find.text('Add New Client'), findsOneWidget);
      expect(find.text('STEP 1 OF 5'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Last name is required'), findsOneWidget);
      expect(find.text('Date of birth is required'), findsOneWidget);

      await _type(tester, 'client-first-name', 'Ada2');
      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      expect(find.text('First name can only contain letters'), findsOneWidget);

      await _type(tester, 'client-first-name', 'Grace');
      await _type(tester, 'client-last-name', 'Hopper');
      await _pickFirstOfMonth(tester, 'client-dob');
      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      expect(find.text('STEP 2 OF 5'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      expect(_inKey('client-residence', find.text('Select a residence')), findsNWidgets(2));
      expect(find.text('Admission date is required'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('client-residence')));
      await _tap(tester, find.text('Elm House').last);
      expect(find.byKey(const ValueKey('client-room-picker')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('client-room-picker')));
      await _tap(tester, find.text('Room 7 — 1 free (single)'));
      await _pickFirstOfMonth(tester, 'client-admission-date');
      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      expect(find.text('STEP 3 OF 5'), findsOneWidget);

      await _type(tester, 'client-guardian-name', 'Mary Benson');
      await _type(tester, 'client-guardian-phone', '12');
      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      expect(find.text('STEP 5 OF 5'), findsOneWidget);
      expect(find.text('Create Client'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('add-client-create')));
      expect(_repo.created, isEmpty);
      expect(find.text('STEP 3 OF 5'), findsOneWidget);
      expect(find.text('Enter a valid phone number'), findsOneWidget);

      await _type(tester, 'client-guardian-phone', '(555) 123-4567');
      await _tap(tester, find.byKey(const ValueKey('client-step-care')));
      await _tap(tester, find.byKey(const ValueKey('add-client-create')));

      expect(_repo.created, hasLength(1));
      final body = _repo.created.single;
      expect(body['firstName'], 'Grace');
      expect(body['lastName'], 'Hopper');
      expect(body['residenceId'], 'elm');
      expect(body['roomId'], 'elm_r2');
      expect(body['level'], 'Low');
      expect(body['status'], 'Active');
      expect(body['dateOfBirth'], matches(RegExp(r'^\d{4}-\d{2}-01$')));
      expect(body['admissionDate'], matches(RegExp(r'^\d{4}-\d{2}-01$')));
      expect((body['portalVisibility'] as Map)['dailyLogs'], isTrue);
      expect((body['portalVisibility'] as Map)['incidents'], isFalse);
      expect(body['medicalInfo'], isA<Map<String, dynamic>>());
      expect(body['carePlan'], isA<Map<String, dynamic>>());

      expect(_repo.familyAdded, hasLength(1));
      final guardian = _repo.familyAdded.single;
      expect(guardian['name'], 'Mary Benson');
      expect(guardian['phone'], '(555) 123-4567');
      expect(guardian['isPrimaryGuardian'], isTrue);
      expect(guardian['createPortalUser'], isTrue);

      expect(find.text('Add New Client'), findsNothing);
      expect(find.text('Client added'), findsOneWidget);
    });

    testWidgets('Save Draft submits without step validation', (tester) async {
      await _pumpPage(tester);
      await _tap(tester, find.byKey(const ValueKey('clients-add')));
      await _type(tester, 'client-first-name', 'Draft');
      await _tap(tester, find.byKey(const ValueKey('add-client-draft')));

      expect(_repo.created, hasLength(1));
      expect(_repo.created.single['firstName'], 'Draft');
      expect(_repo.familyAdded, isEmpty);
    });
  });

  group('M05 row actions', () {
    testWidgets('menu shows View, Edit, Move and Delete with full access', (tester) async {
      await _pumpPage(tester);
      await _tap(tester, find.byKey(ValueKey('client-actions-${_ada.id}')));
      expect(find.text('View'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Move to another home'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('menu only offers View without update and delete', (tester) async {
      await _pumpPage(
        tester,
        denied: {'clients:update', 'clients:write', 'clients:delete'},
      );
      await _tap(tester, find.byKey(ValueKey('client-actions-${_ada.id}')));
      expect(find.text('View'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Move to another home'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('Delete asks first, then deletes', (tester) async {
      await _pumpPage(tester);
      await _tap(tester, find.byKey(ValueKey('client-actions-${_ada.id}')));
      await _tap(tester, find.text('Delete'));
      expect(find.text('Delete Ada Lovelace?'), findsOneWidget);
      expect(
        find.text('This removes the client from the directory along with their '
            'daily logs, care plan, and family portal access.'),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const ValueKey('client-delete-confirm')));

      expect(_repo.deleted, [_ada.id]);
      expect(find.text('Client deleted'), findsOneWidget);
    });

    testWidgets('Move asks for an over-capacity reason when the home is full', (tester) async {
      _repo.transferAtCapacityOnce = true;
      await _pumpPage(tester);
      await _tap(tester, find.byKey(ValueKey('client-actions-${_ada.id}')));
      await _tap(tester, find.text('Move to another home'));

      expect(
        find.text('Ada Lovelace is at Elm House. '
            'The move is recorded with its reason and the date.'),
        findsOneWidget,
      );
      expect(find.text('Leaving room 4'), findsOneWidget);
      expect(_enabled(tester, 'move-client-submit'), isFalse);

      await _tap(tester, find.byKey(const ValueKey('move-client-to')));
      expect(
        find.descendant(of: find.byType(ListTile), matching: find.text('Oak Lodge')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(ListTile), matching: find.text('Elm House')),
        findsNothing,
      );
      await _tap(tester, find.text('Oak Lodge').last);
      await _type(tester, 'move-client-reason', 'Closer to family');
      await _tap(tester, find.byKey(const ValueKey('move-client-submit')));

      expect(_repo.transfers.single, {'toResidenceId': 'oak', 'reason': 'Closer to family'});
      expect(find.byKey(const ValueKey('move-client-over-capacity')), findsOneWidget);
      expect(_enabled(tester, 'move-client-submit'), isFalse);

      await _type(tester, 'move-client-over-capacity', 'Hospital discharge today');
      await _tap(tester, find.byKey(const ValueKey('move-client-submit')));

      expect(_repo.transfers.last, {
        'toResidenceId': 'oak',
        'reason': 'Closer to family',
        'overCapacityReason': 'Hospital discharge today',
      });
      expect(find.text('Resident moved'), findsOneWidget);
    });
  });

  group('M05 client record', () {
    testWidgets('View is read-only with family contacts and inventory spend', (tester) async {
      await _pumpPage(tester);
      await _tap(tester, find.byKey(ValueKey('client-actions-${_ada.id}')));
      await _tap(tester, find.text('View'));

      expect(find.text('Client Details'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(
        find.text('Viewing the complete client record. Fields are read-only.'),
        findsOneWidget,
      );
      final first = tester.widget<TextField>(_inKey('client-first-name', find.byType(TextField)));
      expect(first.enabled, isFalse);
      expect(find.text('Mary Benson'), findsOneWidget);
      expect(find.text('Primary guardian'), findsOneWidget);
      expect(find.text('Portal access'), findsOneWidget);
      expect(find.byKey(const ValueKey('client-contact-add')), findsNothing);
      expect(find.text('Inventory Spend'), findsWidgets);
      expect(find.text('Incontinence pads'), findsOneWidget);
      expect(find.text('Edit Record'), findsOneWidget);
      expect(find.textContaining('of 5 sections complete'), findsOneWidget);
    });

    testWidgets('Edit saves the PATCH body without residenceId', (tester) async {
      await _pumpPage(tester);
      await _tap(tester, find.byKey(ValueKey('client-actions-${_ada.id}')));
      await _tap(tester, find.text('Edit'));

      expect(find.text('Save & Close'), findsOneWidget);
      await _type(tester, 'client-first-name', 'Adah');
      await _tap(tester, find.byKey(const ValueKey('client-save-close')));

      expect(_repo.updated, hasLength(1));
      final body = _repo.updated.single;
      expect(body['firstName'], 'Adah');
      expect(body.containsKey('residenceId'), isFalse);
      expect(body['roomId'], 'r1');
      expect((body['medicalInfo'] as Map)['allergies'], ['Peanuts']);
      expect(find.text('Client Details'), findsNothing);
      expect(find.text('Client updated'), findsOneWidget);
    });

    testWidgets('family contact add validates name and portal email', (tester) async {
      await _pumpPage(tester);
      await _tap(tester, find.byKey(ValueKey('client-actions-${_ada.id}')));
      await _tap(tester, find.text('Edit'));

      await _tap(tester, find.byKey(const ValueKey('client-contact-add')));
      await _tap(tester, find.byKey(const ValueKey('client-contact-save')));
      expect(find.text('Name is required'), findsOneWidget);

      await _type(tester, 'client-contact-name', 'Tom Hardy');
      await _tap(
        tester,
        _inKey('client-contact-portal', find.byType(Switch)),
      );
      await _tap(tester, find.byKey(const ValueKey('client-contact-save')));
      expect(find.text('An email address is needed to give portal access'), findsOneWidget);
      expect(_repo.familyAdded, isEmpty);

      await _type(tester, 'client-contact-email', 'tom@example.com');
      await _tap(tester, find.byKey(const ValueKey('client-contact-save')));

      expect(_repo.familyAdded.single, {
        'name': 'Tom Hardy',
        'isPrimaryGuardian': false,
        'isEmergencyContact': false,
        'receiveNotifications': true,
        'emergencyAlerts': true,
        'createPortalUser': true,
        'email': 'tom@example.com',
      });
      expect(find.text('Contact added'), findsOneWidget);
    });
  });

  group('M05 mapper', () {
    test('maps the live /clients row shape', () {
      final page = ClientsMapper.pageFrom({
        'data': [
          {
            'id': 'abcdef12-0000-0000-0000-000000000000',
            'firstName': 'Ada',
            'lastName': 'Lovelace',
            'residenceId': 'elm',
            'residence': {'id': 'elm', 'name': 'Elm House'},
            'roomId': null,
            'roomNumber': '12B',
            'level': 'High',
            'status': 'active',
            'dateOfBirth': '1950-04-02',
            'admissionDate': '2026-01-10',
            'fundingSource': 'Medicaid',
            'portalVisibility': {'dailyLogs': true, 'incidents': false},
            'carePlan': {
              'goals': ['Walk daily'],
              'servicePlan': 'Plan',
            },
            'medicalInfo': {
              'allergies': ['Peanuts'],
              'doctorName': 'Dr. Who',
            },
          },
        ],
        'meta': {'page': 1, 'limit': 10, 'total': 11, 'totalPages': 2},
      }, limit: 10);

      expect(page.total, 11);
      expect(page.totalPages, 2);
      final c = page.items.single;
      expect(c.shortId, 'abcdef12');
      expect(c.residenceName, 'Elm House');
      expect(c.room, '12B');
      expect(c.careLevel, 'High');
      expect(c.isActive, isTrue);
      expect(c.fundingSource, 'Medicaid');
      expect(c.portalVisibility, {'dailyLogs': true, 'incidents': false});
      expect(c.carePlanGoals, ['Walk daily']);
      expect(c.allergies, ['Peanuts']);
      expect(c.doctorName, 'Dr. Who');
    });
  });
}
