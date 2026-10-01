import 'dart:convert';

import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/data/mappers/medication_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/data/repositories/medication_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/domain/entities/mar_administration.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/domain/entities/mar_medication.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/domain/entities/mar_options.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/domain/entities/mar_round.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/domain/repositories/medication_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/presentation/controllers/medication_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/presentation/mar_row.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/presentation/pages/medication_page.dart';
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

Widget _app(Widget home) => ScreenUtilInit(
      designSize: const Size(ResponsiveHelper.baseWidth, ResponsiveHelper.baseHeight),
      minTextAdapt: true,
      builder: (_, _) => GetMaterialApp(
        home: home,
        theme: ThemeData(
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
      ),
    );

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) => _tap(tester, find.byKey(ValueKey(key)));

/// Scrolls the page list until [finder] is built (the side panels sit below
/// the registry).
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 400, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

Finder _inKey(String key, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: matching);

Future<void> _type(WidgetTester tester, String key, String text) async {
  final field = find.byKey(ValueKey(key));
  final input = find.descendant(of: field, matching: find.byType(TextField));
  final target = input.evaluate().isEmpty ? field : input;
  await tester.ensureVisible(target.first);
  await tester.enterText(target.first, text);
  await tester.pumpAndSettle();
}

/// Opens the select at [key] and picks [label] from its bottom sheet.
Future<void> _pick(WidgetTester tester, String key, String label) async {
  await _tapKey(tester, key);
  await _tap(
    tester,
    find.descendant(of: find.byType(ListTile), matching: find.text(label)).last,
  );
}

class _Session extends UserSession {
  final Set<String> denied;
  final String? staff;
  final bool approved;

  _Session({this.denied = const {}, this.staff, this.approved = false});

  @override
  bool can(String permission) => !denied.contains(permission);

  @override
  String? get staffId => staff;

  @override
  bool get medAdminApproved => approved;
}

// Live-shaped rows (GET /mar/round on the demo tenant), one per state.
Map<String, dynamic> _occ(
  String state, {
  String client = 'c1',
  String? medicationId,
  String? name,
  String dose = '1 tablet',
  String time = '08:00',
  bool controlled = false,
  String? administeredBy,
}) =>
    {
      'id': 'o-$state',
      'medicationId': medicationId ?? 'm-$state',
      'clientId': client,
      'clientName': client == 'c1' ? 'Ayaan Karim' : 'Nadia Islam',
      'clientAllergies': client == 'c1' ? ['Penicillin'] : <String>[],
      'residenceId': 'elm',
      'residenceName': 'Elm House',
      'name': name ?? 'Med $state',
      'dose': dose,
      'isControlled': controlled,
      'scheduledTime': time,
      'dueAt': '2026-10-01T${time.padLeft(5, '0')}:00.000Z',
      'state': state,
      'scheduled': true,
      'administrationId': state == 'given' || state == 'late' ? 'a-$state' : null,
      'administeredAt': state == 'given' || state == 'late' ? '2026-10-01T08:05:00.000Z' : null,
      'administeredBy': administeredBy,
    };

List<MarOccurrence> _occurrences() => [
      MedicationMapper.occurrenceFrom(_occ('given', administeredBy: 's1')),
      MedicationMapper.occurrenceFrom(_occ('late', client: 'c2')),
      MedicationMapper.occurrenceFrom(_occ('due', name: 'Paracetamol 500mg', time: '09:00')),
      MedicationMapper.occurrenceFrom(_occ('upcoming', name: 'Morphine 10mg', controlled: true, time: '14:00')),
      MedicationMapper.occurrenceFrom(_occ('overdue', client: 'c2', time: '07:00')),
      MedicationMapper.occurrenceFrom(_occ('missed', time: '06:00')),
      MedicationMapper.occurrenceFrom(_occ('refused', client: 'c2', time: '06:30')),
      MedicationMapper.occurrenceFrom(_occ('withheld', time: '05:00')),
      MedicationMapper.occurrenceFrom(_occ('not_available', client: 'c2', time: '05:30')),
    ];

MarMedication _medFor(MarOccurrence o) => MarMedication(
      id: o.medicationId,
      clientId: o.clientId,
      residenceId: o.residenceId,
      name: o.name,
      dose: o.dose,
      frequency: 'daily',
      times: [o.scheduledTime],
      isControlled: o.isControlled,
    );

