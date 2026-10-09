import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/domain/entities/emergency_alert.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/domain/repositories/emergency_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/presentation/widgets/emergency_alert_motion.dart';
import 'package:comprehensive_hr_and_ops/features/hr/emergency/presentation/widgets/raise_emergency_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

class _Repo extends Fake implements EmergencyRepository {
  _Repo(this.total);

  int total;
  final List<String?> statuses = [];

  @override
  Future<Result<EmergencyAlertPage>> list({
    String? status,
    required int page,
    required int limit,
  }) async {
    statuses.add(status);
    return Result.success(EmergencyAlertPage(items: const [], total: total));
  }
}

class _Denied extends UserSession {
  @override
  bool can(String permission) => false;
}

Widget _app(Widget child) {
  return GetMaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets('Emergency pill shows the active count and stays still when clear', (
    tester,
  ) async {
    final repo = _Repo(4);
    Get.put<UserSession>(UserSession());
    GetIt.I.registerSingleton<EmergencyRepository>(repo);

    await tester.pumpWidget(
      _app(EmergencyRaiseButton(onPressed: () {}, onDark: true)),
    );
    await tester.pump();

    expect(repo.statuses, ['active']);
    expect(find.byKey(const ValueKey('emergency-active-count')), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.byType(EmergencyPulse), findsNothing);

    repo.total = 0;
    await ActiveEmergencyAlerts.refresh();
    await tester.pump();

    expect(find.byKey(const ValueKey('emergency-active-count')), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('the pill does not poll without emergency read', (tester) async {
    final repo = _Repo(3);
    Get.put<UserSession>(_Denied());
    GetIt.I.registerSingleton<EmergencyRepository>(repo);

    await tester.pumpWidget(
      _app(EmergencyRaiseButton(onPressed: () {}, onDark: true)),
    );
    await tester.pump();

    expect(repo.statuses, isEmpty);
    expect(find.byKey(const ValueKey('emergency-active-count')), findsNothing);
    await tester.pumpAndSettle();
  });
}
