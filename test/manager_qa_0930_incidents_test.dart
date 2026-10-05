import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/data/mappers/incidents_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_witness_statement.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incidents_board.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incidents_enums.dart'
    as hr;
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/open_incident.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/repositories/incidents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/presentation/controllers/incidents_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/presentation/pages/hr_incident_details_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/presentation/pages/incidents_list_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/incident_detail.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incidents_enums.dart'
    as staff;
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/repositories/staff_incidents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/controllers/incident_details_controller.dart';
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

const _detail = IncidentDetail(
  id: 'inc-1',
  incidentCode: '#inc-1',
  categoryLabel: 'Fall',
  title: 'Slip in the hallway',
  iconKind: staff.StaffIncidentIconKind.warning,
  dateTimeLabel: '29 Sep 2026',
  severity: staff.IncidentSeverity.high,
  statusLabel: 'Open',
  detectedDuring: '',
  location: '',
  residentName: 'Ayaan Karim',
  residentSubLabel: '',
  residentInitials: 'AK',
  reportedByName: 'Jamal Uddin',
  reportedBySubLabel: '',
  reportedByInitials: 'JU',
  description: 'Resident slipped near the dining room.',
  residenceName: 'Elm House',
  reportedAtLabel: '29 Sep 2026',
);

class _StaffDetailRepo implements StaffIncidentsRepository {
  final List<String> acknowledged = [];

  @override
  Future<Result<IncidentDetail>> getIncidentDetail(String incidentId) async =>
      Result.success(_detail);

  @override
  Future<Result<void>> acknowledge(String incidentId) async {
    acknowledged.add(incidentId);
    return Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HrIncidentsRepo implements IncidentsRepository {
  final List<(String, String, String)> added = [];
  final List<String> signed = [];
  List<IncidentWitnessStatement> statements = const [
    IncidentWitnessStatement(
      id: 'ws-1',
      witnessType: 'staff',
      witnessName: 'Rina Akter',
      statementText: 'I saw her slip on the wet floor.',
      takenByName: 'Jamal Uddin',
    ),
  ];

  @override
  Future<Result<IncidentsBoard>> getBoard() async => Result.success(
        const IncidentsBoard(
          open: IncidentsOpenSection(
            stats: [],
            activeCount: 1,
            incidents: [
              OpenIncident(
                id: 'inc-1',
                title: 'Slip in the hallway',
                iconKind: hr.IncidentIconKind.bandage,
                severity: hr.IncidentSeverity.high,
                subtitle: 'Ayaan Karim · Elm House',
                statusLabel: 'Open',
                reportedAtLabel: 'Today',
                reporterInitials: 'JU',
                reporterName: 'Jamal Uddin',
              ),
            ],
          ),
          underReview: IncidentsUnderReviewSection(
            stats: [],
            incidents: [],
            investigationCount: 0,
          ),
          closed: IncidentsClosedSection(stats: [], incidents: []),
        ),
      );

  @override
  Future<Result<List<IncidentWitnessStatement>>> getWitnessStatements(
    String incidentId,
  ) async =>
      Result.success(statements);

  @override
  Future<Result<void>> addWitnessStatement({
    required String incidentId,
    required String witnessType,
    required String witnessName,
    required String statementText,
  }) async {
    added.add((witnessType, witnessName, statementText));
    return Result.success(null);
  }

  @override
  Future<Result<void>> signWitnessStatement({
    required String incidentId,
    required String statementId,
  }) async {
    signed.add(statementId);
    return Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StaffDetailRepo staffRepo;
  late _HrIncidentsRepo hrRepo;

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
    staffRepo = _StaffDetailRepo();
    hrRepo = _HrIncidentsRepo();
    GetIt.I.registerFactory<IncidentDetailsController>(
      () => IncidentDetailsController(repository: staffRepo),
    );
    GetIt.I.registerSingleton<IncidentsRepository>(hrRepo);
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  void bigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(375, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('M03: tapping an incident opens its details like the web modal',
      (tester) async {
    bigView(tester);
    Get.put<UserSession>(
      UserSession()..applyPermissions(const ['incidents:read', 'incidents:write']),
    );
    Get.put(IncidentsController(repository: hrRepo), permanent: true);
    await tester.pumpWidget(_app(const IncidentsListPage()));
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('incident-open-inc-1')));

    expect(find.text('Incident Details'), findsWidgets);
    expect(find.text('Resident slipped near the dining room.'), findsOneWidget);
    expect(find.text('Witness statements'), findsOneWidget);
    expect(find.text('Rina Akter'), findsOneWidget);
    expect(find.text('Staff member · taken by Jamal Uddin'), findsOneWidget);
    expect(find.text('Incident summary'), findsOneWidget);
    expect(find.text('Download summary PDF'), findsOneWidget);
    expect(find.text('Acknowledge'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await _tap(tester, find.text('Close'));
    expect(find.byType(HrIncidentDetailsPage), findsNothing);
  });

  testWidgets('M03: take a statement and sign it (incidents:write)',
      (tester) async {
    bigView(tester);
    await tester.pumpWidget(
      _app(const HrIncidentDetailsPage(incidentId: 'inc-1')),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('incident-take-statement')));
    expect(find.text('Who is speaking *'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('incident-statement-save')));
    expect(hrRepo.added, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('incident-statement-name')),
      'Visitor Tom',
    );
    await tester.enterText(
      find.byKey(const ValueKey('incident-statement-text')),
      'Heard a fall and came over.',
    );
    await _tap(tester, find.byKey(const ValueKey('incident-statement-type')));
    await tester.tap(find.text('Visitor').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('incident-statement-save')));
    expect(hrRepo.added, [('visitor', 'Visitor Tom', 'Heard a fall and came over.')]);
    expect(find.text('Who is speaking *'), findsNothing);

    await _tap(tester, find.byKey(const ValueKey('incident-statement-sign-ws-1')));
    expect(hrRepo.signed, ['ws-1']);

    await _tap(tester, find.text('Acknowledge'));
    expect(staffRepo.acknowledged, ['inc-1']);
  });

  testWidgets('M03: read-only managers see Unsigned and no Edit',
      (tester) async {
    bigView(tester);
    await tester.pumpWidget(
      _app(const HrIncidentDetailsPage(incidentId: 'inc-1', canWrite: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unsigned'), findsOneWidget);
    expect(find.text('Take a statement'), findsNothing);
    expect(find.text('Sign'), findsNothing);
    expect(find.text('Edit'), findsNothing);
  });

  test('M03: witness statements parse like the web schema', () {
    final parsed = IncidentsMapper.witnessStatementsFrom({
      'data': [
        {
          'id': 'ws-1',
          'witnessType': 'resident',
          'witnessName': 'Ayaan',
          'statementText': 'It was wet.',
          'signedAt': '2026-09-29T10:00:00.000Z',
          'takenBy': {'firstName': 'Jamal', 'lastName': 'Uddin'},
        },
      ],
    });
    expect(parsed.single.subtitle, 'Resident · taken by Jamal Uddin');
    expect(parsed.single.isSigned, isTrue);
  });
}