class _FakeRepo implements MedicationRepository {
  List<MarOccurrence> occurrences = _occurrences();
  late List<MarMedication> meds = [for (final o in occurrences) _medFor(o)];
  List<MarMedication> prnList = const [
    MarMedication(id: 'p1', isPrn: true, clientId: 'c1', residenceId: 'elm', name: 'Ibuprofen 200mg', dose: '1 tablet', instructions: 'For pain'),
    MarMedication(id: 'p2', isPrn: true, clientId: '', residenceId: 'elm', name: 'Gaviscon', minIntervalMinutes: 240),
  ];
  List<MarAdministration> givenList = const [
    MarAdministration(
      id: 'a1',
      medicationName: 'Med given',
      dose: '1 tablet',
      clientName: 'Ayaan Karim',
      status: 'administered',
      administeredBy: 's1',
      administeredByName: 'Ruma Akter',
      wasLate: true,
    ),
    MarAdministration(
      id: 'a0',
      medicationName: 'Med old',
      isControlled: true,
      clientName: 'Nadia Islam',
      status: 'missed',
      supersededById: 'a1',
    ),
  ];
  final List<String> calls = [];
  final List<MarMedicineDraft> drafts = [];
  MarRoundDraft? round_;
  String? failWith;

  Future<Result<void>> _log(String call) async {
    calls.add(call);
    final error = failWith;
    return error == null ? Result.success(null) : Result.failure(ApiError(message: error));
  }

  @override
  Future<Result<MarRound>> round({String? residenceId}) async => Result.success(
        MarRound(
          occurrences: List.of(occurrences),
          summary: const MarSummary(scheduled: 9, administered: 2, unscheduled: 1, missed: 2, complianceRate: 22),
        ),
      );

  @override
  Future<Result<List<MarMedication>>> medications({String? residenceId}) async =>
      Result.success(List.of(meds));

  @override
  Future<Result<List<MarMedication>>> prnMedications({String? residenceId}) async =>
      Result.success(List.of(prnList));

  @override
  Future<Result<List<MarAdministration>>> administrations() async => Result.success(List.of(givenList));

  @override
  Future<Result<MarResidentChart>> residentChart(String clientId) async {
    calls.add('chart $clientId');
    return Result.success(
      MarResidentChart(
        allergies: const ['Penicillin'],
        buckets: {
          'morning': [occurrences.firstWhere((o) => o.state == 'due')],
          'afternoon': const [],
          'evening': const [],
          'night': const [],
        },
        prn: const [MarChartPrn(id: 'p1', name: 'Ibuprofen 200mg', minIntervalMinutes: 240, availableInMinutes: 90)],
      ),
    );
  }

  @override
  Future<Result<List<MarOption>>> residences() async =>
      Result.success(const [MarOption(id: 'elm', label: 'Elm House')]);

  @override
  Future<Result<List<MarClientOption>>> clients() async => Result.success(const [
        MarClientOption(id: 'c1', name: 'Ayaan Karim', residenceId: 'elm'),
        MarClientOption(id: 'c2', name: 'Nadia Islam', residenceId: 'elm'),
      ]);

  @override
  Future<Result<List<MarOption>>> approvedStaff() async => Result.success(const [
        MarOption(id: 's1', label: 'Ruma Akter'),
        MarOption(id: 's2', label: 'Jamal Uddin'),
      ]);

  @override
  Future<Result<List<MarOption>>> witnesses(String residenceId) async =>
      Result.success(const [MarOption(id: 's1', label: 'Ruma Akter'), MarOption(id: 's2', label: 'Jamal Uddin')]);

  @override
  Future<Result<List<MarOption>>> checkSchedules({String? clientId}) async =>
      Result.success(const [MarOption(id: 'chk1', label: 'Blood pressure')]);

  @override
  Future<Result<void>> createMedication(MarMedicineDraft draft) async {
    drafts.add(draft);
    final result = await _log('createMedication ${draft.name}');
    if (result.isSuccess) {
      final id = 'm-new-${meds.length}';
      meds = [...meds, MarMedication(id: id, clientId: draft.clientId, residenceId: draft.residenceId, name: draft.name, dose: draft.dose, times: draft.times)];
      occurrences = [
        ...occurrences,
        for (final t in draft.times)
          MarOccurrence(
            id: 'o-$id-$t',
            medicationId: id,
            clientId: draft.clientId,
            clientName: draft.clientId == 'c1' ? 'Ayaan Karim' : 'Nadia Islam',
            residenceId: draft.residenceId,
            residenceName: 'Elm House',
            name: draft.name,
            dose: draft.dose,
            scheduledTime: t,
          ),
      ];
    }
    return result;
  }

  @override
  Future<Result<void>> createMedicationBatch(List<MarMedicineDraft> list) {
    drafts.addAll(list);
    return _log('createMedicationBatch ${list.length}');
  }

  @override
  Future<Result<void>> updateMedication(String id, MarMedicineDraft draft) async {
    drafts.add(draft);
    final result = await _log('updateMedication $id');
    if (result.isSuccess) {
      occurrences = [
        for (final o in occurrences)
          o.medicationId == id
              ? MarOccurrence(
                  id: o.id,
                  medicationId: id,
                  clientId: o.clientId,
                  clientName: o.clientName,
                  residenceId: o.residenceId,
                  residenceName: o.residenceName,
                  name: draft.name,
                  dose: draft.dose,
                  scheduledTime: o.scheduledTime,
                  state: o.state,
                )
              : o,
      ];
    }
    return result;
  }

