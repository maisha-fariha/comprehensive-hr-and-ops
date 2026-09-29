import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/api_endpoints.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/data/mappers/scheduling_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/data/repositories/scheduling_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/scheduling_enums.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/scheduling_overview.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/shift_residence_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/shift_staff_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/presentation/controllers/scheduling_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/presentation/pages/scheduling_page.dart';
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

class _FakeSchedulingRepo implements SchedulingRepository {
  final List<bool> mineCalls = [];

  @override
  Future<Result<SchedulingOverview>> getOverview({
    DateTime? weekOf,
    DateTime? selectedDay,
    String? residenceId,
    ShiftStatusFilter? status,
    bool mine = false,
  }) async {
    mineCalls.add(mine);
    return Result.success(
      SchedulingMapper.compose(
        weekBody: const [],
        openBody: const [],
        pendingSwapsBody: const {'data': []},
        approvedSwapsBody: const {'data': []},
        declinedSwapsBody: const {'data': []},
        weekOf: weekOf,
        selectedDay: selectedDay,
      ),
    );
  }

  @override
  Future<Result<List<ShiftResidenceOption>>> getResidences() async =>
      Result.success(const []);

  @override
  Future<Result<List<ShiftStaffOption>>> getStaffOptions() async =>
      Result.success(const []);

  @override
  Future<Result<int>> createShift(Map<String, dynamic> payload) async =>
      Result.success(1);

  @override
  Future<Result<void>> decideShiftSwap({
    required String swapId,
    required bool approve,
  }) async =>
      Result.success(null);
}

class _FakeApi implements AppApiClient {
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
    return Result.success({'data': const []});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserSession _session(List<String> permissions) =>
    UserSession()..applyPermissions(permissions);

Future<_FakeSchedulingRepo> _pumpPage(
  WidgetTester tester, {
  required List<String> permissions,
}) async {
  tester.view.physicalSize = const Size(375, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = _FakeSchedulingRepo();
  Get.put(
    SchedulingController(repository: repo, session: _session(permissions)),
    permanent: true,
  );
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(
        ResponsiveHelper.baseWidth,
        ResponsiveHelper.baseHeight,
      ),
      minTextAdapt: true,
      builder: (_, _) => GetMaterialApp(
        home: const SchedulingPage(),
        theme: ThemeData(
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

const _myShifts = ValueKey('scheduling-my-shifts');

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

  testWidgets('BUG05: "My shifts" toggles mine=true on and off, like the web',
      (tester) async {
    final repo = await _pumpPage(
      tester,
      permissions: const ['scheduling:read', 'scheduling:write'],
    );

    expect(find.byKey(_myShifts), findsOneWidget);
    expect(find.text('My shifts'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Shift'), findsOneWidget);
    expect(repo.mineCalls, [false]);

    await tester.tap(find.byKey(_myShifts));
    await tester.pumpAndSettle();
    expect(repo.mineCalls, [false, true]);
    expect(Get.find<SchedulingController>().mineOnly.value, isTrue);
    final toggle = tester.widget<Semantics>(
      find.ancestor(of: find.byKey(_myShifts), matching: find.byType(Semantics)).first,
    );
    expect(toggle.properties.toggled, isTrue);

    await tester.tap(find.byKey(_myShifts));
    await tester.pumpAndSettle();
    expect(repo.mineCalls, [false, true, false]);
    expect(Get.find<SchedulingController>().mineOnly.value, isFalse);
  });

  testWidgets('BUG05: "My shifts" stays on across week changes and refresh',
      (tester) async {
    final repo = await _pumpPage(
      tester,
      permissions: const ['scheduling:read', 'scheduling:write'],
    );
    final controller = Get.find<SchedulingController>();

    await tester.tap(find.byKey(_myShifts));
    await tester.pumpAndSettle();
    await controller.goToNextWeek();
    await controller.refresh();
    await tester.pumpAndSettle();
    expect(repo.mineCalls, [false, true, true, true]);
  });

  testWidgets(
      'BUG05: without scheduling:write, "My shifts" and Create Shift are hidden',
      (tester) async {
    await _pumpPage(tester, permissions: const ['scheduling:read']);

    expect(find.byKey(_myShifts), findsNothing);
    expect(find.text('Shift'), findsNothing);
    expect(find.text('Filters'), findsOneWidget);
  });

  test('BUG05: mine=true goes on the week and open shift queries only',
      () async {
    final api = _FakeApi();
    final repo = SchedulingRepositoryImpl(api: api, session: UserSession());

    await repo.getOverview(weekOf: DateTime(2026, 9, 28), mine: true);
    final shiftQueries = [
      for (final (path, query) in api.calls)
        if (path == ApiEndpoints.shifts) query!,
    ];
    final swapQueries = [
      for (final (path, query) in api.calls)
        if (path == ApiEndpoints.shiftSwaps) query!,
    ];
    expect(shiftQueries, hasLength(2));
    for (final query in shiftQueries) {
      expect(query['mine'], isTrue);
    }
    expect(shiftQueries.last['status'], 'open');
    expect(swapQueries, hasLength(3));
    for (final query in swapQueries) {
      expect(query.containsKey('mine'), isFalse);
    }

    api.calls.clear();
    await repo.getOverview(weekOf: DateTime(2026, 9, 28));
    for (final (_, query) in api.calls) {
      expect(query!.containsKey('mine'), isFalse);
    }
  });
}
