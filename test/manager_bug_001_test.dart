import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/common/inbox/domain/entities/portal_notification.dart';
import 'package:comprehensive_hr_and_ops/features/common/inbox/domain/entities/portal_search_hit.dart';
import 'package:comprehensive_hr_and_ops/features/common/inbox/domain/repositories/portal_inbox_repository.dart';
import 'package:comprehensive_hr_and_ops/features/common/inbox/presentation/pages/portal_search_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/dashboard/domain/entities/dashboard_overview.dart';
import 'package:comprehensive_hr_and_ops/features/hr/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/dashboard/presentation/pages/manager_dashboard_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/domain/entities/residence_summary.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/domain/repositories/residences_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/presentation/controllers/residences_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/presentation/pages/residences_page.dart';
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

class _FakeDashboardRepo implements DashboardRepository {
  @override
  Future<Result<DashboardOverview>> getOverview() async => Result.success(
        const DashboardOverview(
          organizationName: 'Demo Care Group',
          dateLabel: 'Monday · 28 Sep',
          greetingLine: 'Good afternoon, Rafi',
          greetingSubtitle: 'Here is today at a glance',
          lastUpdatedLabel: 'Updated just now',
          unreadNotificationCount: 0,
          unresolvedAlertCount: 0,
          avatarInitials: 'RA',
          attentionAlerts: [],
          overviewStats: [],
          scheduleShifts: [],
          quickActions: [],
        ),
      );
}

class _FakeResidencesRepo implements ResidencesRepository {
  @override
  Future<Result<List<ResidenceSummary>>> getResidences() async =>
      Result.success(const [
        ResidenceSummary(
          id: 'r1',
          name: 'Elm House',
          status: 'active',
          bedCapacity: 4,
          residents: 1,
          residenceType: 'Group Home',
        ),
      ]);

  @override
  Future<Result<List<ResidenceRoom>>> getRooms(String residenceId) async =>
      Result.success(const []);
}

class _FakeInboxRepo implements PortalInboxRepository {
  @override
  Future<Result<List<PortalSearchHit>>> search(String query) async =>
      Result.success(const []);

  @override
  Future<Result<List<PortalNotification>>> getNotifications() async =>
      Result.success(const []);

  @override
  Future<Result<void>> markNotificationRead(String id) async =>
      Result.success(null);

  @override
  Future<Result<void>> markAllNotificationsRead() async =>
      Result.success(null);
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

const _filter = Key('manager-dashboard-filter');

Future<void> _pumpDashboard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Get.put(
    DashboardController(repository: _FakeDashboardRepo()),
    permanent: true,
  );
  await tester.pumpWidget(_wrap(const ManagerDashboardPage()));
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(_filter));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserSession session;

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
    session = UserSession()
      ..signIn(
        role: UserRole.hr,
        displayName: 'Rafi Ahmed',
        email: 'residence_manager@demo.local',
        avatarInitials: 'RA',
      );
    Get.put(session, permanent: true);
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets('BUG01: filter button is shown on the dashboard search bar',
      (tester) async {
    await _pumpDashboard(tester);

    expect(find.byKey(const Key('manager-dashboard-search')), findsOneWidget);
    expect(find.byKey(_filter), findsOneWidget);
  });

  testWidgets('BUG01: tapping the filter button opens the "Search pages" sheet',
      (tester) async {
    await _pumpDashboard(tester);
    expect(find.text('Jump to'), findsNothing);

    await _openSheet(tester);

    expect(find.text('Jump to'), findsOneWidget);
    expect(find.text('Search pages…'), findsOneWidget);
    for (final page in const [
      'Dashboard',
      'Residences',
      'Clients',
      'Scheduling',
      'Attendance',
      'Incidents',
      'Daily Logs',
    ]) {
      await tester.scrollUntilVisible(
        find.text(page),
        80,
        scrollable: find.descendant(
          of: find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ListView),
          ),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(page), findsOneWidget, reason: '$page should be listed');
    }
    // The filter tap must not fall through to the full-text search screen.
    expect(find.byType(PortalSearchPage), findsNothing);
  });

  testWidgets('BUG01: typing narrows the page list', (tester) async {
    await _pumpDashboard(tester);
    await _openSheet(tester);

    await tester.enterText(find.byType(TextField), 'resid');
    await tester.pumpAndSettle();
    expect(find.text('Residences'), findsOneWidget);
    expect(find.text('Attendance'), findsNothing);
    expect(find.text('Scheduling'), findsNothing);

    // Keyword match: "handovers" finds Daily Logs.
    await tester.enterText(find.byType(TextField), 'handovers');
    await tester.pumpAndSettle();
    expect(find.text('Daily Logs'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No pages match your search.'), findsOneWidget);
  });

  testWidgets('BUG01: selecting a page navigates to it', (tester) async {
    Get.put(ResidencesController(repository: _FakeResidencesRepo()));
    await _pumpDashboard(tester);
    await _openSheet(tester);

    await tester.tap(find.text('Residences'));
    await tester.pumpAndSettle();

    expect(find.text('Jump to'), findsNothing);
    expect(find.byType(ResidencesPage), findsOneWidget);
    expect(find.text('Elm House'), findsOneWidget);
  });

  testWidgets('BUG01: pages without permission are hidden', (tester) async {
    session.applyPermissions(const ['scheduling:read', 'attendance:read']);
    await _pumpDashboard(tester);
    await _openSheet(tester);

    expect(find.text('Scheduling'), findsOneWidget);
    expect(find.text('Residences'), findsNothing);
    expect(find.text('Clients'), findsNothing);
  });

  testWidgets('BUG01: the whole filter button is tappable, including its '
      'lower half below the header edge', (tester) async {
    await _pumpDashboard(tester);

    final rect = tester.getRect(find.byKey(_filter));
    await tester.tapAt(Offset(rect.center.dx, rect.bottom - 3));
    await tester.pumpAndSettle();

    expect(find.text('Jump to'), findsOneWidget);
  });

  testWidgets('BUG01: the rest of the search bar still opens full search',
      (tester) async {
    GetIt.I.registerSingleton<PortalInboxRepository>(_FakeInboxRepo());
    await _pumpDashboard(tester);

    final bar = tester.getRect(find.byKey(const Key('manager-dashboard-search')));
    await tester.tapAt(Offset(bar.left + 60, bar.bottom - 8));
    await tester.pumpAndSettle();

    expect(find.byType(PortalSearchPage), findsOneWidget);
    expect(find.text('Jump to'), findsNothing);
  });
}
