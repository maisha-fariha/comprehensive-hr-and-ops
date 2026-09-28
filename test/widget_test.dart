// Basic smoke test: the app boots into the HR Manager Dashboard and renders
// its key sections without throwing.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comprehensive_hr_and_ops/app.dart';
import 'package:comprehensive_hr_and_ops/core/config/app_env.dart';
import 'package:comprehensive_hr_and_ops/core/di/service_locator.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/dashboard/domain/entities/attention_alert.dart';
import 'package:comprehensive_hr_and_ops/features/hr/dashboard/domain/entities/dashboard_enums.dart';
import 'package:comprehensive_hr_and_ops/features/hr/dashboard/domain/entities/dashboard_overview.dart';
import 'package:comprehensive_hr_and_ops/features/hr/dashboard/domain/entities/quick_action.dart';
import 'package:comprehensive_hr_and_ops/features/hr/dashboard/domain/repositories/dashboard_repository.dart';

/// `flutter test` doesn't load bundled TTFs by default, so text falls back to
/// a generic test font with different glyph metrics than the real "Outfit"
/// font the layout was measured against. Loading it explicitly keeps this
/// test's layout representative of the real, on-device rendering.
Future<void> _loadOutfitFont() async {
  final data = await rootBundle.load('assets/fonts/outfit/Outfit-Variable.ttf');
  final loader = FontLoader('Outfit')..addFont(Future.value(data));
  await loader.load();
}

/// Widget tests answer every HTTP request with 400, so the dashboard reads
/// its overview from here instead of `GET /dashboard`.
class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<Result<DashboardOverview>> getOverview() async => Result.success(
        const DashboardOverview(
          organizationName: 'Demo Care Group',
          dateLabel: 'Monday · 28 Sep',
          greetingLine: 'Good morning, Alex',
          greetingSubtitle: 'Here is today at a glance',
          lastUpdatedLabel: 'Updated just now',
          unreadNotificationCount: 0,
          unresolvedAlertCount: 1,
          avatarInitials: 'AL',
          attentionAlerts: [
            AttentionAlert(
              id: 'a1',
              title: 'Night shift understaffed',
              subtitle: 'Elm House · 1 open slot',
              severity: AlertSeverity.urgent,
            ),
          ],
          overviewStats: [],
          scheduleShifts: [],
          quickActions: [
            QuickAction(type: QuickActionType.createShift, label: 'Create Shift'),
          ],
        ),
      );
}

void main() {
  testWidgets('HR Dashboard renders its main sections', (WidgetTester tester) async {
    await _loadOutfitFont();
    Get.reset();
    Get.put(UserSession(), permanent: true).signIn(role: UserRole.hr, displayName: 'Alex');

    SharedPreferences.setMockInitialValues({});
    final hiveDir = Directory.systemTemp.createTempSync('hive_smoke');
    addTearDown(() => hiveDir.deleteSync(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => hiveDir.path,
    );
    // Hive opens real files, which never complete inside the fake-async zone.
    await tester.runAsync(
      () => setupAppDependencies(
        apiConfig: const ApiConfig(baseUrl: AppEnv.apiBaseUrl),
      ),
    );
    GetIt.instance
      ..unregister<DashboardRepository>()
      ..registerLazySingleton<DashboardRepository>(_FakeDashboardRepository.new);

    // Match the Figma reference frame (375x812, see `ResponsiveHelper.base*`)
    // so responsive scaling behaves exactly as it would on the reference
    // device instead of distorting proportions.
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ComprehensiveHrAndOpsApp());
    // `pumpAndSettle` never converges here because GetX's `GetMaterialController`
    // keeps a perpetual animation ticker alive; pump a fixed number of frames
    // instead so the async `DashboardController.loadOverview()` has time to
    // resolve and rebuild via `Obx`.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text("Today's Overview"), findsOneWidget);

    // The rest of the body sits below the fold on a real phone screen, so
    // scroll the dashboard to bring it into view, matching how a user would
    // actually reach it.
    for (var i = 0; i < 10 && find.text('Quick Actions').evaluate().isEmpty; i++) {
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pump();
    }
    await tester.pump();

    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
