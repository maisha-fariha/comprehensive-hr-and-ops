import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/api_endpoints.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/network/tenant_store.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/appointments/domain/entities/staff_appointment.dart';
import 'package:comprehensive_hr_and_ops/features/staff/appointments/presentation/widgets/staff_appointments_tabs_bar.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/data/mappers/staff_attendance_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/presentation/widgets/staff_attendance_header.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/entities/staff_emergency_alert.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/entities/staff_residence.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/repositories/staff_extras_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/presentation/pages/staff_recurring_checks_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/presentation/pages/staff_residences_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/presentation/widgets/staff_emergency_details_sheet.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incident.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incident_options.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incidents_summary.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/repositories/staff_incidents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/controllers/staff_incidents_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/pages/staff_incidents_list_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/scheduling/presentation/widgets/staff_schedule_header.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/recurring_check_instance.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/recurring_check_schedule.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/repositories/staff_tasks_messages_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live `/mobile/me` permissions of the harmony-help caregiver QA used.
const _caregiverPermissions = [
  'appointments:read',
  'attendance:read',
  'attendance:write',
  'care-flags:read',
  'client-activities:read',
  'client-activities:write',
  'clients:read',
  'daily-logs:read',
  'daily-logs:write',
  'documents:read',
  'emergency:raise',
  'emergency:read',
  'incidents:read',
  'mar:read',
  'mar:write',
  'messaging:read',
  'messaging:write',
  'notifications:read',
  'notifications:write',
  'recurring-checks:complete',
  'recurring-checks:read',
  'residences:read',
  'scheduling:bid',
  'scheduling:read',
  'shift-handovers:read',
  'shift-handovers:write',
  'staff:directory',
  'tasks:read',
  'tasks:write',
  'training:read',
  'uploads:read',
  'uploads:write',
];

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

