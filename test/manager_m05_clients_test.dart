import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/data/mappers/clients_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/data/repositories/clients_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/entities/client_extras.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/entities/client_goals.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/entities/client_summary.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/repositories/clients_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/client_form.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/clients_labels.dart';
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
  final deleteReasons = <String?>[];
  final restored = <String>[];
  final createKeys = <String?>[];
  final goalsCreated = <Map<String, dynamic>>[];
  final goalUpdates = <Map<String, dynamic>>[];
  AppError? createFailure;
  bool rejectFamily = false;
  List<DeletedClient> deletedRows = const [];
  List<ClientGoal> goals = const [];
  ClientGoalOutcomes outcomes = const ClientGoalOutcomes();
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
  Future<Result<ClientSummary>> createClient(
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    created.add(body);
    createKeys.add(idempotencyKey);
    if (createFailure != null) return Result.failure(createFailure!);
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
  Future<Result<void>> deleteClient(String clientId, {String? reason}) async {
    deleted.add(clientId);
    deleteReasons.add(reason);
    return Result.success(null);
  }

  @override
  Future<Result<List<DeletedClient>>> getDeletedClients({String? search}) async =>
      Result.success(deletedRows);

  @override
  Future<Result<void>> restoreClient(String clientId) async {
    restored.add(clientId);
    return Result.success(null);
  }

  @override
  Future<Result<List<ClientGoalCategory>>> getGoalCategories() async => Result.success(const [
        ClientGoalCategory(key: 'social_skills', label: 'Social skills'),
        ClientGoalCategory(key: 'education', label: 'Education'),
        ClientGoalCategory(key: 'custom', label: 'Custom'),
      ]);

  @override
  Future<Result<List<ClientGoal>>> getGoals(String clientId) async => Result.success(goals);

  @override
  Future<Result<void>> createGoal(String clientId, Map<String, dynamic> body) async {
    goalsCreated.add(body);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateGoal(
    String clientId,
    String goalId,
    Map<String, dynamic> body,
  ) async {
    goalUpdates.add({'goalId': goalId, ...body});
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteGoal(String clientId, String goalId) async => Result.success(null);

  @override
  Future<Result<ClientGoalOutcomes>> getGoalOutcomes(String clientId) async =>
      Result.success(outcomes);

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
    if (rejectFamily) return Result.failure(const ApiError(message: 'Email is not valid'));
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
      expect(find.text('Primary Emergency Contact'), findsOneWidget);
      expect(find.text('Secondary Emergency Contact'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      expect(find.text('Primary emergency contact name is required'), findsOneWidget);
      expect(find.text('Relationship is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);

      await _type(tester, 'client-guardian-name', 'Mary Benson');
      await _type(tester, 'client-guardian-phone', '12');
      await _tap(tester, find.byKey(const ValueKey('client-relationship')));
      await _tap(tester, find.text('Parent').last);
      await _tap(tester, find.byKey(const ValueKey('client-step-medical')));
      expect(find.byKey(const ValueKey('client-allergies')), findsNothing);
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(
        find.text('Add an email for the family portal login, or turn portal access off'),
        findsOneWidget,
      );

      await _type(tester, 'client-guardian-phone', '(555) 123-4567');
      await _type(tester, 'client-guardian-email', 'mary@example.com');
      await _type(tester, 'client-secondary-name', 'John Benson');
      await _type(tester, 'client-secondary-phone', '(555) 987-6543');
      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      await _tap(tester, find.byKey(const ValueKey('add-client-next')));
      expect(find.text('STEP 5 OF 5'), findsOneWidget);
      expect(find.text('Create Client'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('goal-category-social_skills')));
      expect(find.byKey(const ValueKey('goal-category-custom')), findsNothing);
      await _tap(tester, find.text('Add Custom Goal'));
      await tester.enterText(
        _inKey('client-custom-goals', find.byType(TextField)).first,
        'Weekly call with mum',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('add-client-create')));

      expect(_repo.created, hasLength(1));
      final body = _repo.created.single;
      expect(body['firstName'], 'Grace');
      expect(body['middleName'], isNull);
      expect(body['lastName'], 'Hopper');
      expect(body['residenceId'], 'elm');
      expect(body['roomId'], 'elm_r2');
      expect(body['level'], 'Low');
      expect(body['status'], 'active');
      expect(body['dateOfBirth'], matches(RegExp(r'^\d{4}-\d{2}-01$')));
      expect(body['admissionDate'], matches(RegExp(r'^\d{4}-\d{2}-01$')));
      expect((body['portalVisibility'] as Map)['dailyLogs'], isTrue);
      expect((body['portalVisibility'] as Map)['incidents'], isFalse);
      expect(body['medicalInfo'], isA<Map<String, dynamic>>());
      expect(body['carePlan'], isA<Map<String, dynamic>>());
      expect(_repo.createKeys.single, isNotEmpty);

      expect(_repo.familyAdded, hasLength(2));
      final guardian = _repo.familyAdded.first;
      expect(guardian['name'], 'Mary Benson');
      expect(guardian['relationship'], 'Parent');
      expect(guardian['phone'], '(555) 123-4567');
      expect(guardian['email'], 'mary@example.com');
      expect(guardian['isPrimaryGuardian'], isTrue);
      expect(guardian['createPortalUser'], isTrue);
      expect(_repo.familyAdded.last, {
        'name': 'John Benson',
        'phone': '(555) 987-6543',
        'isPrimaryGuardian': false,
        'createPortalUser': false,
        'isEmergencyContact': true,
        'receiveNotifications': false,
        'emergencyAlerts': true,
      });
      expect(_repo.goalsCreated, [
        {'category': 'social_skills'},
        {'category': 'custom', 'title': 'Weekly call with mum'},
      ]);

      expect(find.text('Add New Client'), findsNothing);
    });

    testWidgets('middle name is sent and Children Services is a funding source',
        (tester) async {
      expect(
        ClientsLabels.fundingSources.sublist(ClientsLabels.fundingSources.length - 2),
        ['Children Services', 'Other'],
      );
      await _pumpPage(tester);
      await _tap(tester, find.byKey(const ValueKey('clients-add')));
      await _type(tester, 'client-first-name', 'Grace');
      await _type(tester, 'client-middle-name', 'Brewster');
      await _type(tester, 'client-last-name', 'Hopper');
      await _tap(tester, find.byKey(const ValueKey('client-step-residence')));
      expect(find.text('Date of birth is required'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('add-client-draft')));
      expect(_repo.created.single['middleName'], 'Brewster');
    });

    testWidgets('Save Draft needs a first and last name and saves as draft', (tester) async {
      await _pumpPage(tester);
      await _tap(tester, find.byKey(const ValueKey('clients-add')));
      await _type(tester, 'client-first-name', 'Draft');
      await _tap(tester, find.byKey(const ValueKey('add-client-draft')));
      expect(_repo.created, isEmpty);
      expect(find.text('Last name is required'), findsOneWidget);

      await _type(tester, 'client-last-name', 'Person');
      await _tap(tester, find.byKey(const ValueKey('add-client-draft')));

      expect(_repo.created, hasLength(1));
      expect(_repo.created.single['firstName'], 'Draft');
      expect(_repo.created.single['status'], 'draft');
      expect(_repo.familyAdded, isEmpty);
      expect(find.text('Draft client saved'), findsOneWidget);
    });

    testWidgets('a failed create keeps the wizard open and retries with the same key',
        (tester) async {
      _repo.createFailure = const ApiError(message: 'Server busy');
      await _pumpPage(tester);
      await _tap(tester, find.byKey(const ValueKey('clients-add')));
      await _type(tester, 'client-first-name', 'Retry');
      await _type(tester, 'client-last-name', 'Person');
      await _tap(tester, find.byKey(const ValueKey('add-client-draft')));
      expect(find.text('Add New Client'), findsOneWidget);

      _repo.createFailure = null;
      await _tap(tester, find.byKey(const ValueKey('add-client-draft')));
      expect(_repo.created, hasLength(2));
      expect(_repo.createKeys.toSet(), hasLength(1));
      expect(find.text('Add New Client'), findsNothing);
    });

    testWidgets('a contact the server rejects does not undo the created client',
        (tester) async {
      _repo.rejectFamily = true;
      await _pumpPage(tester);
      final form = ClientForm();
      form.firstName.text = 'Ada';
      form.lastName.text = 'Byron';
      form.guardianName.text = 'Bad Contact';
      final error = await Get.find<ClientsController>().createClient(form, draft: true);
      await tester.pumpAndSettle();

      expect(error, isNull);
      expect(_repo.created, hasLength(1));
      expect(
        find.text('Bad Contact was not added as a contact: Email is not valid'),
        findsOneWidget,
      );
      form.dispose();
    });
  });

  group('M05 deleted residents', () {
    testWidgets('delete sends the reason and the log restores a resident', (tester) async {
      _repo.deletedRows = [
        DeletedClient(
          client: _ben,
          deletedAt: DateTime.utc(2026, 10, 1, 9, 30),
          deletedByName: 'Maria Manager',
          reason: 'Duplicate record',
          statusBeforeDelete: 'active',
        ),
      ];
      await _pumpPage(tester);
      await _tap(tester, find.byKey(ValueKey('client-actions-${_ada.id}')));
      await _tap(tester, find.text('Delete'));
      expect(find.text('Reason (optional)'), findsOneWidget);
      await _type(tester, 'client-delete-reason', 'Added twice');
      await _tap(tester, find.byKey(const ValueKey('client-delete-confirm')));
      expect(_repo.deleted, [_ada.id]);
      expect(_repo.deleteReasons, ['Added twice']);

      await _tap(tester, find.byKey(const ValueKey('clients-deleted')));
      expect(find.text('Deleted residents'), findsWidgets);
      expect(find.text('Oak Lodge · was Active'), findsOneWidget);
      expect(find.textContaining('by Maria Manager'), findsOneWidget);
      expect(find.text('Reason: Duplicate record'), findsOneWidget);

      await _tap(tester, find.byKey(ValueKey('deleted-client-restore-${_ben.id}')));
      expect(_repo.restored, [_ben.id]);
      expect(find.text('Ben Okafor is back on the roster'), findsOneWidget);
    });

    testWidgets('the deleted log is hidden without clients:delete', (tester) async {
      await _pumpPage(tester, denied: {'clients:delete'});
      expect(find.byKey(const ValueKey('clients-deleted')), findsNothing);
    });
  });

  group('M05 goals & outcomes', () {
    testWidgets('the record shows goals with progress and can mark one achieved',
        (tester) async {
      _repo.goals = const [
        ClientGoal(
          id: 'g1',
          category: 'social_skills',
          categoryLabel: 'Social skills',
          title: 'Join a group activity',
        ),
      ];
      _repo.outcomes = const ClientGoalOutcomes(
        overall: GoalPeriods(
          weekly: GoalPeriod(logged: 4, achieved: 3, progress: 75, trend: 'upward'),
        ),
        byGoal: {
          'g1': GoalPeriods(weekly: GoalPeriod(logged: 4, achieved: 3, progress: 75)),
        },
      );
      await _pumpPage(tester);
      await _tap(tester, find.byKey(ValueKey('client-actions-${_ada.id}')));
      await _tap(tester, find.text('Edit'));

      expect(find.text('Goals & Outcomes'), findsOneWidget);
      expect(find.text('Join a group activity'), findsOneWidget);
      expect(find.text('Social skills'), findsOneWidget);
      expect(find.text('75%'), findsNWidgets(2));
      expect(find.text('3 of 4 shifts'), findsNWidgets(2));

      await _tap(tester, find.text('Mark achieved'));
      expect(_repo.goalUpdates.single, {'goalId': 'g1', 'status': 'achieved'});
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
        find.text('They leave the directory. The record is kept on the deleted log, '
            'with who deleted it and why, and can be restored from there.'),
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
