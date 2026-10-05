import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/domain/entities/client_extras.dart';
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
  residenceName: 'Elm House',
  room: '101',
  careLevel: 'High',
  allergies: ['Penicillin'],
  conditions: ['Epilepsy'],
  carePlanGoals: ['Walk daily with support'],
);

const _maya = ClientSummary(
  id: 'b7e2c4d1-0000-4000-8000-000000000002',
  firstName: 'Maya',
  lastName: 'Hossain',
  status: 'discharged',
  residenceId: 'oak',
  residenceName: 'Oak Lodge',
  room: '202',
);

class _Session extends UserSession {
  @override
  bool can(String permission) => true;
}

class _FakeClientsRepo implements ClientsRepository {
  final searches = <String?>[];

  @override
  Future<Result<ClientPage>> getClients({
    required int page,
    required int limit,
    String? search,
    String? residenceId,
  }) async {
    searches.add(search);
    final q = (search ?? '').toLowerCase();
    final items = [_ayaan, _maya]
        .where((c) => q.isEmpty || c.fullName.toLowerCase().contains(q))
        .where((c) => residenceId == null || c.residenceId == residenceId)
        .toList();
    return Result.success(ClientPage(items: items, total: items.length, totalPages: 1));
  }

  @override
  Future<Result<ClientSummary>> getClient(String clientId) async => Result.success(
        clientId == _ayaan.id
            ? ClientSummary(
                id: _ayaan.id,
                firstName: _ayaan.firstName,
                lastName: _ayaan.lastName,
                status: _ayaan.status,
                residenceId: _ayaan.residenceId,
                residenceName: _ayaan.residenceName,
                room: _ayaan.room,
                careLevel: _ayaan.careLevel,
                allergies: _ayaan.allergies,
                conditions: _ayaan.conditions,
                carePlanGoals: _ayaan.carePlanGoals,
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

  @override
  Future<Result<int?>> getClientLimit() async => Result.success(null);

  @override
  Future<Result<ClientSummary>> createClient(Map<String, dynamic> body) async =>
      Result.success(_ayaan);

  @override
  Future<Result<ClientSummary>> updateClient(String clientId, Map<String, dynamic> body) async =>
      Result.success(_ayaan);

  @override
  Future<Result<void>> deleteClient(String clientId) async => Result.success(null);

  @override
  Future<Result<ClientSummary>> transferClient(
    String clientId,
    ClientTransferRequest request,
  ) async =>
      Result.success(_ayaan);

  @override
  Future<Result<List<ClientFamilyMember>>> getFamily(String clientId) async =>
      Result.success(const []);

  @override
  Future<Result<void>> addFamilyMember(String clientId, Map<String, dynamic> body) async =>
      Result.success(null);

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
  Future<Result<List<ClientRoom>>> getRooms(String residenceId) async =>
      Result.success(const []);

  @override
  Future<Result<ClientSpend>> getSpend(String clientId) async => Result.success(
        const ClientSpend(spend: 0, purchaseCount: 0, stockOnHandValue: 0, stockOnHandCount: 0),
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
  Future<Result<List<int>>> exportRosterCsv() async => Result.success(const []);
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

late _FakeClientsRepo _repo;

Future<void> _pumpClients(WidgetTester tester, {String? residenceId}) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Get.put(ClientsController(repository: _repo, session: _Session()));
  await tester.pumpWidget(
    _wrap(ClientsPage(initialResidenceId: residenceId)),
  );
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
    _repo = _FakeClientsRepo();
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets('BUG04: client directory lists every client', (tester) async {
    await _pumpClients(tester);

    expect(find.text('Showing 1 to 2 of 2 entries'), findsOneWidget);
    expect(find.text('Ayaan Karim'), findsOneWidget);
    expect(find.text('Maya Hossain'), findsOneWidget);
  });

  testWidgets('BUG04: search narrows the directory', (tester) async {
    await _pumpClients(tester);

    await _search(tester, 'maya');
    expect(_repo.searches.last, 'maya');
    expect(find.text('Maya Hossain'), findsOneWidget);
    expect(find.text('Ayaan Karim'), findsNothing);

    await _search(tester, 'nobody');
    expect(find.text('No clients found'), findsOneWidget);
  });

  testWidgets('BUG04: opening from a residence pre-filters to that home',
      (tester) async {
    await _pumpClients(tester, residenceId: 'oak');

    expect(find.text('Maya Hossain'), findsOneWidget);
    expect(find.text('Ayaan Karim'), findsNothing);
  });

  testWidgets('BUG04: tapping a client opens the client record', (tester) async {
    await _pumpClients(tester);

    await tester.tap(find.text('Ayaan Karim'));
    await tester.pumpAndSettle();

    expect(find.byType(ClientDetailPage), findsOneWidget);
    for (final section in const [
      'Basic Information',
      'Medical Information',
      'Care Planning',
    ]) {
      expect(find.text(section), findsWidgets, reason: '$section section');
    }
    expect(find.text('Transfer history'), findsOneWidget);
    expect(find.text('Oak Lodge → Elm House'), findsOneWidget);
  });
}