  void _drop(String id) {
    meds = meds.where((m) => m.id != id).toList();
    occurrences = occurrences.where((o) => o.medicationId != id).toList();
  }

  @override
  Future<Result<void>> discontinueMedication(String id) async {
    final result = await _log('discontinueMedication $id');
    if (result.isSuccess) _drop(id);
    return result;
  }

  @override
  Future<Result<void>> deleteMedication(String id) async {
    final result = await _log('deleteMedication $id');
    if (result.isSuccess) _drop(id);
    return result;
  }

  @override
  Future<Result<void>> createPrn(MarMedicineDraft draft) {
    drafts.add(draft);
    return _log('createPrn ${draft.name}');
  }

  @override
  Future<Result<void>> createPrnBatch(List<MarMedicineDraft> list) {
    drafts.addAll(list);
    return _log('createPrnBatch ${list.length}');
  }

  @override
  Future<Result<void>> updatePrn(String id, MarMedicineDraft draft) {
    drafts.add(draft);
    return _log('updatePrn $id');
  }

  @override
  Future<Result<void>> discontinuePrn(String id) => _log('discontinuePrn $id');

  @override
  Future<Result<void>> deletePrn(String id) async {
    final result = await _log('deletePrn $id');
    if (result.isSuccess) prnList = prnList.where((p) => p.id != id).toList();
    return result;
  }

  @override
  Future<Result<void>> chartRound(MarRoundDraft draft) {
    round_ = draft;
    return _log('chartRound ${draft.clientId} ${draft.items.length}');
  }

  @override
  Future<Result<void>> fileEvidence({
    required MarEvidenceFile file,
    required String name,
    required String clientId,
  }) =>
      _log('evidence $name $clientId');

  @override
  Future<Result<void>> amend(String administrationId, {required String reason, String? status, String? doseReason}) =>
      _log('amend $administrationId $reason $status $doseReason');

  @override
  Future<Result<List<int>>> exportMarCsv() async {
    calls.add('export');
    return Result.success(utf8.encode('Given\n'));
  }
}

final List<(String, List<int>)> _saved = [];

Future<_FakeRepo> _open(
  WidgetTester tester, {
  _FakeRepo? repo,
  Set<String> denied = const {},
  String? staffId = 's1',
  bool approved = true,
}) async {
  _tallView(tester);
  final fake = repo ?? _FakeRepo();
  final session = _Session(denied: denied, staff: staffId, approved: approved);
  GetIt.I.registerFactory<MedicationController>(
    () => MedicationController(
      repository: fake,
      session: session,
      saveFile: (name, bytes) async {
        _saved.add((name, bytes));
        return null;
      },
    ),
  );
  await tester.pumpWidget(_app(const MedicationPage()));
  await tester.pumpAndSettle();
  return fake;
}

class _FakeApi implements AppApiClient {
  final List<(String, String, Object?)> sent = [];
  final Map<String, Result<dynamic>> responses = {};

