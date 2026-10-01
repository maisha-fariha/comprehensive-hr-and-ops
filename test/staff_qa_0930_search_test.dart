import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/api_endpoints.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/network/tenant_store.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/domain/entities/staff_dashboard_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/domain/entities/today_shift_summary.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/domain/repositories/staff_dashboard_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/presentation/controllers/staff_dashboard_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/presentation/pages/staff_dashboard_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/presentation/widgets/staff_home_search_bar.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/presentation/widgets/staff_overview_section.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/entities/staff_residence.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/repositories/staff_extras_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/presentation/pages/staff_residences_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/search/data/mappers/staff_search_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/staff/search/data/repositories/staff_search_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/staff/search/domain/entities/staff_search_record.dart';
import 'package:comprehensive_hr_and_ops/features/staff/search/domain/repositories/staff_search_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/search/presentation/pages/staff_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live `/me` permissions of the harmony-help caregiver QA used.
const _caregiverPermissions = [
  'appointments:read',
  'attendance:read',
  'attendance:write',
  'care-flags:read',
  'client-activities:read',
  'client-activities:write',
  'clients:read',
  'daily-logs:read',
  'daily-logs:write',
  'documents:read',
  'emergency:raise',
  'emergency:read',
  'incidents:read',
  'mar:read',
  'mar:write',
  'messaging:read',
  'messaging:write',
  'notifications:read',
  'notifications:write',
  'recurring-checks:complete',
  'recurring-checks:read',
  'residences:read',
  'scheduling:bid',
  'scheduling:read',
  'shift-handovers:read',
  'shift-handovers:write',
  'staff:directory',
  'tasks:read',
  'tasks:write',
  'training:read',
  'uploads:read',
  'uploads:write',
];

/// Live `/me` → `tenant.modules` for harmony-help.
const _harmonyModules = {
  'mar': true,
  'payroll': true,
  'reports': true,
  'training': true,
  'documents': true,
  'incidents': true,
  'inventory': true,
  'messaging': true,
  'attendance': true,
  'compliance': true,
  'scheduling': true,
  'appointments': true,
};

/// Web palette pages this caregiver sees, in sidebar order.
const _caregiverPages = [
  'Residences',
  'Clients',
  'Scheduling',
  'Attendance',
  'Handovers',
  'Recurring Checks',
  'Task Management',
  'Daily Logs',
  'Emergency',
  'Incidents',
  'Medication MAR',
  'Daily Activity',
  'Documents Management',
  'Appointments',
  'Training',
  'Communication',
];

const _hiddenForCaregiver = [
  'Dashboard',
  'Admissions',
  'Users & Access',
  'Inventory',
  'Reports & Analytics',
  'Compliance & Audit',
  'Finance & Payroll',
  'Support & Tickets',
  'Settings',
];

Future<void> _loadOutfitFont() async {
  final data = await rootBundle.load('assets/fonts/outfit/Outfit-Variable.ttf');
  final loader = FontLoader('Outfit')..addFont(Future.value(data));
  await loader.load();
}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(
      ResponsiveHelper.baseWidth,
      ResponsiveHelper.baseHeight,
    ),
    minTextAdapt: true,
    builder: (_, _) => GetMaterialApp(
      home: child,
      theme: ThemeData(
        fontFamily: 'Outfit',
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
    ),
  );
}