void _phone(WidgetTester tester, {Size size = const Size(390, 900)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const _residence = StaffResidence(
  id: 'res-1',
  name: 'Cozzy Cottage',
  status: 'active',
  addressLine1: 'Haji Solimuddin Ln',
);

class _FakeExtrasRepo extends Fake implements StaffExtrasRepository {
  @override
  Future<Result<List<StaffResidence>>> getResidences() async =>
      Result.success(const [_residence]);

  @override
  Future<Result<int>> getActiveResidentCount() async => Result.success(0);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceClients(
    String residenceId,
  ) async => Result.success(const [
    {'id': 'client-1', 'title': 'Client One', 'residenceId': 'res-1'},
  ]);
}

class _FakeTasksRepo extends Fake implements StaffTasksMessagesRepository {
  @override
  Future<Result<List<RecurringCheckSchedule>>>
  getRecurringCheckSchedules() async => Result.success(const [
    RecurringCheckSchedule(
      id: 'schedule-1',
      name: 'Welfare check',
      clientId: 'client-1',
      clientName: 'Client One',
      residenceId: 'res-1',
      residenceName: 'Cozzy Cottage',
      intervalMinutes: 30,
      isActive: true,
    ),
  ]);

  @override
  Future<Result<List<RecurringCheckInstance>>> getRecurringCheckInstances({
    DateTime? from,
    DateTime? to,
    String? status,
    String? residenceId,
    bool mine = false,
  }) async => Result.success(const []);

  @override
  Future<Result<List<RecurringCheckInstance>>> getRecurringCheckEntries({
    String? residenceId,
    DateTime? from,
    DateTime? to,
  }) async => Result.success(const []);
}

class _FakeIncidentsRepo extends Fake implements StaffIncidentsRepository {
  @override
  Future<Result<List<StaffIncidentResidenceOption>>> getResidences() async =>
      Result.success(const []);

  @override
  Future<Result<List<StaffIncidentClientOption>>> getClients({
    String? search,
    String? residenceId,
    bool assignedToMe = true,
  }) async => Result.success(const []);

  @override
  Future<Result<StaffIncidentsSummary>> getSummary() async =>
      Result.success(const StaffIncidentsSummary());

  @override
  Future<Result<List<StaffIncident>>> getIncidents({
    bool mine = false,
    String? search,
    String? severity,
    String? status,
    String? from,
    String? to,
    String? residenceId,
    String? clientId,
    int page = 1,
    int limit = 20,
  }) async => Result.success(const []);
}

class _FakeEmergencyApiClient extends AppApiClient {
  _FakeEmergencyApiClient(super.api, super.tenant);

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) async {
    if (path == ApiEndpoints.emergencyAlertById('alert-1')) {
      return Result.success({
        'id': 'alert-1',
        'status': 'active',
        'priority': 'high',
        'type': 'fall',
        'note': 'Resident slipped in the hallway',
        'residence': {'name': 'Cozzy Cottage'},
        'raiser': {'name': 'Abir Hasan'},
      });
    }
    return Result.failure(ApiError(message: 'unexpected GET $path'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
    Get.put(
      UserSession()
        ..signIn(
          role: UserRole.staff,
          displayName: 'Abir Hasan',
          email: 'xirob96224@meonvr.com',
        )
        ..applyStaffContext(
          staffId: 'staff-1',
          residenceId: 'res-1',
          residenceName: 'Cozzy Cottage',
        )
        ..applyPermissions(_caregiverPermissions),
      permanent: true,
    );
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('S01 Attendance shows Clock out after clocking in', () {
    // Live `/attendance?mine=true` shape: `checkIn` / `checkOut` are always
    // geofence metadata objects, even while the punch is open.
    Map<String, dynamic> record({
      required String status,
      String? checkInAt,
      String? checkOutAt,
    }) => {
      'id': 'att-$status',
      'residenceId': 'res-1',
      'status': status,
      'checkInAt': checkInAt,
      'checkOutAt': checkOutAt,
      'checkIn': {'geofenceStatus': 'not_provided', 'selfieUrl': null},
      'checkOut': {'geofenceStatus': 'not_provided', 'selfieUrl': null},
    };

    test('open present record (checkOut metadata object) is on shift', () {
      final checkIn = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 1))
          .toIso8601String();
      final overview = StaffAttendanceMapper.compose(
        todayAttendanceBody: [
          record(status: 'missed'),
          record(status: 'present', checkInAt: checkIn),
        ],
        historyBody: const [],
        shiftsBody: const [],
        residenceBody: null,
      );
      expect(overview.isOnShift, isTrue);
      expect(overview.shiftStartedLabel, startsWith('Started at'));
    });

    test('closed and missed records are not on shift', () {
      final overview = StaffAttendanceMapper.compose(
        todayAttendanceBody: [
          record(status: 'missed'),
          record(
            status: 'pending_approval',
            checkInAt: '2026-09-30T07:36:41.113Z',
            checkOutAt: '2026-09-30T11:30:00.000Z',
          ),
        ],
        historyBody: const [],
        shiftsBody: const [],
        residenceBody: null,
      );
      expect(overview.isOnShift, isFalse);
    });

    testWidgets('header swaps Clock in for Clock out', (tester) async {
      _phone(tester);
      var clockedOut = false;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: StaffAttendanceHeader(
              isOnShift: true,
              onClockInTap: () {},
              onClockOutTap: () => clockedOut = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Clock out'), findsOneWidget);
      expect(find.text('Clock in'), findsNothing);
      await tester.tap(find.byKey(const Key('staff-attendance-clock-out')));
      expect(clockedOut, isTrue);
    });
  });

  group('S03 Residences without residences:update', () {
    testWidgets('list shows only View, like the web', (tester) async {
      _phone(tester);
      GetIt.I.registerSingleton<StaffExtrasRepository>(_FakeExtrasRepo());

      await tester.pumpWidget(_wrap(const StaffResidencesPage()));
      await tester.pumpAndSettle();

      expect(find.text('Cozzy Cottage'), findsOneWidget);
      expect(find.byKey(const Key('staff-residence-view-res-1')), findsOneWidget);
      expect(find.byKey(const Key('staff-residence-edit-res-1')), findsNothing);
      expect(
        find.byKey(const Key('staff-residence-deactivate-res-1')),
        findsNothing,
      );
    });

    testWidgets('list keeps Edit / Deactivate with residences:update', (
      tester,
    ) async {
      _phone(tester);
      Get.find<UserSession>().applyPermissions([
        ..._caregiverPermissions,
        'residences:update',
      ]);
      GetIt.I.registerSingleton<StaffExtrasRepository>(_FakeExtrasRepo());

      await tester.pumpWidget(_wrap(const StaffResidencesPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staff-residence-edit-res-1')), findsOneWidget);
      expect(
        find.byKey(const Key('staff-residence-deactivate-res-1')),
        findsOneWidget,
      );
    });
  });

  group('S04 My Schedule without scheduling:write', () {
    testWidgets('+ Shift is hidden when no create callback', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _wrap(Scaffold(body: StaffScheduleHeader(onFilterTap: () {}))),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Schedule'), findsOneWidget);
      expect(find.byKey(const Key('staff-schedule-create-shift')), findsNothing);
    });

    testWidgets('+ Shift shows when the create callback is passed', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: StaffScheduleHeader(
              onFilterTap: () {},
              onCreateShiftTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('staff-schedule-create-shift')),
        findsOneWidget,
      );
    });
  });

  group('S05 Recurring Checks without recurring-checks:write', () {
    testWidgets('only Record Progress; no New Schedule or row actions', (
      tester,
    ) async {
      _phone(tester);
      GetIt.I.registerSingleton<StaffTasksMessagesRepository>(_FakeTasksRepo());
      GetIt.I.registerSingleton<StaffExtrasRepository>(_FakeExtrasRepo());

      await tester.pumpWidget(_wrap(const StaffRecurringChecksPage()));
      await tester.pumpAndSettle();

      expect(find.text('Welfare check'), findsOneWidget);
      expect(find.text('Record Progress'), findsOneWidget);
      expect(find.text('+ New Schedule'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Pause'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('managers with recurring-checks:write keep every action', (
      tester,
    ) async {
      _phone(tester);
      Get.find<UserSession>().applyPermissions([
        ..._caregiverPermissions,
        'recurring-checks:write',
      ]);
      GetIt.I.registerSingleton<StaffTasksMessagesRepository>(_FakeTasksRepo());
      GetIt.I.registerSingleton<StaffExtrasRepository>(_FakeExtrasRepo());

      await tester.pumpWidget(_wrap(const StaffRecurringChecksPage()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-recurring-new-schedule')),
        findsOneWidget,
      );
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('S06 Emergency note keeps its size while typing', () {
    testWidgets('note field stays usable with the keyboard open', (
      tester,
    ) async {
      _phone(tester, size: const Size(360, 640));
      SharedPreferences.setMockInitialValues({});
      final tenant = TenantStore(await SharedPreferences.getInstance());
      await tenant.load();
      GetIt.I.registerSingleton<AppApiClient>(
        _FakeEmergencyApiClient(
          ApiService(const ApiConfig(baseUrl: 'http://test')),
          tenant,
        ),
      );

      const alert = StaffEmergencyAlert(
        id: 'alert-1',
        status: 'active',
        priority: 'high',
        type: 'fall',
        typeLabel: 'Fall',
        residenceName: 'Cozzy Cottage',
        houseLine: '',
        raisedByName: 'Abir Hasan',
        raisedByPhone: '',
        note: 'Resident slipped in the hallway',
        locationNote: '',
      );
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => StaffEmergencyDetailsSheet.show(alert),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final note = find.byType(TextField);
      await tester.scrollUntilVisible(
        note,
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('staff-emergency-details')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(note);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      for (final text in ['Checked on', 'Checked on her, she is fine']) {
        await tester.enterText(note, text);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(text), findsOneWidget);
      }

      final card = tester.getRect(
        find
            .descendant(
              of: find.byKey(const Key('staff-emergency-details')),
              matching: find.byType(Material),
            )
            .first,
      );
      final body = tester.getRect(
        find.descendant(
          of: find.byKey(const Key('staff-emergency-details')),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(card.bottom, lessThanOrEqualTo(640 - 280));
      expect(tester.getRect(note).bottom, lessThanOrEqualTo(640 - 280));
      expect(body.height, greaterThan(100));
      expect(note.hitTestable(), findsOneWidget);
    });
  });

  group('S07 Incident Reports without incidents:write', () {
    Future<void> pumpList(WidgetTester tester) async {
      _phone(tester);
      Get.put(
        StaffIncidentsController(repository: _FakeIncidentsRepo()),
        permanent: true,
      );
      await tester.pumpWidget(_wrap(const StaffIncidentsListPage()));
      await tester.pumpAndSettle();
    }

    testWidgets('Add Incident is hidden', (tester) async {
      await pumpList(tester);
      expect(find.text('Incident Reports'), findsOneWidget);
      expect(find.text('Add Incident'), findsNothing);
    });

    testWidgets('Add Incident shows with incidents:write', (tester) async {
      Get.find<UserSession>().applyPermissions([
        ..._caregiverPermissions,
        'incidents:write',
      ]);
      await pumpList(tester);
      expect(find.byKey(const Key('staff-incidents-add')), findsOneWidget);
    });
  });

  group('S11 Appointments tab counts match the web', () {
    testWidgets('Pending, Approved, Rejected and All show counts', (
      tester,
    ) async {
      _phone(tester);
      final search = TextEditingController();
      addTearDown(search.dispose);
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: StaffAppointmentsTabsBar(
              selected: StaffAppointmentTab.approved,
              summary: const StaffAppointmentsSummary(
                pending: 1,
                approved: 1,
                rejected: 2,
                cancelled: 2,
                total: 6,
              ),
              onChanged: (_) {},
              searchController: search,
              onSearchChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending (1)'), findsOneWidget);
      expect(find.text('Approved (1)'), findsOneWidget);
      expect(find.text('Family visits'), findsOneWidget);
      expect(find.text('External'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('All (6)'),
        find.byType(SingleChildScrollView),
        const Offset(-200, 0),
      );
      expect(find.text('Rejected (2)'), findsOneWidget);
      expect(find.text('All (6)'), findsOneWidget);
    });
  });
}
