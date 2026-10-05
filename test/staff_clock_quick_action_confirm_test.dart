import 'package:comprehensive_hr_and_ops/core/constants/app_assets.dart';
import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/data/mappers/staff_home_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/domain/entities/staff_dashboard_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/domain/entities/staff_quick_action.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/domain/entities/today_shift_summary.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/domain/repositories/staff_dashboard_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/presentation/controllers/staff_dashboard_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/presentation/pages/staff_dashboard_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/search/domain/entities/staff_search_record.dart';
import 'package:comprehensive_hr_and_ops/features/staff/search/domain/repositories/staff_search_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(
      ResponsiveHelper.baseWidth,
      ResponsiveHelper.baseHeight,
    ),
    minTextAdapt: true,
    builder: (_, _) => GetMaterialApp(
      home: child,
      theme: ThemeData(scaffoldBackgroundColor: AppColors.scaffoldBackground),
    ),
  );
}

class _FakeSearchRepo extends Fake implements StaffSearchRepository {
  @override
  Future<Result<StaffTenantModules>> getTenantModules() async =>
      Result.success(const StaffTenantModules({}));
}

class _FakeDashboardRepo extends Fake implements StaffDashboardRepository {
  _FakeDashboardRepo({required this.onShift});

  final bool onShift;
  final List<String> calls = [];

  @override
  Future<Result<StaffDashboardOverview>> getOverview() async =>
      Result.success(StaffDashboardOverview(
        organizationName: 'Cozzy Cottage',
        dateLabel: 'Friday · 2 Oct',
        greetingLine: 'Good morning, Abir',
        greetingSubtitle: "Here's what's happening on your shift.",
        unreadNotificationCount: 0,
        todayShift: TodayShiftSummary(
          statusLabel: onShift ? 'On Shift' : 'Off Shift',
          dateLabel: 'October 2, 2026',
          timeRange: 'No shift today',
          onShift: onShift,
        ),
        overviewStats: const [],
        alertCount: 0,
        alertLabel: '',
        quickActions: [
          StaffQuickAction(
            id: 'clock-in-out',
            asset: AppAssets.clock,
            label: 'Clock In / Out',
            subtitle: 'Tap to manage your shift',
            trailing: onShift ? 'On Shift' : 'Off Shift',
          ),
        ],
      ));

  @override
  Future<Result<void>> checkIn({String? shiftId, String? residenceId}) async {
    calls.add('check-in');
    return Result.success(null);
  }

  @override
  Future<Result<void>> checkOut({String? shiftId, String? residenceId}) async {
    calls.add('check-out');
    return Result.success(null);
  }
}

Future<_FakeDashboardRepo> _openHome(
  WidgetTester tester, {
  required bool onShift,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = _FakeDashboardRepo(onShift: onShift);
  GetIt.I.registerSingleton<StaffSearchRepository>(_FakeSearchRepo());
  GetIt.I.registerFactory<StaffDashboardController>(
    () => StaffDashboardController(repository: repo),
  );
  await tester.pumpWidget(_wrap(const StaffDashboardPage()));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Clock In / Out'));
  await tester.tap(find.text('Clock In / Out'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUp(() async {
    Get.reset();
    await GetIt.I.reset();
    Get.put(
      UserSession()
        ..signIn(
          role: UserRole.staff,
          displayName: 'Abir Hasan',
          email: 'xirob96224@meonvr.com',
        ),
      permanent: true,
    );
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('Staff Home Clock In / Out quick action', () {
    testWidgets('on shift asks before clocking out; Cancel does nothing', (
      tester,
    ) async {
      final repo = await _openHome(tester, onShift: true);

      expect(find.text('Clock out?'), findsOneWidget);
      expect(find.text('This ends your shift attendance now.'), findsOneWidget);
      expect(repo.calls, isEmpty);

      await tester.tap(find.byKey(const ValueKey('clock-confirm-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Clock out?'), findsNothing);
      expect(repo.calls, isEmpty);
    });

    testWidgets('confirming clocks out', (tester) async {
      final repo = await _openHome(tester, onShift: true);

      await tester.tap(find.byKey(const ValueKey('clock-confirm-submit')));
      await tester.pumpAndSettle();

      expect(repo.calls, ['check-out']);
    });

    testWidgets('off shift asks before clocking in; confirming clocks in', (
      tester,
    ) async {
      final repo = await _openHome(tester, onShift: false);

      expect(find.text('Clock in?'), findsOneWidget);
      expect(find.text('This starts your shift attendance now.'), findsOneWidget);
      expect(repo.calls, isEmpty);

      await tester.tap(find.byKey(const ValueKey('clock-confirm-submit')));
      await tester.pumpAndSettle();

      expect(repo.calls, ['check-in']);
    });
  });

  group('Staff Home on-shift status', () {
    StaffDashboardOverview compose(Map<String, dynamic> attendance) =>
        StaffHomeMapper.compose(
          session: Get.find<UserSession>(),
          body: {
            'success': true,
            'data': {
              'attendance': attendance,
              'shift': null,
              'tiles': const {},
            },
          },
        );

    String clockTrailing(StaffDashboardOverview o) =>
        o.quickActions.firstWhere((a) => a.id == 'clock-in-out').trailing;

    test('a missed record never clocked into is Off Shift (live shape)', () {
      final overview = compose({
        'id': '3069fbbd-bf27-46f2-9a71-efdc72c471e4',
        'checkInAt': null,
        'onShift': true,
        'onBreak': false,
        'breakStartedAt': null,
        'breakMinutes': null,
        'residence': {
          'id': '4c134b43-d345-4b53-8043-1074e1a2cfba',
          'name': 'Cozzy Cottege',
        },
      });

      expect(overview.todayShift.onShift, isFalse);
      expect(overview.todayShift.statusLabel, 'Off Shift');
      expect(overview.overviewStats.first.value, 'Off Shift');
      expect(clockTrailing(overview), 'Off Shift');
    });

    test('an open clock-in is On Shift', () {
      final overview = compose({
        'id': 'a1',
        'checkInAt': '2026-10-02T03:00:00.000Z',
        'onShift': true,
        'onBreak': false,
      });

      expect(overview.todayShift.onShift, isTrue);
      expect(overview.todayShift.statusLabel, 'On Shift');
      expect(clockTrailing(overview), 'On Shift');
    });

    test('an open clock-in on break is On Break', () {
      final overview = compose({
        'id': 'a1',
        'checkInAt': '2026-10-02T03:00:00.000Z',
        'onShift': true,
        'onBreak': true,
      });

      expect(overview.todayShift.onShift, isTrue);
      expect(overview.todayShift.statusLabel, 'On Break');
    });

    test('a clocked-out record is Off Shift', () {
      final overview = compose({
        'id': 'a1',
        'checkInAt': '2026-10-02T03:00:00.000Z',
        'checkOutAt': '2026-10-02T11:00:00.000Z',
        'onShift': true,
        'onBreak': true,
      });

      expect(overview.todayShift.onShift, isFalse);
      expect(overview.todayShift.onBreak, isFalse);
      expect(overview.todayShift.statusLabel, 'Off Shift');
    });

    test('payloads without checkInAt keep the server onShift flag', () {
      expect(compose({'onShift': true}).todayShift.onShift, isTrue);
      expect(compose({'onShift': false}).todayShift.onShift, isFalse);
      expect(compose(const {}).todayShift.onShift, isFalse);
    });
  });
}