  Result<dynamic> _reply(String method, String path, Object? payload) {
    sent.add((method, path, payload));
    return responses['$method $path'] ?? Result.success({'data': <String, dynamic>{}});
  }

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) async =>
      _reply('GET', path, query);

  @override
  Future<Result<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) async =>
      _reply('POST', path, data);

  @override
  Future<Result<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) async =>
      _reply('PATCH', path, data);

  @override
  Future<Result<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) async =>
      _reply('DELETE', path, data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _draft = MarMedicineDraft(
  clientId: 'c1',
  residenceId: 'elm',
  name: ' Amoxicillin 250mg ',
  dose: '1 capsule',
  frequency: 'weekly',
  times: ['08:00', '20:00'],
  weekdays: [1, 3],
  route: 'Oral',
  startsAt: '2026-10-01',
  stockUnitsPerDose: '1',
  isControlled: false,
  requiresCheckScheduleId: 'chk1',
  requiresCheckWithinMinutes: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    _saved.clear();
    Get.reset();
    await GetIt.I.reset();
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('mapper', () {
    test('round keeps every occurrence state and the summary', () {
      final round = MedicationMapper.roundFrom({
        'success': true,
        'data': {
          'occurrences': [for (final s in ['given', 'late', 'due', 'missed', 'refused', 'withheld', 'not_available']) _occ(s)],
          'summary': {'scheduled': 7, 'administered': 2, 'unscheduled': 1, 'missed': 1, 'complianceRate': 28.6},
        },
      });
      expect(round.occurrences.map((o) => o.state),
          ['given', 'late', 'due', 'missed', 'refused', 'withheld', 'not_available']);
      expect(round.occurrences.first.allergies, ['Penicillin']);
      expect(round.occurrences.first.administrationId, 'a-given');
      expect(round.summary.complianceRate, 29);
      expect(round.summary.unscheduled, 1);
    });

    test('medication reads nested or flat schedules; rows mirror the web', () {
      final nested = MedicationMapper.medicationFrom({
        'id': 'm1',
        'clientId': 'c1',
        'residenceId': 'elm',
        'name': 'Amlodipine',
        'dose': '5mg',
        'schedule': {'frequency': 'weekly', 'times': ['08:00'], 'weekdays': [1, 4]},
        'startsAt': '2026-10-01T00:00:00.000Z',
        'requiresCheckScheduleId': 'chk1',
        'requiresCheckWithinMinutes': 30,
      });
      expect(nested.frequency, 'weekly');
      expect(nested.times, ['08:00']);
      expect(nested.weekdays, [1, 4]);
      expect(nested.startsAt, '2026-10-01');
      expect(nested.requiresCheckWithinMinutes, 30);
      expect(marScheduleLabel(nested), 'Weekly · 08:00');

      final flat = MedicationMapper.medicationFrom({
        'id': 'm2',
        'name': 'Sertraline',
        'scheduleFrequency': 'daily',
        'scheduleTimes': ['20:00'],
        'isActive': false,
      });
      expect(flat.frequency, 'daily');
      expect(flat.times, ['20:00']);
      expect(flat.isActive, isFalse);

      final row = MarRow.fromOccurrence(_occurrences().first, staffNames: const {'s1': 'Ruma Akter'});
      expect(row.statusLabel, 'Given');
      expect(row.nextDue, 'Tomorrow');
      expect(row.administeredBy, 'Ruma Akter');
      expect(row.scheduleSlot, 'Morning');

      final stock = MarRow.fromPrn(
        const MarMedication(id: 'p2', isPrn: true, residenceId: 'elm', name: 'Gaviscon'),
        clientNames: const {},
        residenceNames: const {'elm': 'Elm House'},
      );
      expect(stock.residentName, 'House stock');
      expect(stock.residentInitials, 'HS');
      expect(stock.scheduleTime, 'On request');
      expect(stock.lastAdministered, 'Never given');
      expect(stock.statusLabel, 'Available');
    });

    test('administrations, staff and checks', () {
      final a = MedicationMapper.administrationFrom({
        'id': 'a1',
        'status': 'administered',
        'medication': {'name': 'Morphine', 'dose': '10mg', 'isControlled': true},
        'client': {'firstName': 'Ayaan', 'lastName': 'Karim'},
        'administeredByStaff': {'firstName': 'Ruma', 'lastName': 'Akter'},
        'witness': {'name': 'Jamal Uddin'},
        'supersededById': 'a2',
      });
      expect(a.clientName, 'Ayaan Karim');
      expect(a.administeredByName, 'Ruma Akter');
      expect(a.witnessName, 'Jamal Uddin');
      expect(a.isSuperseded, isTrue);

      final staff = MedicationMapper.approvedStaffFrom({
        'data': [
          {'id': 's1', 'firstName': 'Ruma', 'lastName': 'Akter', 'medAdminApproved': true},
          {'id': 's3', 'firstName': 'Not', 'lastName': 'Approved', 'medAdminApproved': false},
        ],
      });
      expect(staff.map((s) => s.label), ['Ruma Akter']);

      final checks = MedicationMapper.checkSchedulesFrom({
        'data': [
          {'id': 'k1', 'name': null},
          {'id': 'k2', 'name': 'Old', 'isActive': false},
        ],
      });
      expect(checks.single.label, 'Recurring check');
    });

    test('prescription, PRN and round bodies match the web', () {
      expect(MedicationMapper.prescriptionBody(_draft), {
        'clientId': 'c1',
        'residenceId': 'elm',
        'name': 'Amoxicillin 250mg',
        'dose': '1 capsule',
        'schedule': {'frequency': 'weekly', 'times': ['08:00', '20:00'], 'weekdays': [1, 3]},
        'isControlled': false,
        'route': 'Oral',
        'startsAt': '2026-10-01T00:00:00.000Z',
        'endsAt': null,
        'stockUnitsPerDose': 1,
        'requiresCheckScheduleId': 'chk1',
        'requiresCheckWithinMinutes': 60,
      });
      final batch = MedicationMapper.prescriptionBatchBody([_draft, _draft]);
      expect(batch['items'], hasLength(2));
      expect((batch['items'] as List).first.containsKey('clientId'), isFalse);

      const prn = MarMedicineDraft(
        isPrn: true,
        residenceId: 'elm',
        name: 'Gaviscon',
        instructions: 'After meals',
        minIntervalMinutes: '240',
      );
      expect(MedicationMapper.prnBody(prn), {
        'residenceId': 'elm',
        'name': 'Gaviscon',
        'instructions': 'After meals',
        'isControlled': false,
        'minIntervalMinutes': 240,
        'stockUnitsPerDose': null,
        'startsAt': null,
        'endsAt': null,
        'requiresCheckScheduleId': null,
        'requiresCheckWithinMinutes': 60,
      });
      // The API answers 400 to `route: null`.
      expect(MedicationMapper.prnBody(prn, update: true)['route'], '');
      const noRoute = MarMedicineDraft(clientId: 'c1', residenceId: 'elm', name: 'Paracetamol', times: ['08:00']);
      expect(MedicationMapper.prescriptionBody(noRoute).containsKey('route'), isFalse);
      expect(MedicationMapper.prescriptionBody(noRoute, update: true)['route'], '');
      expect(
        (MedicationMapper.prescriptionBatchBody([noRoute])['items'] as List).single,
        isNot(contains('route')),
      );
      final prnBatch = MedicationMapper.prnBatchBody([prn, prn]);
      expect(prnBatch.containsKey('clientId'), isFalse);
      expect((prnBatch['items'] as List).first.containsKey('residenceId'), isFalse);

      final body = MedicationMapper.roundBody(
        MarRoundDraft(
          clientId: 'c1',
          residenceId: 'elm',
          staffId: 's1',
          administeredAt: DateTime.utc(2026, 10, 1, 9, 5),
          safetyChecks: const {'safetyConfirmed': true, 'identityVerified': false},
          vitals: const {'bloodPressure': '120/80', 'heartRate': ' '},
          items: const [
            MarRoundItem(medicationId: 'm1', witnessStaffId: 's2', clinicalNotes: ' calm '),
            MarRoundItem(recordType: 'PRN', medicationId: 'p1', status: 'refused', doseReason: 'patient_refused'),
          ],
        ),
      );
      expect(body, {
        'clientId': 'c1',
        'residenceId': 'elm',
        'staffId': 's1',
        'administeredAt': '2026-10-01T09:05:00.000Z',
        'items': [
          {
            'source': 'prescribed',
            'medicationId': 'm1',
            'status': 'administered',
            'witnessStaffId': 's2',
            'clinicalNotes': 'calm',
            'safetyChecks': {'safetyConfirmed': true, 'identityVerified': false},
            'vitals': {'bloodPressure': '120/80'},
          },
          {
            'source': 'prn',
            'prnMedicationId': 'p1',
            'status': 'refused',
            'reason': 'patient_refused',
          },
        ],
      });
    });

    test('local CSV escapes cells', () {
      final csv = MedicationMapper.csvFrom([
        {
          'administeredAt': '2026-10-01T08:05:00.000Z',
          'status': 'administered',
          'medication': {'name': 'Paracetamol, 500mg'},
          'client': {'name': 'Ayaan "AK" Karim'},
        },
      ]);
      expect(
        csv.split('\n')[1],
        '2026-10-01T08:05:00.000Z,"Ayaan ""AK"" Karim","Paracetamol, 500mg",,administered,,,',
      );
    });
  });

  group('repository', () {
    test('reads fetch every page-1 row with limit 100; residence is optional', () async {
      final api = _FakeApi();
      final repo = MedicationRepositoryImpl(api: api);
      await repo.round();
      expect(api.sent.last.$2, '/mar/round');
      expect(api.sent.last.$3, isEmpty);
      await repo.medications(residenceId: 'elm');
      expect(api.sent.last.$2, '/medications');
      expect(api.sent.last.$3, {'page': 1, 'limit': 100, 'residenceId': 'elm'});
      await repo.prnMedications();
      expect(api.sent.last.$3, {'page': 1, 'limit': 100});
      await repo.administrations();
      expect(api.sent.last.$2, '/mar/administrations');
      await repo.residentChart('c1');
      expect(api.sent.last.$2, '/mar/residents/c1/chart');
      await repo.witnesses('elm');
      expect(api.sent.last.$2, '/mar/witnesses');
      expect(api.sent.last.$3, {'residenceId': 'elm'});
      await repo.checkSchedules(clientId: 'c1');
      expect(api.sent.last.$2, '/recurring-checks/schedules');
    });

    test('writes hit the web paths', () async {
      final api = _FakeApi();
      final repo = MedicationRepositoryImpl(api: api);
      await repo.createMedication(_draft);
      await repo.createMedicationBatch([_draft]);
      await repo.updateMedication('m1', _draft);
      await repo.discontinueMedication('m1');
      await repo.deleteMedication('m1');
      await repo.createPrn(_draft);
      await repo.createPrnBatch([_draft]);
      await repo.updatePrn('p1', _draft);
      await repo.discontinuePrn('p1');
      await repo.deletePrn('p1');
      await repo.chartRound(const MarRoundDraft(clientId: 'c1', residenceId: 'elm', staffId: 's1', items: [MarRoundItem(medicationId: 'm1')]));
      await repo.amend('a1', reason: 'Wrong resident', status: 'missed');
      expect(api.sent.map((s) => '${s.$1} ${s.$2}'), [
        'POST /medications',
        'POST /medications/batch',
        'PATCH /medications/m1',
        'POST /medications/m1/discontinue',
        'DELETE /medications/m1',
        'POST /prn-medications',
        'POST /prn-medications/batch',
        'PATCH /prn-medications/p1',
        'POST /prn-medications/p1/discontinue',
        'DELETE /prn-medications/p1',
        'POST /mar/administrations/round',
        'POST /mar/administrations/a1/amendments',
      ]);
      expect(api.sent.last.$3, {'reason': 'Wrong resident', 'status': 'missed'});
    });

    test('export falls back to a local CSV when the report export is refused', () async {
      final api = _FakeApi()
        ..responses['POST /reports/exports'] = Result.failure(const ApiError(message: 'Forbidden'))
        ..responses['GET /mar/administrations'] = Result.success({
          'data': [
            {'status': 'administered', 'medication': {'name': 'Paracetamol'}, 'client': {'name': 'Ayaan Karim'}},
          ],
          'meta': {'totalPages': 1},
        });
      final repo = MedicationRepositoryImpl(api: api, pollInterval: Duration.zero);
      final result = await repo.exportMarCsv();
      expect(api.sent.first.$3, {'reportKey': 'mar_administrations', 'format': 'csv'});
      final csv = utf8.decode(result.value!);
      expect(csv, startsWith('Given,Resident,Medicine'));
      expect(csv, contains('Paracetamol'));
    });
  });

  group('page', () {
    testWidgets('lists every dose on the round, whatever its state (M07/M08)', (tester) async {
      await _open(tester);
      expect(find.text('Medication Administration Record (MAR)'), findsOneWidget);
      expect(find.byKey(const ValueKey('mar-kpi-scheduled')), findsOneWidget);
      expect(find.text('MAR (9)'), findsOneWidget);
      for (final label in ['GIVEN', 'GIVEN LATE', 'DUE NOW', 'UPCOMING', 'OVERDUE', 'MISSED', 'REFUSED', 'WITHHELD', 'NOT AVAILABLE']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(_inKey('mar-row-o-given', find.text('Ruma Akter')), findsOneWidget);
      await _scrollTo(tester, find.byKey(const ValueKey('mar-alerts')));
      expect(find.text('Due Now'), findsOneWidget);
      expect(find.text('2 pending'), findsOneWidget);
      expect(find.text('3 alerts'), findsOneWidget);
    });

    testWidgets('a medicine added in the app shows right after saving (M08)', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-add-medicine');
      expect(find.text('Add a medicine'), findsOneWidget);

      await _tapKey(tester, 'mar-form-submit');
      expect(find.text('What is the medicine called?'), findsOneWidget);

      await _pick(tester, 'mar-form-house', 'Elm House');
      await _pick(tester, 'mar-form-resident', 'Nadia Islam');
      await _type(tester, 'mar-form-name', 'Amoxicillin 250mg');
      await _type(tester, 'mar-form-dose', '1 capsule');
      await _type(tester, 'mar-form-time-input', '12:00');
      await _tapKey(tester, 'mar-form-submit');

      expect(repo.calls, contains('createMedication Amoxicillin 250mg'));
      final draft = repo.drafts.last;
      expect(draft.clientId, 'c2');
      expect(draft.residenceId, 'elm');
      expect(draft.times, ['12:00']);
      expect(find.text('Add a medicine'), findsNothing);
      expect(find.text('Prescription added'), findsOneWidget);
      expect(find.text('MAR (10)'), findsOneWidget);
      expect(find.text('Amoxicillin 250mg'), findsWidgets);
    });

    testWidgets('a PRN added from the PRN tab lands on the PRN register', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-tab-prn');
      expect(find.text('PRN Medication Registry'), findsOneWidget);
      expect(_inKey('mar-row-p2', find.text('House stock')), findsOneWidget);
      await _tapKey(tester, 'mar-add-medicine');
      expect(find.text('Add a PRN medicine'), findsOneWidget);
      await _pick(tester, 'mar-form-house', 'Elm House');
      await _type(tester, 'mar-form-name', 'Senna');
      await _type(tester, 'mar-form-gap', '240');
      await _tapKey(tester, 'mar-form-add-another');
      expect(find.text('1 medicine added'), findsOneWidget);
      await _type(tester, 'mar-form-name', 'Lactulose');
      expect(find.text('Add 2 medicines'), findsOneWidget);
      await _tapKey(tester, 'mar-form-submit');
      expect(repo.calls, contains('createPrnBatch 2'));
      expect(repo.drafts.first.minIntervalMinutes, '240');
      expect(find.text('2 medicines added'), findsOneWidget);
    });

    testWidgets('editing a prescription refreshes the same row at once (M07)', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-edit-o-due');
      expect(find.text('Correct a medicine'), findsOneWidget);
      expect(find.text('Moving a medicine between houses is not an edit.'), findsOneWidget);
      expect(find.byKey(const ValueKey('mar-form-kind-prn')), findsNothing);

      await _type(tester, 'mar-form-dose', '2 tablets');
      await _tapKey(tester, 'mar-form-submit');

      expect(repo.calls, contains('updateMedication m-due'));
      final draft = repo.drafts.last;
      expect(draft.name, 'Paracetamol 500mg');
      expect(draft.dose, '2 tablets');
      expect(draft.times, ['09:00']);
      expect(find.text('Prescription updated'), findsOneWidget);
      expect(_inKey('mar-row-o-due', find.text('2 tablets')), findsOneWidget);
    });

    testWidgets('discontinue confirms with the web copy and drops the row', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-discontinue-o-due');
      expect(find.text('Stop giving Paracetamol 500mg?'), findsOneWidget);
      await _tapKey(tester, 'mar-confirm');
      expect(repo.calls, contains('discontinueMedication m-due'));
      expect(find.text('Discontinued — it stays on file'), findsOneWidget);
      expect(find.byKey(const ValueKey('mar-row-o-due')), findsNothing);
    });

    testWidgets('delete on the PRN tab removes it from the PRN register', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-tab-prn');
      await _tapKey(tester, 'mar-delete-p1');
      expect(find.text('Delete this prescription?'), findsOneWidget);
      await _tapKey(tester, 'mar-confirm');
      expect(repo.calls, contains('deletePrn p1'));
      expect(find.text('Prescription deleted'), findsOneWidget);
      expect(find.byKey(const ValueKey('mar-row-p1')), findsNothing);
    });

    testWidgets('a row whose prescription is not loaded says so', (tester) async {
      final repo = _FakeRepo();
      repo.meds = [for (final o in repo.occurrences) _medFor(o)];
      repo.occurrences = [
        ...repo.occurrences,
        MedicationMapper.occurrenceFrom(_occ('upcoming', medicationId: 'm-gone', name: 'Orphan')..['id'] = 'o-orphan'),
      ];
      await _open(tester, repo: repo);
      await _tapKey(tester, 'mar-edit-o-orphan');
      expect(find.text(MedicationController.notInList), findsOneWidget);
      expect(find.text('Correct a medicine'), findsNothing);
    });

    testWidgets('without mar:write only View and Export remain', (tester) async {
      await _open(tester, denied: {'mar:write'}, staffId: null, approved: false);
      expect(find.byKey(const ValueKey('mar-add-medicine')), findsNothing);
      expect(find.byKey(const ValueKey('mar-record-administration')), findsNothing);
      expect(find.byKey(const ValueKey('mar-export')), findsOneWidget);
      expect(find.byKey(const ValueKey('mar-view-o-due')), findsOneWidget);
      expect(find.byKey(const ValueKey('mar-edit-o-due')), findsNothing);
      expect(find.byKey(const ValueKey('mar-chart-o-due')), findsNothing);
      expect(find.byKey(const ValueKey('mar-due-record-o-due')), findsNothing);
    });

    testWidgets('without approval or mar:manage charting is disabled', (tester) async {
      await _open(tester, denied: {'mar:manage'}, staffId: null, approved: false);
      expect(find.byKey(const ValueKey('mar-edit-o-due')), findsOneWidget);
      expect(find.byKey(const ValueKey('mar-chart-o-due')), findsNothing);
      await _tapKey(tester, 'mar-record-administration');
      expect(find.text('Choose who this round is for, then add every medicine being given.'), findsNothing);
      expect(
        find.byTooltip('Medication administration is restricted to approved staff'),
        findsWidgets,
      );
    });

    testWidgets('without mar:read nothing loads', (tester) async {
      final repo = await _open(tester, denied: {'mar:read'});
      expect(find.text('You do not have permission to view the medication record.'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('Record administration charts the round from a row', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-chart-o-due');
      expect(find.text('Fixed to the dose this was opened on.'), findsOneWidget);
      expect(find.text('Ayaan Karim has recorded allergies: Penicillin'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      await _tapKey(tester, 'mar-wizard-next');
      expect(find.text('Pre-administration verification'), findsOneWidget);
      await _tapKey(tester, 'mar-wizard-safety-confirmed');
      await _tapKey(tester, 'mar-wizard-check-identityVerified');
      await _type(tester, 'mar-wizard-vital-bloodPressure', '118/76');
      await _tapKey(tester, 'mar-wizard-next');
      expect(find.text('Final Review Checklist'), findsOneWidget);
      await _type(tester, 'mar-wizard-notes-0', 'Taken with water');
      await _tapKey(tester, 'mar-wizard-complete');

      final draft = repo.round_!;
      expect(draft.clientId, 'c1');
      expect(draft.residenceId, 'elm');
      expect(draft.staffId, 's1');
      expect(draft.administeredAt!.isUtc, isTrue);
      expect(draft.items.single.medicationId, 'm-due');
      expect(draft.items.single.notes, 'Taken with water');
      expect(draft.safetyChecks['safetyConfirmed'], isTrue);
      expect(draft.safetyChecks['identityVerified'], isTrue);
      expect(draft.vitals['bloodPressure'], '118/76');
      expect(find.text('Dose recorded'), findsOneWidget);
    });

    testWidgets('a controlled drug needs a witness other than the giver', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-chart-o-upcoming');
      expect(find.text('Yes — witness required'), findsOneWidget);
      await _tapKey(tester, 'mar-wizard-next');
      expect(find.text('A controlled drug needs a witness'), findsOneWidget);
      await _pick(tester, 'mar-wizard-witness-0', 'Jamal Uddin');
      await _tapKey(tester, 'mar-wizard-next');
      await _tapKey(tester, 'mar-wizard-next');
      await _tapKey(tester, 'mar-wizard-complete');
      expect(repo.round_!.items.single.witnessStaffId, 's2');
    });

    testWidgets('the blank wizard asks for a resident, then scopes medicines to them', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-record-administration');
      await _tapKey(tester, 'mar-wizard-next');
      expect(find.text('Choose the resident this round is for'), findsOneWidget);

      await _pick(tester, 'mar-wizard-resident', 'Nadia Islam');
      await _tapKey(tester, 'mar-wizard-med-0');
      expect(find.descendant(of: find.byType(ListTile), matching: find.text('Med late — 1 tablet')), findsOneWidget);
      expect(find.descendant(of: find.byType(ListTile), matching: find.text('Paracetamol 500mg — 1 tablet')), findsNothing);
      expect(find.descendant(of: find.byType(ListTile), matching: find.text('Gaviscon (PRN)')), findsOneWidget);
      await _tap(tester, find.descendant(of: find.byType(ListTile), matching: find.text('Gaviscon (PRN)')));
      await _tapKey(tester, 'mar-wizard-status-0-refused');
      await _tapKey(tester, 'mar-wizard-next');
      expect(find.text('Say why this dose was not given'), findsOneWidget);
      await _pick(tester, 'mar-wizard-reason-0', 'Resident refused');
      await _tapKey(tester, 'mar-wizard-next');
      await _tapKey(tester, 'mar-wizard-next');
      await _tapKey(tester, 'mar-wizard-complete');
      final item = repo.round_!.items.single;
      expect(item.isPrn, isTrue);
      expect(item.medicationId, 'p2');
      expect(item.status, 'refused');
      expect(item.doseReason, 'patient_refused');
    });

    testWidgets('Given tab flags and Correct', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-tab-given');
      expect(find.text('After its round'), findsOneWidget);
      expect(find.text('Superseded by a later correction'), findsOneWidget);
      expect(find.byKey(const ValueKey('mar-correct-a0')), findsNothing);

      await _tapKey(tester, 'mar-correct-a1');
      expect(find.text('Correct this record'), findsOneWidget);
      await _tapKey(tester, 'mar-correct-submit');
      expect(find.text('Say what was wrong — a corrected drug chart needs a reason.'), findsOneWidget);

      await _type(tester, 'mar-correct-reason', 'Charted against the wrong round');
      await _pick(tester, 'mar-correct-outcome', 'Missed');
      await _tapKey(tester, 'mar-correct-submit');
      expect(find.text('Say why the dose was not given.'), findsOneWidget);
      await _pick(tester, 'mar-correct-dose-reason', 'Resident asleep');
      await _tapKey(tester, 'mar-correct-submit');
      expect(repo.calls, contains('amend a1 Charted against the wrong round missed resident_asleep'));
      expect(find.text('Correction recorded. The original stays on the chart.'), findsOneWidget);
    });

    testWidgets('Resident chart shows one person\'s day', (tester) async {
      final repo = await _open(tester);
      await _tapKey(tester, 'mar-tab-chart');
      expect(find.text("A chart is one person's day."), findsOneWidget);
      await _pick(tester, 'mar-chart-resident', 'Ayaan Karim');
      expect(repo.calls, contains('chart c1'));
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Nothing due.'), findsNWidgets(3));
      expect(find.text('Available in 1h 30m'), findsOneWidget);
      expect(find.text('Penicillin'), findsOneWidget);
    });

    testWidgets('Review All narrows the registry to overdue doses; Export MAR saves', (tester) async {
      final repo = await _open(tester);
      await _scrollTo(tester, find.byKey(const ValueKey('mar-review-all')));
      await _tapKey(tester, 'mar-review-all');
      expect(find.byKey(const ValueKey('mar-row-o-overdue')), findsOneWidget);
      expect(find.byKey(const ValueKey('mar-row-o-due')), findsNothing);
      await _tapKey(tester, 'mar-filter-clear');
      expect(find.byKey(const ValueKey('mar-row-o-due')), findsOneWidget);

      await _tapKey(tester, 'mar-export');
      expect(repo.calls, contains('export'));
      expect(_saved.single.$1, 'mar_administrations.csv');
      expect(find.text('Export ready'), findsOneWidget);
    });

    testWidgets('a failed save stays open with the error', (tester) async {
      final repo = await _open(tester);
      repo.failWith = 'Name is required';
      await _tapKey(tester, 'mar-edit-o-due');
      await _tapKey(tester, 'mar-form-submit');
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Correct a medicine'), findsOneWidget);
      expect(repo.calls, contains('updateMedication m-due'));
    });
  });
}
