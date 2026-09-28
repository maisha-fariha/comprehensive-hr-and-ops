import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/entities/client_summary.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/repositories/clients_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/controllers/clients_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/pages/client_detail_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/pages/clients_page.dart';
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

const _ayaan = ClientSummary(
  id: '1d9afca5-5520-4bc6-aa4e-770206ff9d27',
  firstName: 'Ayaan',
  lastName: 'Karim',
  status: 'active',
  residenceId: 'elm',
  room: '101',
  careLevel: 'high_support',
  allergies: ['Penicillin'],
  conditions: ['Epilepsy'],
  carePlanGoals: ['Walk daily with support'],
  reviewCycleDays: 90,
);

const _maya = ClientSummary(
  id: 'b7e2c4d1-0000-4000-8000-000000000002',
  firstName: 'Maya',
  lastName: 'Hossain',
  status: 'discharged',
  residenceId: 'oak',
  room: '202',
);

class _FakeClientsRepo implements ClientsRepository {
  @override
  Future<Result<List<ClientSummary>>> getClients() async =>
      Result.success(const [_ayaan, _maya]);

  @override
  Future<Result<ClientSummary>> getClient(String clientId) async =>
      Result.success(
        clientId == _ayaan.id
            ? ClientSummary(
                id: _ayaan.id,
                firstName: _ayaan.firstName,
                lastName: _ayaan.lastName,
                status: _ayaan.status,
                residenceId: _ayaan.residenceId,
                room: _ayaan.room,
                careLevel: _ayaan.careLevel,
                allergies: _ayaan.allergies,
                conditions: _ayaan.conditions,
                carePlanGoals: _ayaan.carePlanGoals,
                reviewCycleDays: _ayaan.reviewCycleDays,
                transfers: [
                  ClientTransfer(
                    fromResidenceId: 'oak',
                    toResidenceId: 'elm',
                    transferredAt: DateTime.utc(2026, 9, 1),
                    reason: 'Closer to family',
                  ),
                ],
              )
            : _maya,
      );

  @override
  Future<Result<Map<String, String>>> getResidenceNames() async =>
      Result.success(const {'elm': 'Elm House', 'oak': 'Oak Lodge'});
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

Future<void> _pumpClients(WidgetTester tester, {String? residenceId}) async {
  tester.view.physicalSize = const Size(375, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Get.put(ClientsController(repository: _FakeClientsRepo()));
  await tester.pumpWidget(
    _wrap(ClientsPage(initialResidenceId: residenceId)),
  );
  await tester.pumpAndSettle();
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

  testWidgets('BUG04: client directory lists every client', (tester) async {
    await _pumpClients(tester);

    expect(find.text('2 of 2 clients'), findsOneWidget);
    expect(find.text('Ayaan Karim'), findsOneWidget);
    expect(find.text('Maya Hossain'), findsOneWidget);
  });

  testWidgets('BUG04: search narrows by name and by short ID', (tester) async {
    await _pumpClients(tester);

    await tester.enterText(find.byType(TextField), 'maya');
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 clients'), findsOneWidget);
    expect(find.text('Ayaan Karim'), findsNothing);

    await tester.enterText(find.byType(TextField), '1D9AFC');
    await tester.pumpAndSettle();
    expect(find.text('Ayaan Karim'), findsOneWidget);
    expect(find.text('Maya Hossain'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pumpAndSettle();
    expect(find.text('No clients match your search or filters.'), findsOneWidget);
  });

  testWidgets('BUG04: opening from a residence pre-filters to that home',
      (tester) async {
    await _pumpClients(tester, residenceId: 'oak');

    expect(find.text('1 of 2 clients'), findsOneWidget);
    expect(find.text('Maya Hossain'), findsOneWidget);
    expect(find.text('Ayaan Karim'), findsNothing);
  });

  testWidgets('BUG04: tapping a client opens the care profile', (tester) async {
    await _pumpClients(tester);

    await tester.tap(find.text('Ayaan Karim'));
    await tester.pumpAndSettle();

    expect(find.byType(ClientDetailPage), findsOneWidget);
    for (final section in const [
      'Overview',
      'Medical info',
      'Care plan',
      'Transfer history',
    ]) {
      expect(find.text(section), findsOneWidget, reason: '$section section');
    }
    expect(find.text('#1D9AFC'), findsWidgets);
    expect(find.text('High support'), findsWidgets);
    expect(find.text('Penicillin'), findsOneWidget);
    expect(find.text('Epilepsy'), findsOneWidget);
    expect(find.text('Walk daily with support'), findsOneWidget);
    expect(find.text('Reviewed every 90 days'), findsOneWidget);
    expect(find.text('Oak Lodge → Elm House'), findsOneWidget);
  });
}
