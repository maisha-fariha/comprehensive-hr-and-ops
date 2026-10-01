import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/data/mappers/staff_medication_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/administered_dose.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/due_dose.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_client_medication_item.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_med_options.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_medication_enums.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_medication_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/repositories/staff_medication_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/presentation/controllers/staff_medication_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/presentation/pages/staff_medication_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/presentation/widgets/staff_record_administration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

const _residenceId = '4c134b43-d345-4b53-8043-1074e1a2cfba';
const _clientId = 'b9f85d33-2a2e-4fac-ad4b-83e24e8a4af9';
const _napaId = 'f225bdf1-7189-4dda-ae17-903032fccfd0';
const _staffId = 'dc3251c3-c2c4-4084-b1c8-f83fd6012fda';

/// QA's web screenshot: Client One / Napa at Cozzy Cottage — Morning 03:30
/// OVERDUE and an unscheduled GIVEN dose.
Map<String, dynamic> _occurrence({
  required String id,
  String medicationId = _napaId,
  String name = 'Napa',
  String dose = '500',
  String scheduledTime = '03:30',
  String dueAt = '2026-09-30T03:30:00.000Z',
  String state = 'overdue',
  bool scheduled = true,
  String? administrationId,
  String? administeredAt,
}) =>
    {
      'id': id,
      'medicationId': medicationId,
      'clientId': _clientId,
      'clientName': 'Client One',
      'residenceId': _residenceId,
      'residenceName': 'Cozzy Cottege',
      'name': name,
      'dose': dose,
      'scheduledTime': scheduledTime,
      'dueAt': dueAt,
      'state': state,
      'scheduled': scheduled,
      'administrationId': administrationId,
      'administeredAt': administeredAt,
      'administeredBy': administrationId == null ? null : _staffId,
    };

Map<String, dynamic> _medicationJson({
  String id = _napaId,
  String name = 'Napa',
  String dose = '500',
  String? route = 'oral',
  List<String> times = const ['03:30'],
}) =>
    {
      'id': id,
      'clientId': _clientId,
      'residenceId': _residenceId,
      'name': name,
      'dose': dose,
      'route': route,
      'startsAt': '2026-09-30T00:00:00.000Z',
      'endsAt': '2026-10-01T00:00:00.000Z',
      'scheduleFrequency': 'daily',
      'scheduleTimes': times,
      'scheduleWeekdays': <int>[],
      'isControlled': false,
      'requiresCheckScheduleId': null,
      'isActive': true,
      'schedule': {'frequency': 'daily', 'times': times, 'weekdays': <int>[]},
    };

class _FakeRepo implements StaffMedicationRepository {
  final List<Map<String, dynamic>> occurrences = [
    _occurrence(id: 'occ-1'),
    _occurrence(
      id: 'occ-2',
      scheduledTime: '15:31',
      dueAt: '2026-09-30T09:31:00.000Z',
      state: 'given',
      scheduled: false,
      administrationId: 'adm-1',
      administeredAt: '2026-09-30T09:31:00.000Z',
    ),
  ];
  final List<Map<String, dynamic>> medicationRows = [_medicationJson()];
  final List<Map<String, dynamic>> prnRows = [];

  final List<String?> overviewResidenceIds = [];
  final List<(String, StaffCreateMedicationInput)> updatedMedications = [];
  final List<StaffCreateMedicationInput> createdMedications = [];
  final List<StaffCreatePrnMedicationInput> createdPrns = [];

  @override
  Future<Result<StaffMedicationOverview>> getOverview({
    String? residenceId,
  }) async {
    overviewResidenceIds.add(residenceId);
    final rows = [
      for (final o in occurrences)
        if (residenceId == null || o['residenceId'] == residenceId) o,
    ];
    return Result.success(
      StaffMedicationMapper.fromRound({
        'success': true,
        'data': {
          'occurrences': rows,
          'summary': {
            'scheduled': rows.where((o) => o['scheduled'] == true).length,
            'administered': 1,
            'unscheduled': 1,
            'due': 0,
            'missed': 0,
            'refused': 0,
          },
        },
      }),
    );
  }

  @override
  Future<Result<List<StaffClientMedicationItem>>> listMedications({
    String? residenceId,
    String? clientId,
  }) async =>
      Result.success(
        StaffMedicationMapper.clientMedicationsFrom(medicationRows, isPrn: false),
      );