void _phone(WidgetTester tester, {Size size = const Size(390, 1400)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeSearchRepo implements StaffSearchRepository {
  _FakeSearchRepo({
    this.modules = const StaffTenantModules(_harmonyModules),
    this.modulesFail = false,
    this.results = const {},
  });

  final StaffTenantModules modules;
  final bool modulesFail;
  final Map<String, List<StaffSearchRecord>> results;
  final List<String> queries = [];

  @override
  Future<Result<StaffTenantModules>> getTenantModules() async {
    if (modulesFail) {
      return Result.failure(const NetworkError(message: 'offline'));
    }
    return Result.success(modules);
  }

  @override
  Future<Result<List<StaffSearchRecord>>> searchRecords(String query) async {
    queries.add(query);
    return Result.success(results[query.toLowerCase()] ?? const []);
  }
}

class _FakeDashboardRepo extends Fake implements StaffDashboardRepository {
  @override
  Future<Result<StaffDashboardOverview>> getOverview() async =>
      Result.success(const StaffDashboardOverview(
        organizationName: 'Cozzy Cottage',
        dateLabel: 'Thursday · 1 Oct',
        greetingLine: 'Good afternoon, Abir',
        greetingSubtitle: 'Here is your day',
        unreadNotificationCount: 0,
        todayShift: TodayShiftSummary(
          statusLabel: 'No shift',
          dateLabel: 'Today',
          timeRange: '--',
        ),
        overviewStats: [],
        alertCount: 0,
        alertLabel: '',
        quickActions: [],
      ));
}

class _FakeExtrasRepo extends Fake implements StaffExtrasRepository {
  @override
  Future<Result<List<StaffResidence>>> getResidences() async =>
      Result.success(const [
        StaffResidence(
          id: 'res-1',
          name: 'Cozzy Cottage',
          status: 'active',
          addressLine1: 'Haji Solimuddin Ln',
        ),
      ]);

  @override
  Future<Result<int>> getActiveResidentCount() async => Result.success(0);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceClients(
    String residenceId,
  ) async => Result.success(const []);
}

class _RecordingApiClient extends AppApiClient {
  _RecordingApiClient(super.api, super.tenant);

  final List<(String, Map<String, dynamic>?)> calls = [];

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) async {
    calls.add((path, query));
    if (path == '/me') {
      return Result.success({
        'success': true,
        'data': {
          'realm': 'tenant',
          'permissions': _caregiverPermissions,
          'tenant': {'subdomain': 'harmony-help', 'modules': _harmonyModules},
        },
      });
    }
    if (path == ApiEndpoints.search) {
      return Result.success({
        'success': true,
        'data': {
          'clients': [
            {
              'id': 'b9f85d33',
              'name': 'Client One',
              'residence': 'Cozzy Cottege',
            },
          ],
          'documents': [],
          'medications': [
            {
              'id': 'e53f3416',
              'name': 'Ooo',
              'dose': '45',
              'client': 'Client One',
            },
          ],
        },
      });
    }
    return Result.failure(ApiError(message: 'unexpected GET $path'));
  }
}

UserSession get _session => Get.find<UserSession>();

Future<void> _openSearch(
  WidgetTester tester, {
  required _FakeSearchRepo repo,
  ValueChanged<StaffSearchRecord>? onRecordTap,
}) async {
  GetIt.I.registerSingleton<StaffSearchRepository>(repo);
  await tester.pumpWidget(
    _wrap(StaffSearchPage(onRecordTap: onRecordTap)),
  );
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('staff-search-input')), text);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Finder _pageTile(String label) =>
    find.byKey(ValueKey('staff-search-page-$label'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
    Get.put(
      UserSession()
        ..signIn(
          role: UserRole.staff,
          displayName: 'Abir Hasan',
          email: 'xirob96224@meonvr.com',
        )
        ..applyStaffContext(
          staffId: 'staff-1',
          residenceId: '4c134b43-d345-4b53-8043-1074e1a2cfba',
          residenceName: 'Cozzy Cottage',
        )
        ..applyPermissions(_caregiverPermissions),
      permanent: true,
    );
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('S02 Staff Home search bar', () {
    testWidgets('shows at the top of Staff Home with the web placeholder and '
        'opens the page palette', (tester) async {
      _phone(tester);
      GetIt.I.registerSingleton<StaffSearchRepository>(_FakeSearchRepo());
      GetIt.I.registerFactory<StaffDashboardController>(
        () => StaffDashboardController(repository: _FakeDashboardRepo()),
      );

      await tester.pumpWidget(_wrap(const StaffDashboardPage()));
      await tester.pumpAndSettle();

      final bar = find.byKey(const Key('staff-home-search'));
      expect(bar, findsOneWidget);
      expect(find.text('Search residents, staff, tasks...'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(StaffHomeSearchBar)).dy,
        lessThan(tester.getTopLeft(find.byType(StaffOverviewSection)).dy),
      );

      await tester.tap(bar);
      await tester.pumpAndSettle();

      expect(find.byType(StaffSearchPage), findsOneWidget);
      expect(find.text('Search pages...'), findsOneWidget);
      expect(find.text('Pages'), findsOneWidget);
    });

    testWidgets('lists only the pages the caregiver may open, in web order', (
      tester,
    ) async {
      _phone(tester);
      await _openSearch(tester, repo: _FakeSearchRepo());

      for (final label in _caregiverPages) {
        expect(_pageTile(label), findsOneWidget, reason: label);
      }
      for (final label in _hiddenForCaregiver) {
        expect(_pageTile(label), findsNothing, reason: label);
      }
      final tops = [
        for (final label in _caregiverPages.take(6))
          tester.getTopLeft(_pageTile(label)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
    });

    testWidgets('disabled tenant modules hide their pages like the web', (
      tester,
    ) async {
      _phone(tester);
      await _openSearch(
        tester,
        repo: _FakeSearchRepo(
          modules: StaffTenantModules(
            Map.of(_harmonyModules)..['scheduling'] = false,
          ),
        ),
      );

      expect(_pageTile('Scheduling'), findsNothing);
      expect(_pageTile('Handovers'), findsNothing);
      expect(_pageTile('Recurring Checks'), findsNothing);
      expect(_pageTile('Task Management'), findsOneWidget);
    });

    testWidgets('unreadable /me keeps permission-gated pages visible', (
      tester,
    ) async {
      _phone(tester);
      await _openSearch(tester, repo: _FakeSearchRepo(modulesFail: true));

      expect(_pageTile('Scheduling'), findsOneWidget);
      expect(_pageTile('Inventory'), findsNothing);
    });

    testWidgets('typing filters pages and queries /search once after debounce',
        (tester) async {
      _phone(tester);
      final repo = _FakeSearchRepo(results: const {
        'ooo': [
          StaffSearchRecord(
            id: 'e53f3416',
            type: StaffSearchRecordType.medication,
            title: 'Ooo',
            subtitle: '45 · Client One',
          ),
        ],
      });
      await _openSearch(tester, repo: repo);

      await tester.enterText(find.byKey(const Key('staff-search-input')), 'O');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('staff-search-input')), 'Oo');
      await tester.pump(const Duration(milliseconds: 100));
      await _type(tester, 'Ooo');

      expect(repo.queries, ['Ooo']);
      expect(find.text('Medications'), findsOneWidget);
      expect(find.text('Ooo'), findsWidgets);
      expect(find.text('45 · Client One'), findsOneWidget);
    });

    testWidgets('page matches rank prefix hits first', (tester) async {
      _phone(tester);
      await _openSearch(tester, repo: _FakeSearchRepo());

      await _type(tester, 'tra');

      expect(_pageTile('Training'), findsOneWidget);
      expect(_pageTile('Residences'), findsNothing);
      expect(
        tester.getTopLeft(_pageTile('Training')).dy,
        lessThan(tester.getTopLeft(find.text('Pages')).dy + 80),
      );
    });

    testWidgets('no pages and no records shows the web empty copy', (
      tester,
    ) async {
      _phone(tester);
      final repo = _FakeSearchRepo();
      await _openSearch(tester, repo: repo);

      await _type(tester, 'zzzz');

      expect(repo.queries, ['zzzz']);
      expect(find.text('No matching pages found.'), findsOneWidget);
      expect(find.text('Pages'), findsNothing);
    });

    testWidgets('record groups and pages follow the user permissions', (
      tester,
    ) async {
      _phone(tester);
      _session.applyPermissions(
        _caregiverPermissions.where((p) => !p.startsWith('mar:')),
      );
      final repo = _FakeSearchRepo(results: const {
        'client': [
          StaffSearchRecord(
            id: 'b9f85d33',
            type: StaffSearchRecordType.client,
            title: 'Client One',
            subtitle: 'Cozzy Cottege',
          ),
          StaffSearchRecord(
            id: 'med-1',
            type: StaffSearchRecordType.medication,
            title: 'Client Med',
          ),
        ],
      });
      await _openSearch(tester, repo: repo);

      expect(_pageTile('Medication MAR'), findsNothing);
      await _type(tester, 'client');

      expect(find.text('Clients'), findsWidgets);
      expect(find.text('Client One'), findsOneWidget);
      expect(find.text('Medications'), findsNothing);
      expect(find.text('Client Med'), findsNothing);
    });

    testWidgets('no record permission skips the /search call', (tester) async {
      _phone(tester);
      _session.applyPermissions(const ['tasks:read', 'attendance:read']);
      final repo = _FakeSearchRepo();
      await _openSearch(tester, repo: repo);

      await _type(tester, 'task');

      expect(repo.queries, isEmpty);
      expect(_pageTile('Task Management'), findsOneWidget);
    });

    testWidgets('web pages without a Staff screen are listed but not tappable',
        (tester) async {
      _phone(tester);
      _session.applyPermissions([..._caregiverPermissions, 'settings:read']);
      await _openSearch(tester, repo: _FakeSearchRepo());

      await _type(tester, 'settings');
      expect(_pageTile('Settings'), findsOneWidget);
      final tile = tester.widget<ListTile>(
        find.descendant(of: _pageTile('Settings'), matching: find.byType(ListTile)),
      );
      expect(tile.enabled, isFalse);
      expect(tile.onTap, isNull);

      await tester.tap(_pageTile('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(StaffSearchPage), findsOneWidget);
    });

    testWidgets('tapping a page opens the Staff screen', (tester) async {
      _phone(tester);
      GetIt.I.registerSingleton<StaffExtrasRepository>(_FakeExtrasRepo());
      await _openSearch(tester, repo: _FakeSearchRepo());

      await tester.tap(_pageTile('Residences'));
      await tester.pumpAndSettle();

      expect(find.byType(StaffResidencesPage), findsOneWidget);
      expect(find.byType(StaffSearchPage), findsNothing);
    });

    testWidgets('tapping a record closes the palette and opens it', (
      tester,
    ) async {
      _phone(tester);
      StaffSearchRecord? opened;
      final repo = _FakeSearchRepo(results: const {
        'client': [
          StaffSearchRecord(
            id: 'b9f85d33',
            type: StaffSearchRecordType.client,
            title: 'Client One',
          ),
        ],
      });
      GetIt.I.registerSingleton<StaffSearchRepository>(repo);
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Get.to(
                  () => StaffSearchPage(onRecordTap: (r) => opened = r),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await _type(tester, 'client');
      await tester.tap(find.byKey(const ValueKey('staff-search-record-b9f85d33')));
      await tester.pumpAndSettle();

      expect(opened?.id, 'b9f85d33');
      expect(find.byType(StaffSearchPage), findsNothing);
    });
  });

  group('S02 Staff search data', () {
    test('maps the live /search and /me shapes', () {
      final records = StaffSearchMapper.recordsFrom({
        'success': true,
        'data': {
          'clients': [
            {'id': 'c1', 'name': 'Client One', 'residence': 'Cozzy Cottege'},
          ],
          'documents': [
            {'id': 'd1', 'title': 'Care plan', 'client': {'name': 'Client One'}},
          ],
          'medications': [
            {'id': 'm1', 'name': 'Ooo', 'dose': '45', 'client': 'Client One'},
          ],
        },
      });
      expect(records.map((r) => (r.type, r.title, r.subtitle)), [
        (StaffSearchRecordType.client, 'Client One', 'Cozzy Cottege'),
        (StaffSearchRecordType.document, 'Care plan', 'Client One'),
        (StaffSearchRecordType.medication, 'Ooo', '45 · Client One'),
      ]);

      final modules = StaffSearchMapper.modulesFrom({
        'data': {
          'tenant': {'modules': _harmonyModules},
        },
      });
      expect(modules.has('scheduling'), isTrue);
      expect(modules.has('family'), isFalse);
      expect(
        StaffSearchMapper.modulesFrom({'data': {'tenant': {}}}).has('mar'),
        isFalse,
      );
      expect(
        const StaffTenantModules({'legacy_unlimited': true}).has('mar'),
        isTrue,
      );
    });

    test('repository calls GET /me and GET /search?q=', () async {
      SharedPreferences.setMockInitialValues({});
      final tenant = TenantStore(await SharedPreferences.getInstance());
      await tenant.load();
      final api = _RecordingApiClient(
        ApiService(const ApiConfig(baseUrl: 'http://test')),
        tenant,
      );
      final repo = StaffSearchRepositoryImpl(api: api);

      final modules = await repo.getTenantModules();
      final records = await repo.searchRecords('  Ooo ');
      final empty = await repo.searchRecords('   ');

      expect(api.calls.map((c) => c.$1), ['/me', ApiEndpoints.search]);
      expect(api.calls.last.$2, {'q': 'Ooo'});
      modules.when(
        success: (m) => expect(m.has('mar'), isTrue),
        failure: (e) => fail(e.message),
      );
      records.when(
        success: (r) => expect(r.map((e) => e.title), ['Client One', 'Ooo']),
        failure: (e) => fail(e.message),
      );
      empty.when(
        success: (r) => expect(r, isEmpty),
        failure: (e) => fail(e.message),
      );
    });
  });
}