  @override
  Future<Result<List<StaffClientMedicationItem>>> listPrnMedications({
    String? residenceId,
  }) async =>
      Result.success(
        StaffMedicationMapper.clientMedicationsFrom(prnRows, isPrn: true),
      );

  @override
  Future<Result<List<AdministeredDose>>> listAdministrations({
    String? residenceId,
    int page = 1,
    int limit = 50,
  }) async =>
      Result.success(
        StaffMedicationMapper.administrationsFrom([
          {
            'id': 'adm-1',
            'medication': {'id': _napaId, 'name': 'Napa', 'dose': '500'},
            'client': {'id': _clientId, 'name': 'Client One'},
            'residenceId': _residenceId,
            'administeredByStaff': {'id': _staffId, 'name': 'Abir Hasan'},
            'administeredAt': '2026-09-30T09:31:00.000Z',
            'status': 'administered',
          },
        ]),
      );

  @override
  Future<Result<List<StaffClientMedicationItem>>> getClientMedications(
    String clientId,
  ) async =>
      Result.success(
        StaffMedicationMapper.clientMedicationsFrom([
          _medicationJson(id: 'med-ooo', name: 'Ooo', dose: '45'),
          ...medicationRows,
        ], isPrn: false),
      );

  @override
  Future<Result<List<StaffClientMedicationItem>>> getClientPrnMedications(
    String clientId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<StaffMedResidenceOption>>> getResidences() async =>
      Result.success(const [
        StaffMedResidenceOption(id: _residenceId, name: 'Cozzy Cottege'),
      ]);

  @override
  Future<Result<List<StaffMedClientOption>>> getClients({
    String? residenceId,
    String? search,
  }) async =>
      Result.success(const [
        StaffMedClientOption(
          id: _clientId,
          name: 'Client One',
          residenceId: _residenceId,
          residenceName: 'Cozzy Cottege',
        ),
      ]);

  @override
  Future<Result<List<StaffMedCheckOption>>> getCheckSchedules({
    String? residenceId,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<void>> createMedication(StaffCreateMedicationInput input) async {
    createdMedications.add(input);
    final id = 'med-new-${createdMedications.length}';
    medicationRows.add(
      _medicationJson(
        id: id,
        name: input.name,
        dose: input.dose ?? '',
        times: input.scheduleTimes,
      ),
    );
    occurrences.add(
      _occurrence(
        id: 'occ-$id',
        medicationId: id,
        name: input.name,
        dose: input.dose ?? '',
        scheduledTime: input.scheduleTimes.first,
        state: 'upcoming',
      ),
    );
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateMedication(
    String id,
    StaffCreateMedicationInput input,
  ) async {
    updatedMedications.add((id, input));
    for (final o in occurrences) {
      if (o['medicationId'] == id) {
        o['name'] = input.name;
        o['dose'] = input.dose ?? '';
      }
    }
    final index = medicationRows.indexWhere((m) => m['id'] == id);
    medicationRows[index] = _medicationJson(
      id: id,
      name: input.name,
      dose: input.dose ?? '',
      route: input.route,
      times: input.scheduleTimes,
    );
    return Result.success(null);
  }

  @override
  Future<Result<void>> createPrnMedication(
    StaffCreatePrnMedicationInput input,
  ) async {
    createdPrns.add(input);
    prnRows.add({
      'id': 'prn-${createdPrns.length}',
      'residenceId': input.residenceId,
      'clientId': input.clientId,
      'name': input.name,
      'dose': input.dose,
      'instructions': input.instructions,
      'isActive': true,
    });
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePrnMedication(
    String id,
    StaffCreatePrnMedicationInput input,
  ) async =>
      Result.success(null);

  @override
  Future<Result<void>> recordAdministration({
    required String clientId,
    required String residenceId,
    required String medicationId,
    required String status,
    String? notes,
    String? clinicalNotes,
    String? doseReason,
    String? witnessStaffId,
    bool isPrn = false,
    Map<String, bool>? safetyChecks,
    Map<String, String>? vitals,
  }) async =>
      Result.success(null);
}

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

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );

final _houseField = find.byType(DropdownButtonFormField<StaffMedResidenceOption>);
final _residentField =
    find.byType(DropdownButtonFormField<StaffMedClientOption?>);

Future<void> _settleSnackbars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  late _FakeRepo repo;
  late UserSession session;

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
    session = UserSession()
      ..signIn(
        role: UserRole.staff,
        displayName: 'Abir Hasan',
        email: 'xirob96224@meonvr.com',
      )
      ..applyPermissions(const ['mar:read', 'mar:write'])
      ..applyStaffContext(staffId: _staffId);
    Get.put(session, permanent: true);
    repo = _FakeRepo();
    GetIt.I.registerSingleton<StaffMedicationRepository>(repo);
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  Future<StaffMedicationController> pumpPage(WidgetTester tester) async {
    _tallView(tester);
    final controller =
        StaffMedicationController(repository: repo, session: session);
    Get.put(controller);
    await tester.pumpWidget(_wrap(const StaffMedicationPage()));
    await tester.pumpAndSettle();
    return controller;
  }

  test('round mapper keeps every occurrence as a web registry row', () {
    final overview = StaffMedicationMapper.fromRound({
      'data': {
        'occurrences': repo.occurrences,
        'summary': {'scheduled': 1, 'administered': 1, 'unscheduled': 1},
      },
    });
    final rows = overview.registryDoses;
    expect(rows, hasLength(2));
    expect(rows[0].state, 'overdue');
    expect(rows[0].timeLabel, '03:30');
    expect(rows[0].slotLabel, 'Morning');
    expect(rows[0].residenceName, 'Cozzy Cottege');
    expect(rows[1].state, 'given');
    expect(rows[1].status, DueDoseStatus.administered);
    expect(rows[1].scheduled, isFalse);
    expect(rows[1].timeLabel, 'Unscheduled');
    expect(rows[1].administrationId, 'adm-1');
    expect(overview.scheduledCount, 1);
  });

  testWidgets(
    'S08: MAR shows both web rows and every registry filter opens, '
    'selects, filters and clears',
    (tester) async {
      final controller = await pumpPage(tester);

      expect(controller.marTabCount, 2);
      expect(find.text('2 scheduled today'), findsOneWidget);
      expect(find.byKey(const ValueKey('staff-mar-state-occ-1')), findsOneWidget);
      expect(find.text('OVERDUE'), findsOneWidget);
      expect(find.text('GIVEN'), findsOneWidget);
      expect(find.text('Unscheduled'), findsOneWidget);
      expect(
        find.textContaining('by Abir Hasan', findRichText: true),
        findsOneWidget,
      );

      // Residence: options from the user's residences.
      await tester.tap(find.byKey(const ValueKey('staff-mar-filter-residence')));
      await tester.pumpAndSettle();
      expect(_inSheet('All residences'), findsOneWidget);
      expect(_inSheet('Cozzy Cottege'), findsOneWidget);
      await tester.tap(_inSheet('Cozzy Cottege'));
      await tester.pumpAndSettle();
      expect(controller.filterResidenceId.value, _residenceId);
      expect(repo.overviewResidenceIds.last, _residenceId);
      expect(controller.marTabCount, 2);

      // Resident: options from the loaded rows.
      await tester.tap(find.byKey(const ValueKey('staff-mar-filter-resident')));
      await tester.pumpAndSettle();
      expect(_inSheet('All residents'), findsOneWidget);
      await tester.tap(_inSheet('Client One'));
      await tester.pumpAndSettle();
      expect(controller.filterClientId.value, _clientId);

      // Medicine: options from the loaded rows.
      await tester.tap(find.byKey(const ValueKey('staff-mar-filter-medicine')));
      await tester.pumpAndSettle();
      expect(_inSheet('All medicines'), findsOneWidget);
      await tester.tap(_inSheet('Napa'));
      await tester.pumpAndSettle();
      expect(controller.filterMedication.value, 'Napa');

      // Status: web labels; "Given" matches the unscheduled given dose.
      await tester.tap(find.byKey(const ValueKey('staff-mar-filter-status')));
      await tester.pumpAndSettle();
      for (final label in const [
        'Any status',
        'Given',
        'Given late',
        'Due now',
        'Upcoming',
        'Overdue',
        'Missed',
        'Refused',
        'Withheld',
        'Not available',
      ]) {
        expect(_inSheet(label), findsOneWidget, reason: label);
      }
      await tester.tap(_inSheet('Given'));
      await tester.pumpAndSettle();
      expect(controller.filteredScheduledDoses.single.id, 'occ-2');
      expect(find.text('1 scheduled today'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('staff-mar-filter-clear')));
      await tester.pumpAndSettle();
      expect(controller.hasActiveFilters, isFalse);
      expect(repo.overviewResidenceIds.last, isNull);
      expect(find.text('2 scheduled today'), findsOneWidget);
    },
  );

  testWidgets(
    'S09: editing a prescription shows the updated row in the same list',
    (tester) async {
      await pumpPage(tester);
      expect(find.text('Napa 500'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('staff-mar-edit-occ-1')));
      await tester.pumpAndSettle();
      expect(find.text('Correct a medicine'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Napa'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, '500'), '650');
      await tester.enterText(find.widgetWithText(TextField, 'oral'), '');
      await tester.tap(find.byKey(const Key('staff-mar-add-medicine-save')));
      await tester.pumpAndSettle();

      final (id, input) = repo.updatedMedications.single;
      expect(id, _napaId);
      expect(input.dose, '650');
      expect(input.route, isNull);
      expect(input.scheduleTimes, ['03:30']);
      expect(input.residenceId, _residenceId);
      expect(input.clientId, _clientId);

      expect(find.text('Correct a medicine'), findsNothing);
      expect(find.text('Napa 650'), findsNWidgets(2));
      expect(find.text('Napa 500'), findsNothing);
      await _settleSnackbars(tester);
    },
  );

  testWidgets(
    'S10: an added medicine appears in the MAR list right after saving',
    (tester) async {
      final controller = await pumpPage(tester);

      await tester.tap(find.text('Add medicine'));
      await tester.pumpAndSettle();
      expect(find.text('Add a medicine'), findsOneWidget);

      await tester.tap(_houseField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cozzy Cottege').last);
      await tester.pumpAndSettle();

      await tester.tap(_residentField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Client One').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Paracetamol 500mg'),
        'Calpol',
      );
      await tester.enterText(find.widgetWithText(TextField, '1 tablet'), '5ml');
      await tester.tap(find.byKey(const Key('staff-mar-add-medicine-save')));
      await tester.pumpAndSettle();

      final created = repo.createdMedications.single;
      expect(created.name, 'Calpol');
      expect(created.residenceId, _residenceId);
      expect(created.clientId, _clientId);
      expect(created.route, isNull);
      expect(created.scheduleTimes, ['08:00']);

      expect(find.text('Add a medicine'), findsNothing);
      expect(controller.marTabCount, 3);
      expect(find.text('Calpol 5ml'), findsOneWidget);
      expect(find.text('3 scheduled today'), findsOneWidget);
      await _settleSnackbars(tester);
    },
  );

  testWidgets('S10: an added PRN medicine appears on the PRN tab', (tester) async {
    final controller = await pumpPage(tester);

    await tester.tap(find.text('Add medicine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PRN Medicine'));
    await tester.pumpAndSettle();
    expect(find.text('Add a PRN medicine'), findsOneWidget);

    await tester.tap(_houseField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cozzy Cottege').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Paracetamol 500mg'),
      'Ibuprofen',
    );
    await tester.tap(find.byKey(const Key('staff-mar-add-medicine-save')));
    await tester.pumpAndSettle();

    expect(repo.createdPrns.single.name, 'Ibuprofen');
    expect(repo.createdPrns.single.route, isNull);
    expect(controller.prnTabCount, 1);

    controller.selectTab(StaffMedicationTab.prn);
    await tester.pumpAndSettle();
    expect(find.text('Ibuprofen'), findsOneWidget);
    await _settleSnackbars(tester);
  });

  testWidgets(
    'Record administration dropdowns keep the preselected medicine and list '
    "the resident's chart",
    (tester) async {
      _tallView(tester);
      const dose = DueDose(
        id: 'occ-1',
        residentName: 'Client One',
        residentInitials: 'CO',
        avatarColor: AvatarPalette.blue,
        medicationName: 'Napa',
        dose: '500',
        route: MedicationRoute.tabletOral,
        timeLabel: '03:30',
        section: DueDoseSection.dueNow,
        clientId: _clientId,
        residenceId: _residenceId,
        medicationId: _napaId,
      );
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => StaffRecordAdministrationDialog.show(
                    context,
                    clients: const [
                      StaffMedClientOption(id: _clientId, name: 'Client One'),
                    ],
                    preselectedDose: dose,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Napa · 500'), findsOneWidget);

      await tester.tap(find.text('Napa · 500'));
      await tester.pumpAndSettle();
      expect(find.text('Ooo · 45'), findsWidgets);
      await tester.tap(find.text('Ooo · 45').last);
      await tester.pumpAndSettle();
      expect(find.text('Ooo · 45'), findsOneWidget);
      expect(find.text('Napa · 500'), findsNothing);

      await tester.tap(find.text('Client One').first);
      await tester.pumpAndSettle();
      expect(find.text('Client One'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
