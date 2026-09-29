import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/formatting/web_formats.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_logs/data/mappers/daily_logs_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_logs/domain/entities/daily_log.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_logs/domain/repositories/daily_logs_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_logs/presentation/controllers/daily_logs_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_logs/presentation/daily_logs_labels.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_logs/presentation/pages/daily_logs_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/daily_logs/presentation/widgets/new_log_entry_sheet.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/presentation/widgets/handover_common.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incidents_board.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/repositories/incidents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/presentation/controllers/incidents_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/domain/entities/handover_options.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/domain/entities/shift_handover.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/domain/repositories/handovers_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/presentation/controllers/handovers_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/presentation/pages/handovers_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/presentation/manager_destinations.dart';
import 'package:comprehensive_hr_and_ops/features/hr/recurring_checks/domain/entities/recurring_check.dart';
import 'package:comprehensive_hr_and_ops/features/hr/recurring_checks/domain/repositories/recurring_checks_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/recurring_checks/presentation/controllers/recurring_checks_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/recurring_checks/presentation/pages/recurring_checks_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/recurring_checks/presentation/recurring_checks_labels.dart';
import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/data/mappers/tasks_compliance_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/domain/entities/create_task_request.dart';
import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/domain/entities/task_client_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/domain/entities/task_residence_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/domain/entities/task_shift_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/domain/entities/task_staff_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/domain/entities/tasks_compliance_overview.dart';
import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/domain/repositories/tasks_compliance_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/presentation/widgets/create_task_sheet.dart';
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

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _label(String text) => find.text(text, findRichText: true);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, Finder field, String option) async {
  await _tap(tester, field);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------- BUG12 ----

const _morningLabel = 'Morning · Tue 29/09/2026 07:00–15:00 · Maya Rahman +1';

class _FakeTasksRepo implements TasksComplianceRepository {
  final List<CreateTaskRequest> created = [];
  final List<String> shiftQueries = [];
  final List<String> roomQueries = [];

  @override
  Future<Result<TasksComplianceOverview>> getOverview() =>
      throw UnimplementedError();

  @override
  Future<Result<List<TaskResidenceOption>>> getResidences() async =>
      Result.success(const [
        TaskResidenceOption(id: 'elm', name: 'Elm House'),
        TaskResidenceOption(id: 'oak', name: 'Oak Lodge'),
      ]);

  @override
  Future<Result<List<String>>> getRooms(String residenceId) async {
    roomQueries.add(residenceId);
    return Result.success(
      residenceId == 'elm' ? const ['Kitchen', 'Room 4'] : const [],
    );
  }

  @override
  Future<Result<List<TaskShiftOption>>> getShiftOptions(String residenceId) async {
    shiftQueries.add(residenceId);
    return Result.success(
      residenceId == 'elm'
          ? const [
              TaskShiftOption(id: 'shift-am', label: _morningLabel),
              TaskShiftOption(
                id: 'shift-pm',
                label: 'Evening · Tue 29/09/2026 15:00–23:00 · nobody rostered',
              ),
            ]
          : const [],
    );
  }

  @override
  Future<Result<List<TaskClientOption>>> searchClients({
    required String search,
    String? residenceId,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<List<TaskStaffOption>>> searchStaff({
    required String search,
    String? residenceId,
  }) async =>
      Result.success(const [TaskStaffOption(id: 'staff-maya', name: 'Maya Rahman')]);

  @override
  Future<Result<void>> createTask(CreateTaskRequest request) async {
    created.add(request);
    return Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_FakeTasksRepo> _openCreateTask(WidgetTester tester) async {
  _tallView(tester);
  final repo = _FakeTasksRepo();
  GetIt.I.registerSingleton<TasksComplianceRepository>(repo);
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showCreateTaskSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _addStaff(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextField, 'Add staff'), 'Maya');
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Maya Rahman').last);
}

// ---------------------------------------------------------------- BUG10 ----

class _Session extends UserSession {
  @override
  String? get userId => 'user-me';

  @override
  String? get staffId => 'staff-me';

  @override
  String get displayName => 'Rafi Ahmed';
}

final _received = ShiftHandover(
  id: 'h1',
  residenceId: 'elm',
  residenceName: 'Elm House',
  summary: 'Quiet shift. Ayaan settled.',
  status: 'submitted',
  fromShiftStartsAt: DateTime(2026, 8, 27, 7, 30),
  alertingCount: 1,
  needsAcknowledgement: true,
  pendingActions: const ['Chase the pharmacy'],
  clientUpdates: const [
    HandoverClientUpdate(
      id: 'cu1',
      clientName: 'Ayaan Karim',
      status: 'needs_attention',
      health: {'generalCondition': 'Calm'},
      medication: {'prnGiven': 'Paracetamol 500mg'},
      care: HandoverCare(
        completed: ['personal_care', 'hygiene'],
        pending: 'Offer a snack before bed',
      ),
    ),
  ],
  incidents: const [
    HandoverIncident(id: 'i1', reference: 'INC-7', title: 'Fall', severity: 'low'),
  ],
  comments: [
    HandoverComment(
      id: 'c1',
      body: 'audit comment',
      authorName: 'Shakib Hasan',
      createdAt: DateTime(2026, 9, 28, 10, 43),
    ),
  ],
  tasks: const [
    HandoverTask(id: 't1', title: 'Chase the pharmacy', status: 'open', priority: 'high'),
  ],
  acknowledgements: [
    HandoverAcknowledgement(
      userId: 'user-priya',
      staffFirstName: 'Priya',
      createdAt: DateTime(2026, 8, 27, 15, 33),
    ),
  ],
  flagCategory: 'medical',
  createdBy: 'user-jamal',
  authorName: 'Jamal Uddin',
  createdAt: DateTime(2026, 8, 27, 9, 33),
);

final _myDraft = ShiftHandover(
  id: 'h2',
  residenceId: 'elm',
  residenceName: 'Elm House',
  summary: 'Draft from me',
  status: 'draft',
  createdBy: 'user-me',
  authorName: 'Rafi Ahmed',
  createdAt: DateTime(2026, 9, 29, 8, 15),
);

final _recentShift = HandoverShift(
  id: 'shift-day',
  residenceId: 'elm',
  residenceName: 'Elm House',
  title: 'Day shift',
  shiftType: 'morning',
  startsAt: DateTime(2026, 9, 29, 7),
  endsAt: DateTime(2026, 9, 29, 15),
  staff: const [HandoverShiftStaff(id: 's1', name: 'Jamal Uddin', status: 'confirmed')],
);

final _nightShift = HandoverShift(
  id: 'shift-night',
  residenceId: 'elm',
  residenceName: 'Elm House',
  shiftType: 'night',
  startsAt: DateTime(2026, 9, 29, 15),
  endsAt: DateTime(2026, 9, 29, 23),
  staff: const [
    HandoverShiftStaff(id: 's2', name: 'Maya Rahman', status: 'confirmed'),
    HandoverShiftStaff(id: 's3', name: 'Priya Das', status: 'confirmed'),
    HandoverShiftStaff(id: 's4', name: 'Sam Lee', status: 'declined'),
  ],
);

class _FakeHandoversRepo implements HandoversRepository {
  List<ShiftHandover> items = [_received, _myDraft];
  final List<Map<String, String?>> queries = [];
  final List<(String, String?)> acknowledged = [];
  final List<(String, String)> statuses = [];
  final List<(String, String)> comments = [];
  final List<String> deleted = [];
  final List<Map<String, dynamic>> created = [];
  final List<DateTime?> incomingAfter = [];

  @override
  Future<Result<List<ShiftHandover>>> list({
    String? status,
    String? staffId,
    String? residenceId,
    String? from,
    String? to,
  }) async {
    queries.add({
      'status': status,
      'staffId': staffId,
      'residenceId': residenceId,
      'from': from,
      'to': to,
    });
    return Result.success(items);
  }

  @override
  Future<Result<ShiftHandover>> byId(String id) async =>
      Result.success(items.firstWhere((h) => h.id == id));

  @override
  Future<Result<HandoverAnnouncement?>> create(Map<String, dynamic> body) async {
    created.add(body);
    return Result.success(const HandoverAnnouncement(mode: 'shift', recipients: 2));
  }

  @override
  Future<Result<void>> setStatus(String id, String status) async {
    statuses.add((id, status));
    return Result.success(null);
  }

  @override
  Future<Result<void>> comment(String id, String body) async {
    comments.add((id, body));
    return Result.success(null);
  }

  @override
  Future<Result<void>> acknowledge(String id, {String? note}) async {
    acknowledged.add((id, note));
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    deleted.add(id);
    return Result.success(null);
  }

  @override
  Future<Result<List<HandoverOption>>> residences() async =>
      Result.success(const [HandoverOption(id: 'elm', label: 'Elm House')]);

  @override
  Future<Result<List<HandoverOption>>> staff() async =>
      Result.success(const [HandoverOption(id: 'staff-jamal', label: 'Jamal Uddin')]);

  @override
  Future<Result<List<HandoverOption>>> clients(String residenceId) async =>
      Result.success(const [HandoverOption(id: 'client-ayaan', label: 'Ayaan Karim')]);

  @override
  Future<Result<List<HandoverShift>>> myRecentShifts(String staffId) async =>
      Result.success(const []);

  @override
  Future<Result<List<HandoverShift>>> residenceRecentShifts(String residenceId) async =>
      Result.success([_recentShift]);

  @override
  Future<Result<List<HandoverShift>>> incomingShifts(
    String residenceId,
    DateTime? after,
  ) async {
    incomingAfter.add(after);
    return Result.success([_nightShift]);
  }
}

Future<_FakeHandoversRepo> _openHandovers(
  WidgetTester tester, {
  List<ShiftHandover>? items,
}) async {
  _tallView(tester);
  final repo = _FakeHandoversRepo();
  if (items != null) repo.items = items;
  final session = Get.put<UserSession>(_Session());
  GetIt.I.registerFactory<HandoversController>(
    () => HandoversController(repository: repo, session: session),
  );
  await tester.pumpWidget(_app(const HandoversPage()));
  await tester.pumpAndSettle();
  return repo;
}

// ---------------------------------------------------------------- BUG11 ----

class _CheckSession extends _Session {
  final Set<String> denied;

  _CheckSession({this.denied = const {}});

  @override
  bool can(String permission) => !denied.contains(permission);
}

final _halfHourly = CheckSchedule(
  id: 's1',
  clientId: 'c1',
  residenceId: 'elm',
  name: 'Half-hourly welfare check',
  checkType: 'other',
  frequency: 'interval',
  intervalMinutes: 30,
  clientName: 'Ayaan Karim',
  residenceName: 'Elm House',
);

final _bp = CheckSchedule(
  id: 's2',
  clientId: 'c1',
  residenceId: 'elm',
  name: 'Blood pressure',
  checkType: 'vital_signs',
  instructions: 'Seated, left arm.',
  frequency: 'weekly',
  timesOfDay: const [480, 1200],
  weekdays: const [1, 3],
  assignedStaffName: 'Maya Rahman',
  assignedStaffId: 'staff-maya',
  isActive: false,
  effectiveFrom: DateTime.utc(2026, 9, 21, 18),
  alertEnabled: true,
  alertRules: const [
    CheckAlertRule(field: 'systolic', operator: 'gt', value: 140, severity: 'urgent'),
  ],
  notifyRoles: const ['nurse'],
  clientName: 'Ayaan Karim',
  residenceName: 'Elm House',
);

CheckInstance _instance(
  String id, {
  String status = 'pending',
  String checkType = 'vital_signs',
  DateTime? dueAt,
  String? assignedStaffId,
  String? assignedStaffName,
  String? assignedRole,
  CheckEntry? entry,
  String? statusNote,
  bool? statusOnDuty,
}) =>
    CheckInstance(
      id: id,
      scheduleId: 's2',
      clientId: 'c1',
      residenceId: 'elm',
      dueAt: dueAt ?? DateTime.now().add(const Duration(hours: 2)),
      status: status,
      checkName: 'Blood pressure',
      checkType: checkType,
      instructions: 'Seated, left arm.',
      clientName: 'Ayaan Karim',
      roomNumber: '101',
      assignedStaffId: assignedStaffId,
      assignedStaffName: assignedStaffName,
      assignedRole: assignedRole,
      entry: entry,
      statusNote: statusNote,
      statusOnDuty: statusOnDuty,
    );

class _FakeChecksRepo implements RecurringChecksRepository {
  List<CheckSchedule> scheduleItems = [_halfHourly, _bp];
  List<CheckInstance> instanceItems = [];
  List<CheckEntry> entryItems = [];
  Map<String, List<CheckSchedule>> byClient = {};
  String? openResidence;

  final List<(int, int)> schedulePages = [];
  final List<Map<String, Object?>> instanceQueries = [];
  final List<Map<String, Object?>> entryQueries = [];
  final List<Map<String, dynamic>> created = [];
  final List<(String, Map<String, dynamic>)> scheduleUpdates = [];
  final List<String> deleted = [];
  final List<(String, Map<String, dynamic>)> instanceUpdates = [];
  final List<Map<String, dynamic>> recorded = [];
  final List<String?> clientQueries = [];

  @override
  Future<Result<CheckSchedulePage>> schedules({required int page, required int limit}) async {
    schedulePages.add((page, limit));
    return Result.success(CheckSchedulePage(
      items: scheduleItems,
      page: page,
      limit: limit,
      total: scheduleItems.length,
      totalPages: 1,
    ));
  }

  @override
  Future<Result<List<CheckSchedule>>> clientSchedules(String clientId) async =>
      Result.success(byClient[clientId] ?? const []);

  @override
  Future<Result<void>> createSchedule(Map<String, dynamic> body) async {
    created.add(body);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateSchedule(String id, Map<String, dynamic> body) async {
    scheduleUpdates.add((id, body));
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteSchedule(String id) async {
    deleted.add(id);
    return Result.success(null);
  }

  @override
  Future<Result<List<CheckInstance>>> instances({
    required String day,
    String? residenceId,
    String? status,
    bool mine = false,
  }) async {
    instanceQueries.add({'day': day, 'residenceId': residenceId, 'status': status, 'mine': mine});
    return Result.success(instanceItems);
  }

  @override
  Future<Result<List<CheckEntry>>> entries({
    required String day,
    String? residenceId,
    String? outcome,
    bool mine = false,
  }) async {
    entryQueries.add({'day': day, 'residenceId': residenceId, 'outcome': outcome, 'mine': mine});
    return Result.success(entryItems);
  }

  @override
  Future<Result<void>> updateInstance(String id, Map<String, dynamic> body) async {
    instanceUpdates.add((id, body));
    return Result.success(null);
  }

  @override
  Future<Result<List<CheckAvailableStaff>>> availableStaff(String instanceId) async =>
      Result.success(const [
        CheckAvailableStaff(staffId: 'staff-maya', name: 'Maya Rahman', shiftTitle: 'Morning'),
      ]);

  @override
  Future<Result<void>> recordEntry(Map<String, dynamic> body) async {
    recorded.add(body);
    return Result.success(null);
  }

  @override
  Future<Result<List<CheckOption>>> residences() async => Result.success(const [
        CheckOption(id: 'elm', label: 'Elm House'),
        CheckOption(id: 'oak', label: 'Oak Lodge'),
      ]);

  @override
  Future<Result<List<CheckOption>>> staff() async => Result.success(const [
        CheckOption(id: 'staff-maya', label: 'Maya Rahman'),
      ]);

  @override
  Future<Result<List<CheckOption>>> clients({String? residenceId}) async {
    clientQueries.add(residenceId);
    return Result.success(const [CheckOption(id: 'c1', label: 'Ayaan Karim')]);
  }

  @override
  Future<Result<List<CheckOption>>> colleagues(String? residenceId) async =>
      Result.success(const [
        CheckOption(id: 'staff-maya', label: 'Maya Rahman'),
        CheckOption(id: 'staff-jamal', label: 'Jamal Uddin'),
      ]);

  @override
  Future<Result<String?>> openAttendanceResidenceId() async => Result.success(openResidence);
}

Future<_FakeChecksRepo> _openChecks(
  WidgetTester tester, {
  _FakeChecksRepo? repo,
  Set<String> denied = const {},
}) async {
  _tallView(tester);
  final fake = repo ?? _FakeChecksRepo();
  final session = Get.put<UserSession>(_CheckSession(denied: denied));
  GetIt.I.registerFactory<RecurringChecksController>(
    () => RecurringChecksController(repository: fake, session: session),
  );
  await tester.pumpWidget(_app(const RecurringChecksPage()));
  await tester.pumpAndSettle();
  return fake;
}

/// Records compare maps by identity; lists let `expect` compare deeply.
List<List<Object>> _calls(List<(String, Map<String, dynamic>)> calls) => [
      for (final (id, body) in calls) [id, body],
    ];

Future<void> _enter(WidgetTester tester, Key key, String text) async {
  final field = find.descendant(of: find.byKey(key), matching: find.byType(TextField));
  if (field.evaluate().isEmpty) {
    await tester.scrollUntilVisible(find.byKey(key), 300,
        scrollable: find.byType(Scrollable).last);
  }
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Taps inside the open bottom sheet, scrolling its list when needed.
Future<void> _tapInSheet(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _chooseInSheet(WidgetTester tester, Finder field, String option) async {
  await _tapInSheet(tester, field);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------- BUG13 ----

final _superseded = DailyLogEntry(
  id: 'e1',
  body: 'Left for school on time.',
  occurredAt: DateTime(2026, 8, 27, 7, 33),
  createdAt: DateTime(2026, 8, 27, 9, 33),
  authorName: 'Jamal Uddin',
  isSuperseded: true,
  wellnessCheckCompleted: false,
  bedCheckCompleted: false,
);

final _correction = DailyLogEntry(
  id: 'e2',
  body: 'Correction: left 20 minutes late.',
  occurredAt: DateTime(2026, 8, 27, 8, 33),
  createdAt: DateTime(2026, 8, 27, 9, 34),
  authorName: 'Jamal Uddin',
  amendsEntryId: 'e1',
  amendmentReason: 'Time was recorded incorrectly.',
);

final _fullEntry = DailyLogEntry(
  id: 'e3',
  body: 'Went to the park with Maya.',
  occurredAt: DateTime(2026, 8, 27, 14, 5),
  createdAt: DateTime(2026, 8, 27, 14, 10),
  authorName: 'Maya Rahman',
  shift: 'afternoon',
  logType: 'care_note',
  observations: const {'mood': 'settled', 'communityOuting': true, 'outingNotes': 'Park'},
  wellnessCheckCompleted: true,
  bedCheckCompleted: false,
  remindAt: DateTime(2026, 8, 27, 18),
  attachments: const [
    DailyLogAttachment(id: 'a1', fileUrl: 'https://files/uploads/chart.pdf'),
  ],
  flag: const DailyLogEntryFlag(category: 'medical', note: 'Cough'),
);

final _bpCheck = DailyLogCheck(
  id: 'k1',
  checkedAt: DateTime(2026, 8, 27, 10),
  checkName: 'Blood pressure',
  note: 'Slightly high',
  result: const {'systolic': 150, 'systolicUnit': 'mmHg'},
  outcome: 'needs_review',
  recordedBy: 'Jamal Uddin',
);

class _FakeDailyLogsRepo implements DailyLogsRepository {
  List<DailyLogReviewRow> reviewRows = const [
    DailyLogReviewRow(
      id: 'd1',
      clientId: 'c1',
      clientName: 'Ayaan Karim',
      logDate: '2026-08-27',
      entriesCount: 2,
    ),
    DailyLogReviewRow(
      id: 'd2',
      clientId: 'c2',
      clientName: 'Nadia Islam',
      logDate: '2026-08-26',
      entriesCount: 3,
    ),
  ];
  int reviewTotal = 7;
  List<DailyLogMissingRow> missingRows = const [
    DailyLogMissingRow(clientId: 'c2', clientName: 'Nadia Islam', logDate: '2026-08-28'),
  ];
  int missingTotal = 4;
  DailyLogDay? dayData = DailyLogDay(
    entries: [_fullEntry, _correction, _superseded],
    checks: [_bpCheck],
  );
  List<DailyLogShiftRow> shiftRows = [
    const DailyLogShiftRow(
      id: 'sl1',
      status: 'open',
      clientName: 'Ayaan Karim',
      shiftTitle: 'Day shift',
    ),
    DailyLogShiftRow(
      id: 'sl2',
      status: 'completed',
      summary: 'Settled day.',
      clientName: 'Nadia Islam',
      shiftType: 'morning',
      shiftStartsAt: DateTime(2026, 9, 29, 7),
      shiftEndsAt: DateTime(2026, 9, 29, 15),
      completedByName: 'Jamal Uddin',
    ),
  ];
  List<ResidenceActivityRow> activityRows = [
    ResidenceActivityRow(
      id: 'a1',
      module: 'handovers',
      activityType: 'handover_acknowledged',
      summary: 'Handover acknowledged by Priya',
      occurredAt: DateTime(2026, 9, 28, 16, 20),
      clientName: 'Ayaan Karim',
      staffName: 'Priya Das',
      residenceName: 'Elm House',
      entityType: 'shift_handover',
      entityId: 'h1',
    ),
    ResidenceActivityRow(
      id: 'a2',
      module: 'inventory',
      activityType: 'stock_low',
      summary: 'Gloves are running low',
      occurredAt: DateTime(2026, 9, 28, 9),
      entityType: 'inventory_item',
    ),
  ];
  List<CareFlag> flagRows = [
    CareFlag(
      id: 'f1',
      category: 'medical',
      raisedAt: DateTime(2026, 9, 29, 8, 15),
      raisedBy: 'Rafi Ahmed',
      residenceName: 'Elm House',
      source: const CareFlagSource(
        kind: 'shift_handover',
        excerpt: 'Coughing through the night',
        logDate: '2026-09-29T00:00:00.000Z',
      ),
    ),
    CareFlag(
      id: 'f2',
      category: 'behaviour',
      note: 'Unsettled after the evening visit',
      raisedAt: DateTime(2026, 8, 27, 9, 33),
      raisedBy: 'Jamal Uddin',
      residenceName: 'Elm House',
    ),
  ];

  final List<Map<String, Object?>> queueQueries = [];
  final List<Map<String, String>> dayQueries = [];
  final List<Map<String, String>> shiftQueries = [];
  final List<Map<String, Object?>> activityQueries = [];
  final List<String?> flagQueries = [];
  final List<String?> clientQueries = [];
  final List<Map<String, dynamic>> created = [];
  final List<List<String>> amended = [];
  final List<String> deleted = [];
  final List<List<Object>> shiftUpdates = [];
  final List<List<String?>> resolved = [];
  final List<String> uploads = [];

  @override
  Future<Result<List<DailyLogOption>>> residences() async => Result.success(const [
        DailyLogOption(id: 'elm', label: 'Elm House'),
        DailyLogOption(id: 'oak', label: 'Oak Lodge'),
      ]);

  @override
  Future<Result<List<DailyLogOption>>> clients(String? residenceId) async {
    clientQueries.add(residenceId);
    return Result.success(clientRows);
  }

  List<DailyLogOption> clientRows = const [
    DailyLogOption(id: 'c1', label: 'Ayaan Karim'),
    DailyLogOption(id: 'c2', label: 'Nadia Islam'),
  ];

  Map<String, Object?> _q(String status, String r, String? c, String f, String t, int p, int l) =>
      {'status': status, 'residenceId': r, 'clientId': c, 'from': f, 'to': t, 'page': p, 'limit': l};

  @override
  Future<Result<DailyLogPage<DailyLogReviewRow>>> reviewQueue({
    required String residenceId,
    String? clientId,
    required String from,
    required String to,
    required int page,
    required int limit,
  }) async {
    queueQueries.add(_q('review', residenceId, clientId, from, to, page, limit));
    return Result.success(DailyLogPage(
      items: reviewRows,
      total: reviewRows.isEmpty ? 0 : reviewTotal,
      totalPages: reviewRows.isEmpty ? 0 : 1,
    ));
  }

  @override
  Future<Result<DailyLogPage<DailyLogMissingRow>>> missing({
    required String residenceId,
    String? clientId,
    required String from,
    required String to,
    required int page,
    required int limit,
  }) async {
    queueQueries.add(_q('missing', residenceId, clientId, from, to, page, limit));
    return Result.success(DailyLogPage(
      items: missingRows,
      total: missingRows.isEmpty ? 0 : missingTotal,
      totalPages: missingRows.isEmpty ? 0 : 1,
    ));
  }

  @override
  Future<Result<DailyLogDay?>> day({
    required String clientId,
    required String residenceId,
    required String logDate,
  }) async {
    dayQueries.add({'clientId': clientId, 'residenceId': residenceId, 'logDate': logDate});
    return Result.success(dayData);
  }

  @override
  Future<Result<DailyLogEntry>> entry(String id) async => Result.success(
        DailyLogEntry(
          id: _correction.id,
          body: _correction.body,
          occurredAt: _correction.occurredAt,
          createdAt: _correction.createdAt,
          authorName: _correction.authorName,
          amendsEntryId: 'e1',
          amendmentReason: _correction.amendmentReason,
          logType: 'sleep_mood',
          wellnessCheckCompleted: true,
          bedCheckCompleted: false,
          observations: const {'mood': 'settled', 'communityOuting': true},
          amendmentChain: [_superseded, _correction],
        ),
      );

  @override
  Future<Result<List<DailyLogShiftRow>>> shiftLogs({
    required String residenceId,
    required String logDate,
  }) async {
    shiftQueries.add({'residenceId': residenceId, 'logDate': logDate});
    return Result.success(shiftRows);
  }

  @override
  Future<Result<void>> updateShiftLog(String id, Map<String, dynamic> body) async {
    shiftUpdates.add([id, body]);
    return Result.success(null);
  }

  @override
  Future<Result<void>> createEntry(Map<String, dynamic> body) async {
    created.add(body);
    return Result.success(null);
  }

  @override
  Future<Result<void>> amendEntry(String id, {required String body, required String reason}) async {
    amended.add([id, body, reason]);
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteEntry(String id) async {
    deleted.add(id);
    return Result.success(null);
  }

  @override
  Future<Result<DailyLogPage<ResidenceActivityRow>>> activity({
    required String residenceId,
    required String from,
    required String to,
    required int page,
    required int limit,
  }) async {
    activityQueries.add(
      {'residenceId': residenceId, 'from': from, 'to': to, 'page': page, 'limit': limit},
    );
    return Result.success(DailyLogPage(
      items: activityRows,
      total: activityRows.length,
      totalPages: activityRows.isEmpty ? 0 : 1,
    ));
  }

  @override
  Future<Result<DailyLogPage<CareFlag>>> openFlags(String? residenceId) async {
    flagQueries.add(residenceId);
    return Result.success(
      DailyLogPage(items: flagRows, total: flagRows.length, totalPages: 1),
    );
  }

  @override
  Future<Result<void>> resolveFlag(String id, {String? note}) async {
    resolved.add([id, note]);
    return Result.success(null);
  }

  @override
  Future<Result<DailyLogUpload>> upload(String path, String fileName) async {
    uploads.add(path);
    return Result.success(DailyLogUpload(
      fileUrl: 'https://files/uploads/$fileName',
      fileType: 'image/png',
      fileName: fileName,
    ));
  }
}

/// Backs the bottom-nav alerts badge on pages that show [HrBottomNavBar].
class _NoIncidentsRepo implements IncidentsRepository {
  @override
  Future<Result<IncidentsBoard>> getBoard() async =>
      Result.failure(const ApiError(message: 'offline'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<(_FakeDailyLogsRepo, DailyLogsController)> _openLogs(
  WidgetTester tester, {
  _FakeDailyLogsRepo? repo,
  Set<String> denied = const {},
  DailyLogFilePicker? pickFiles,
}) async {
  _tallView(tester);
  final fake = repo ?? _FakeDailyLogsRepo();
  final session = Get.put<UserSession>(_CheckSession(denied: denied));
  GetIt.I.registerFactory<DailyLogsController>(
    () => DailyLogsController(repository: fake, session: session),
  );
  GetIt.I.registerFactory<IncidentsController>(
    () => IncidentsController(repository: _NoIncidentsRepo()),
  );
  await tester.pumpWidget(_app(DailyLogsPage(pickFiles: pickFiles)));
  await tester.pumpAndSettle();
  return (fake, Get.find<DailyLogsController>());
}

Future<void> _pickResidence(WidgetTester tester, [String name = 'Elm House']) =>
    _choose(tester, find.byKey(const ValueKey('dl-residence')), name);

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

  group('BUG12 New Task shift', () {
    test('shift options use the web describeShift label, skip cancelled '
        'shifts and declined staff, soonest first', () {
      final options = TasksComplianceMapper.shiftOptionsFrom({
        'data': [
          {
            'id': 'late',
            'shiftType': 'evening',
            'startsAt': DateTime(2026, 9, 29, 15).toUtc().toIso8601String(),
            'endsAt': DateTime(2026, 9, 29, 23).toUtc().toIso8601String(),
            'staff': const [],
          },
          {
            'id': 'gone',
            'status': 'cancelled',
            'startsAt': DateTime(2026, 9, 29, 6).toUtc().toIso8601String(),
          },
          {
            'id': 'early',
            'shiftType': 'morning',
            'title': 'Day shift',
            'startsAt': DateTime(2026, 9, 29, 7).toUtc().toIso8601String(),
            'endsAt': DateTime(2026, 9, 29, 15).toUtc().toIso8601String(),
            'staff': const [
              {'name': 'Jamal Uddin', 'status': 'confirmed'},
              {'name': 'Priya Das', 'status': 'declined'},
              {'name': 'Maya Rahman', 'status': 'assigned'},
              {'name': 'Sam Lee', 'status': 'bid_pending'},
            ],
          },
        ],
      });
      expect(options.map((o) => o.id), ['early', 'late']);
      expect(
        options.first.label,
        'Morning — Day shift · Tue 29/09/2026 07:00–15:00 · Jamal Uddin +1',
      );
      expect(
        options.last.label,
        'Evening · Tue 29/09/2026 15:00–23:00 · nobody rostered',
      );
      expect(
        WebFormat.describeShift(
          startsAt: DateTime(2026, 9, 29, 7),
          endsAt: DateTime(2026, 9, 29, 15),
          staffNames: const ['Maya'],
          residenceName: 'Elm House',
          withResidence: true,
        ),
        'Shift · Elm House · Tue 29/09/2026 07:00–15:00 · Maya',
      );
    });

    testWidgets('Shift is required for a one-off task and loads the '
        "residence's rostered shifts", (tester) async {
      final repo = await _openCreateTask(tester);

      expect(repo.shiftQueries, ['elm']);
      expect(repo.roomQueries, ['elm']);
      expect(_label('Shift *'), findsOneWidget);
      expect(find.text('Select the shift'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('create-task-submit')));
      expect(find.text('Choose the shift this task belongs to'), findsOneWidget);
      expect(find.text('Assign at least one person to the task'), findsOneWidget);
      expect(find.text('Task title is required'), findsOneWidget);
      expect(repo.created, isEmpty);

      await _choose(
        tester,
        find.byKey(const ValueKey('create-task-shift')),
        _morningLabel,
      );
      expect(find.text(_morningLabel), findsOneWidget);
      expect(find.text('Choose the shift this task belongs to'), findsNothing);

      await _choose(tester, find.byKey(const ValueKey('create-task-room')), 'Room 4');
      await _addStaff(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Fridge Temperature Check'),
        'Fridge check',
      );
      await _choose(tester, find.text('Administrative'), 'Follow-up');
      await _choose(tester, find.text('Medium'), 'Urgent');
      await _tap(tester, find.byKey(const ValueKey('create-task-submit')));

      expect(repo.created, hasLength(1));
      final request = repo.created.single;
      expect(request.residenceId, 'elm');
      expect(request.shiftId, 'shift-am');
      expect(request.roomArea, 'Room 4');
      expect(request.title, 'Fridge check');
      expect(request.taskType, 'follow_up');
      expect(request.priority, 'urgent');
      expect(request.assignedStaffIds, ['staff-maya']);
      expect(request.recurring, isFalse);
    });

    testWidgets('changing residence clears the shift and reloads its options; '
        'an unrostered home says so', (tester) async {
      final repo = await _openCreateTask(tester);
      await _choose(
        tester,
        find.byKey(const ValueKey('create-task-shift')),
        _morningLabel,
      );

      await _choose(
        tester,
        find.byKey(const ValueKey('create-task-residence')),
        'Oak Lodge',
      );
      expect(repo.shiftQueries, ['elm', 'oak']);
      expect(find.text(_morningLabel), findsNothing);
      expect(
        find.text('No shifts rostered at this home in the next week'),
        findsOneWidget,
      );
    });

    testWidgets('a recurring task swaps Shift for the web schedule settings',
        (tester) async {
      final repo = await _openCreateTask(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Fridge Temperature Check'),
        'Weekly audit',
      );
      await _tap(tester, find.byKey(const ValueKey('create-task-recurring')));
      await _tap(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('create-task-recurring')),
          matching: find.byType(Switch),
        ),
      );

      expect(find.byKey(const ValueKey('create-task-shift')), findsNothing);
      expect(_label('Frequency *'), findsOneWidget);
      expect(find.text("In the home's own clock"), findsOneWidget);
      expect(find.text('Everybody named gets every occurrence'), findsOneWidget);

      await _choose(
        tester,
        find.byKey(const ValueKey('create-task-rotation')),
        'One person in turn',
      );
      expect(find.text('Each occurrence goes to one person, in turn'), findsOneWidget);

      await _choose(
        tester,
        find.byKey(const ValueKey('create-task-frequency')),
        'Weekly',
      );
      await _tap(tester, find.byKey(const ValueKey('create-task-submit')));
      expect(find.text('Pick the days it falls on'), findsOneWidget);
      expect(find.text('Choose the shift this task belongs to'), findsNothing);
      expect(repo.created, isEmpty);

      await _tap(tester, find.byKey(const ValueKey('create-task-weekday-1')));
      await _tap(tester, find.byKey(const ValueKey('create-task-weekday-5')));
      await _choose(
        tester,
        find.byKey(const ValueKey('create-task-end-condition')),
        'On a specific date',
      );
      expect(_label('Stops on *'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('create-task-submit')));
      expect(find.text('Pick the date it stops'), findsOneWidget);

      await _choose(
        tester,
        find.byKey(const ValueKey('create-task-end-condition')),
        'Never',
      );
      await _tap(tester, find.byKey(const ValueKey('create-task-submit')));

      final request = repo.created.single;
      expect(request.shiftId, isNull);
      final recurrence = request.recurrence!;
      expect(recurrence.frequency, 'weekly');
      expect(recurrence.weekdays, [1, 5]);
      expect(recurrence.timeOfDayMinutes, 9 * 60);
      expect(recurrence.rotating, isTrue);
      expect(recurrence.endsOn, isNull);
    });
  });

  group('BUG10 Shift Handovers', () {
    test('the Manager menu lists Shift Handovers', () {
      Get.put<UserSession>(_Session());
      expect(
        managerDestinations().map((d) => d.title),
        contains('Shift Handovers'),
      );
    });

    testWidgets('list shows the web filters, cards and row actions',
        (tester) async {
      final repo = await _openHandovers(tester);

      expect(find.text('Shift Handovers'), findsOneWidget);
      for (final label in const [
        'Any status',
        'Anyone',
        'Handovers from',
        'Handovers to',
        'All Residences',
        'Record Handover',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(repo.queries.single, {
        'status': null,
        'staffId': null,
        'residenceId': null,
        'from': null,
        'to': null,
      });

      final card = find.byKey(const ValueKey('handover-h1'));
      Finder inCard(String text) =>
          find.descendant(of: card, matching: find.text(text));
      expect(inCard('Elm House'), findsOneWidget);
      expect(inCard('Submitted'), findsOneWidget);
      expect(inCard('1 needing attention'), findsOneWidget);
      expect(inCard('Jamal Uddin · 27/08/2026 09:33'), findsOneWidget);
      expect(inCard('Ayaan Karim'), findsOneWidget);
      expect(inCard('Incidents on this shift: INC-7'), findsOneWidget);
      expect(inCard('Chase the pharmacy'), findsOneWidget);
      expect(inCard('nobody yet'), findsOneWidget);
      expect(inCard('Open'), findsOneWidget);
      expect(inCard('Priya at 15:33'), findsOneWidget);
      expect(inCard('Flagged: Medical'), findsOneWidget);
      expect(find.byKey(const ValueKey('handover-take-h1')), findsOneWidget);
      expect(find.byKey(const ValueKey('handover-submit-h1')), findsNothing);

      final draft = find.byKey(const ValueKey('handover-h2'));
      expect(find.descendant(of: draft, matching: find.text('Draft')), findsOneWidget);
      expect(
        find.descendant(
          of: draft,
          matching: find.text('Nobody has confirmed picking this up yet.'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('handover-submit-h2')), findsOneWidget);
      expect(find.byKey(const ValueKey('handover-take-h2')), findsNothing);

      await _choose(
        tester,
        find.byKey(const ValueKey('handovers-status-filter')),
        'Read',
      );
      expect(repo.queries.last['status'], 'viewed');
      await _choose(
        tester,
        find.byKey(const ValueKey('handovers-staff-filter')),
        'Jamal Uddin',
      );
      expect(repo.queries.last['staffId'], 'staff-jamal');
      await _choose(
        tester,
        find.byKey(const ValueKey('handovers-residence-filter')),
        'Elm House',
      );
      expect(repo.queries.last['residenceId'], 'elm');
    });

    testWidgets('take, submit and delete call the web endpoints',
        (tester) async {
      final repo = await _openHandovers(tester);

      await _tap(tester, find.byKey(const ValueKey('handover-take-h1')));
      expect(repo.acknowledged, [('h1', null)]);

      await _tap(tester, find.byKey(const ValueKey('handover-submit-h2')));
      expect(repo.statuses, [('h2', 'submitted')]);

      await _tap(tester, find.byKey(const ValueKey('handover-delete-h2')));
      expect(find.text('Delete this handover?'), findsOneWidget);
      expect(
        find.text('It leaves the list. What it recorded, and who acknowledged '
            'it, are kept rather than destroyed, so it can be restored.'),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const ValueKey('handover-delete-confirm')));
      expect(repo.deleted, ['h2']);
    });

    testWidgets('detail shows residents, incidents, jobs and notes; notes '
        'and taking post to the API', (tester) async {
      final repo = await _openHandovers(tester);

      await _tap(tester, find.byKey(const ValueKey('handover-open-h1')));
      expect(find.text('Jamal Uddin · 27/08/2026 09:33'), findsWidgets);
      expect(find.text('From 27/08/2026'), findsOneWidget);
      expect(find.text('Residents (1)'), findsOneWidget);
      expect(find.text('HEALTH'), findsOneWidget);
      expect(find.text('General condition: Calm', findRichText: true), findsOneWidget);
      expect(find.text('Prn given: Paracetamol 500mg', findRichText: true), findsOneWidget);
      expect(find.text('Done: Personal care, Hygiene'), findsOneWidget);
      expect(find.text('Still to do: Offer a snack before bed'), findsOneWidget);
      expect(find.text('Incidents on this shift'), findsOneWidget);
      expect(find.text('INC-7 · Fall · low'), findsOneWidget);
      expect(find.text('Outstanding jobs'), findsOneWidget);
      expect(find.text('Important'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('audit comment'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('handover-note-field')),
          matching: find.byType(TextField),
        ),
        'Pharmacy called back',
      );
      await tester.pump();
      await _tap(tester, find.byKey(const ValueKey('handover-add-note')));
      expect(repo.comments, [('h1', 'Pharmacy called back')]);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('handover-take-note')),
          matching: find.byType(TextField),
        ),
        'On it',
      );
      await _tap(tester, find.byKey(const ValueKey('handover-detail-take')));
      expect(repo.acknowledged, [('h1', 'On it')]);
    });

    testWidgets('Record handover walks residence, shift, incoming shift, '
        'jobs, residents and flag, then posts the web body', (tester) async {
      final repo = await _openHandovers(tester);

      await _tap(tester, find.byKey(const ValueKey('handovers-record')));
      expect(find.text('Record handover'), findsOneWidget);
      expect(
        find.text('What the next shift needs to know before it starts.'),
        findsOneWidget,
      );
      expect(
        find.text('You have no shifts of your own in the last day, so name the home.'),
        findsOneWidget,
      );
      expect(find.text('Choose a residence above'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('record-handover-submit')));
      expect(
        find.text('Choose the shift you are handing over — or a residence — '
            'and write a summary.'),
        findsOneWidget,
      );
      expect(repo.created, isEmpty);

      await _choose(
        tester,
        find.byKey(const ValueKey('record-handover-residence')),
        'Elm House',
      );
      expect(find.text('Which shift is this handover about?'), findsOneWidget);
      const dayLabel =
          'Morning — Day shift · Elm House · Tue 29/09/2026 07:00–15:00 · Jamal Uddin';
      await _choose(tester, find.byKey(const ValueKey('record-handover-shift')), dayLabel);
      expect(find.text('HANDING OVER'), findsOneWidget);
      expect(repo.incomingAfter.last, DateTime(2026, 9, 29, 15));

      await _choose(
        tester,
        find.byKey(const ValueKey('record-handover-applies')),
        'Night · Tue 29/09/2026 15:00–23:00 · Maya Rahman +1',
      );
      expect(
        find.text('Maya Rahman and 1 other will see it when they clock in, and '
            'the outstanding jobs are theirs.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('record-handover-summary')),
          matching: find.byType(TextField),
        ),
        'Calm afternoon',
      );
      await tester.enterText(
        find.byKey(const ValueKey('record-handover-job-input')),
        'Monitor temperature',
      );
      await _tap(tester, find.byKey(const ValueKey('record-handover-priority-urgent')));
      await _tap(tester, find.byKey(const ValueKey('record-handover-job-add')));
      expect(find.text('Monitor temperature'), findsOneWidget);

      await _choose(
        tester,
        find.byKey(const ValueKey('record-handover-add-client')),
        'Ayaan Karim',
      );
      expect(find.text('Client updates (1)'), findsOneWidget);
      expect(
        find.text('Every resident here is already on this handover'),
        findsOneWidget,
      );
      await _choose(
        tester,
        find.byKey(const ValueKey('client-client-ayaan-status')),
        'Needs attention',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('client-client-ayaan-mood')),
          matching: find.byType(TextField),
        ),
        'Cheerful',
      );
      await _tap(tester, find.byKey(const ValueKey('client-client-ayaan-care-feeding')));

      await _choose(tester, find.byKey(const ValueKey('record-handover-flag')), 'Medical');
      await _tap(tester, find.byKey(const ValueKey('record-handover-submit')));

      expect(repo.created.single, {
        'residenceId': 'elm',
        'summary': 'Calm afternoon',
        'pendingActions': [
          {'title': 'Monitor temperature', 'priority': 'urgent'},
        ],
        'clientUpdates': [
          {
            'clientId': 'client-ayaan',
            'status': 'needs_attention',
            'health': {'mood': 'Cheerful'},
            'care': {
              'completed': ['feeding'],
            },
          },
        ],
        'status': 'submitted',
        'fromShiftId': 'shift-day',
        'toShiftId': 'shift-night',
        'flagForAttention': {'category': 'medical'},
      });
      expect(find.text('Handed to 2 on the incoming shift'), findsOneWidget);
      expect(find.text('Record handover'), findsNothing);
    });

    testWidgets('empty list uses the web empty state', (tester) async {
      await _openHandovers(tester, items: const []);
      expect(find.text('No handovers yet'), findsOneWidget);
      expect(
        find.text('What one shift tells the next will appear here.'),
        findsOneWidget,
      );
    });
  });

  group('BUG11 Recurring Checks', () {
    final today = RecurringChecksController.dayKey(DateTime.now());

    test('the Manager menu lists Recurring Checks', () {
      Get.put<UserSession>(_Session());
      expect(managerDestinations().map((d) => d.title), contains('Recurring Checks'));
    });

    test('"How often" reads like the web', () {
      String w(CheckSchedule s) => CheckLabels.describeFrequency(s);
      CheckSchedule s({
        String? frequency,
        int? interval,
        List<int> times = const [],
        List<int> days = const [],
        int? dom,
      }) =>
          CheckSchedule(
            id: 'x',
            clientId: 'c',
            residenceId: 'r',
            frequency: frequency,
            intervalMinutes: interval,
            timesOfDay: times,
            weekdays: days,
            dayOfMonth: dom,
          );
      expect(w(s(frequency: 'interval', interval: 30)), 'Every 30 minutes');
      expect(w(s(frequency: 'interval')), 'No schedule set');
      expect(w(s(frequency: 'daily', times: [480, 1230])), 'Daily at 08:00, 20:30');
      expect(w(s(frequency: 'daily')), 'Daily');
      expect(w(s(frequency: 'weekly', days: [1, 3], times: [480])), 'Mon, Wed at 08:00');
      expect(w(s(frequency: 'weekly')), 'Weekly');
      expect(w(s(frequency: 'monthly', dom: 15, times: [540])), 'Day 15 of each month at 09:00');
    });

    testWidgets('Schedules tab: web columns, pagination, Pause / Resume and '
        'Delete with the web confirm', (tester) async {
      final repo = await _openChecks(tester);

      expect(find.text('Recurring Checks'), findsOneWidget);
      expect(find.byKey(const ValueKey('checks-record-progress')), findsOneWidget);
      expect(find.byKey(const ValueKey('checks-new-schedule')), findsOneWidget);
      for (final tab in ['Schedules', 'Due', 'Checks']) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(repo.schedulePages, [(1, 20)]);
      expect(find.text('Half-hourly welfare check'), findsOneWidget);
      expect(find.text('Ayaan Karim · Elm House'), findsNWidgets(2));
      expect(find.text('Every 30 minutes'), findsOneWidget);
      expect(find.text('Mon, Wed at 08:00, 20:00'), findsOneWidget);
      expect(find.text('Assign'), findsOneWidget);
      expect(find.text('Maya Rahman'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Showing 1 to 2 of 2 entries'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('schedule-toggle-s1')));
      await _tap(tester, find.byKey(const ValueKey('schedule-toggle-s2')));
      expect(_calls(repo.scheduleUpdates), [
        ['s1', {'isActive': false}],
        ['s2', {'isActive': true}],
      ]);

      await _tap(tester, find.byKey(const ValueKey('schedule-delete-s1')));
      expect(find.text('Delete this recurring check?'), findsOneWidget);
      expect(
        find.text('It stops producing checks and leaves the list. The checks already '
            'recorded against it are kept, so it can be restored.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('schedule-delete-confirm')));
      await tester.pumpAndSettle();
      expect(repo.deleted, ['s1']);
      expect(find.text('Check deleted'), findsOneWidget);
    });

    testWidgets('"Who usually does this" assigns a colleague or unassigns', (tester) async {
      final repo = await _openChecks(tester);

      await _tap(tester, find.byKey(const ValueKey('schedule-who-s1')));
      expect(find.text('Who usually does this'), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule-unassign')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('schedule-colleague-staff-jamal')));
      await tester.pumpAndSettle();
      expect(_calls(repo.scheduleUpdates).last, ['s1', {'assignedStaffId': 'staff-jamal'}]);
      expect(find.text('Half-hourly welfare check assigned to Jamal Uddin'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('schedule-who-s2')));
      await tester.tap(find.byKey(const ValueKey('schedule-unassign')));
      await tester.pumpAndSettle();
      expect(_calls(repo.scheduleUpdates).last, ['s2', {'assignedStaffId': null}]);
      expect(find.text('Blood pressure is no longer assigned to anybody'), findsOneWidget);
    });

    testWidgets('without write permission the schedule actions are hidden', (tester) async {
      await _openChecks(tester, denied: {'recurring-checks:write'});
      expect(find.byKey(const ValueKey('checks-new-schedule')), findsNothing);
      expect(find.byKey(const ValueKey('checks-record-progress')), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule-edit-s1')), findsNothing);
      expect(find.text('Whoever is on shift'), findsOneWidget);
    });

    testWidgets('Due tab: day / status / mine filters hit the API and cards show '
        'the web status, Late and assignee lines', (tester) async {
      final repo = _FakeChecksRepo()
        ..instanceItems = [
          _instance('i1', dueAt: DateTime.now().subtract(const Duration(hours: 1))),
          _instance('i2', status: 'needs_assignment', assignedRole: 'nurse'),
          _instance(
            'i3',
            status: 'completed',
            entry: CheckEntry(
              id: 'e1',
              note: 'Settled',
              staffName: 'Jamal Uddin',
              checkedAt: DateTime(2026, 9, 29, 9, 5),
              result: const {'systolic': 120, 'systolicUnit': 'mmHg'},
            ),
          ),
          _instance('i4', status: 'skipped', statusNote: 'At hospital', statusOnDuty: false),
        ];
      await _openChecks(tester, repo: repo);

      await _tap(tester, find.byKey(const ValueKey('checks-tab-due')));
      expect(repo.instanceQueries.last,
          {'day': today, 'residenceId': null, 'status': null, 'mine': false});
      expect(find.text('All my residences'), findsOneWidget);
      expect(find.text(WebFormat.date(DateTime.now())), findsOneWidget);
      expect(find.text('Any status'), findsOneWidget);
      expect(find.text('Checks assigned to me'), findsOneWidget);

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Needs assignment'), findsOneWidget);
      expect(find.text('Nurse on shift'), findsOneWidget);
      expect(find.text('Nobody is on shift when this falls due.'), findsOneWidget);
      expect(find.text('Whoever is on shift'), findsNWidgets(3));
      expect(find.text('systolic: 120 mmHg'), findsOneWidget);
      expect(find.text('Jamal Uddin · 29/09/2026 09:05'), findsOneWidget);
      expect(find.textContaining('Skipped: At hospital'), findsOneWidget);
      expect(find.byKey(const ValueKey('check-assign-i2')), findsOneWidget);
      expect(find.byKey(const ValueKey('check-assign-i1')), findsNothing);
      expect(find.byKey(const ValueKey('check-record-i3')), findsNothing);

      await _choose(tester, find.byKey(const ValueKey('checks-status-filter')), 'Missed');
      expect(repo.instanceQueries.last['status'], 'missed');
      await _choose(tester, find.byKey(const ValueKey('checks-residence-filter')), 'Oak Lodge');
      expect(repo.instanceQueries.last['residenceId'], 'oak');
      await _tap(tester, find.byKey(const ValueKey('checks-mine-filter')));
      expect(repo.instanceQueries.last['mine'], true);
    });

    testWidgets('Assign lists who is on shift and can apply to future checks', (tester) async {
      final repo = _FakeChecksRepo()
        ..instanceItems = [_instance('i2', status: 'needs_assignment')];
      await _openChecks(tester, repo: repo);
      await _tap(tester, find.byKey(const ValueKey('checks-tab-due')));

      await _tap(tester, find.byKey(const ValueKey('check-assign-i2')));
      expect(find.text('On shift when this is due'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('assign-apply-future')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('assign-staff-staff-maya')));
      await tester.pumpAndSettle();
      expect(_calls(repo.instanceUpdates), [
        ['i2', {'assignedStaffId': 'staff-maya', 'applyToSchedule': true}],
      ]);
      expect(find.text('Blood pressure assigned to Maya Rahman, and to future checks'),
          findsOneWidget);
    });

    testWidgets('a check assigned to someone else is locked without manage', (tester) async {
      final repo = _FakeChecksRepo()
        ..instanceItems = [
          _instance('i5', assignedStaffId: 'staff-maya', assignedStaffName: 'Maya Rahman'),
        ];
      await _openChecks(tester, repo: repo, denied: {'recurring-checks:manage'});
      await _tap(tester, find.byKey(const ValueKey('checks-tab-due')));

      expect(find.text('Assigned to Maya Rahman'), findsOneWidget);
      expect(
        find.text('Assigned to Maya Rahman — reassign it before recording or skipping.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('check-assign-i5')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('check-record-i5')));
      await tester.pumpAndSettle();
      expect(find.text('What you saw *', findRichText: true), findsNothing);
    });

    testWidgets('Skip needs a reason and sends status skipped', (tester) async {
      final repo = _FakeChecksRepo()..instanceItems = [_instance('i1')];
      await _openChecks(tester, repo: repo);
      await _tap(tester, find.byKey(const ValueKey('checks-tab-due')));

      await _tap(tester, find.byKey(const ValueKey('check-skip-i1')));
      expect(find.text('Skip this check'), findsOneWidget);
      expect(find.text('Blood pressure · Ayaan Karim'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('skip-check-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Say why the check could not be done.'), findsOneWidget);
      expect(repo.instanceUpdates, isEmpty);

      await _enter(tester, const ValueKey('skip-check-why'), 'Out at hospital');
      await tester.tap(find.byKey(const ValueKey('skip-check-submit')));
      await tester.pumpAndSettle();
      expect(_calls(repo.instanceUpdates), [
        ['i1', {'status': 'skipped', 'statusNote': 'Out at hospital'}],
      ]);
      expect(find.text('Check skipped'), findsOneWidget);
    });

    testWidgets('Record check: vital sign readings, on-behalf reason, outcome '
        'and the web body', (tester) async {
      final repo = _FakeChecksRepo()
        ..instanceItems = [
          _instance('i6', assignedStaffId: 'staff-maya', assignedStaffName: 'Maya Rahman'),
        ];
      await _openChecks(tester, repo: repo);
      await _tap(tester, find.byKey(const ValueKey('checks-tab-due')));
      await _tap(tester, find.byKey(const ValueKey('check-record-i6')));

      expect(find.textContaining('Ayaan Karim · due'), findsWidgets);
      expect(find.textContaining('You are not clocked in at this home.'), findsOneWidget);
      expect(find.text('INSTRUCTIONS'), findsOneWidget);
      for (final label in [
        'Systolic (mmHg)',
        'Diastolic (mmHg)',
        'Pulse (bpm)',
        'Temperature (°C)',
      ]) {
        expect(find.text(label, findRichText: true), findsOneWidget);
      }
      expect(find.textContaining('You are recording it on their behalf.', findRichText: true),
          findsOneWidget);

      await _tapInSheet(tester, find.byKey(const ValueKey('record-check-submit')));
      expect(find.text('Say what you saw — a tick with nothing written is not evidence.'),
          findsOneWidget);

      await _enter(tester, const ValueKey('record-reading-systolic'), '150');
      await _enter(tester, const ValueKey('record-check-note'), 'Headache');
      await _tapInSheet(tester, find.byKey(const ValueKey('record-check-submit')));
      expect(
        find.text('This check is assigned to Maya Rahman — say why you are recording it for them.'),
        findsOneWidget,
      );

      await _enter(tester, const ValueKey('record-check-takeover'), 'On her break');
      await _chooseInSheet(
          tester, find.byKey(const ValueKey('record-check-outcome')), 'Needs attention');
      expect(find.text('Stays open'), findsOneWidget);
      await _tapInSheet(tester, find.byKey(const ValueKey('record-check-submit')));

      final body = repo.recorded.single;
      expect(body['scheduleId'], 's2');
      expect(body['instanceId'], 'i6');
      expect(body['clientId'], 'c1');
      expect(body.containsKey('staffId'), isFalse);
      expect(body['note'], 'Headache');
      expect(body['result'], {'systolic': 150, 'systolicUnit': 'mmHg'});
      expect(body['outcome'], 'needs_attention');
      expect(body['takeoverReason'], 'On her break');
      expect(DateTime.tryParse(body['checkedAt'] as String), isNotNull);
      expect(find.text('Recorded — sent for review'), findsOneWidget);
    });

    testWidgets('Record Progress picks a resident, then their schedule', (tester) async {
      final repo = _FakeChecksRepo()
        ..byClient = {
          'c1': [_bp],
        };
      await _openChecks(tester, repo: repo);
      await _tap(tester, find.byKey(const ValueKey('checks-record-progress')));

      expect(find.text('Record a resident welfare observation, vital check, or care progress'),
          findsOneWidget);
      await _chooseInSheet(
          tester, find.byKey(const ValueKey('record-check-resident')), 'Ayaan Karim');
      expect(find.text('Blood pressure (vital_signs)'), findsOneWidget);
      expect(find.text('Systolic (mmHg)', findRichText: true), findsOneWidget);

      await _enter(tester, const ValueKey('record-check-note'), 'Settled');
      await _tapInSheet(tester, find.byKey(const ValueKey('record-check-submit')));
      final body = repo.recorded.single;
      expect(body['scheduleId'], 's2');
      expect(body['clientId'], 'c1');
      expect(body.containsKey('instanceId'), isFalse);
      expect(body.containsKey('result'), isFalse);
      expect(body['outcome'], 'normal');
      expect(find.text('Check recorded'), findsOneWidget);
    });

    testWidgets('Record Progress explains a resident without a schedule', (tester) async {
      await _openChecks(tester);
      await _tap(tester, find.byKey(const ValueKey('checks-record-progress')));
      await _chooseInSheet(
          tester, find.byKey(const ValueKey('record-check-resident')), 'Ayaan Karim');
      expect(find.text('No active recurring check schedule for this resident'), findsOneWidget);
    });

    testWidgets('New Schedule validates like the web and sends the web body', (tester) async {
      final repo = await _openChecks(tester);
      await _tap(tester, find.byKey(const ValueKey('checks-new-schedule')));
      expect(find.text('New recurring check'), findsOneWidget);
      expect(find.text('What is checked, how often, and who is expected to do it.'),
          findsOneWidget);

      Future<void> submit() =>
          _tapInSheet(tester, find.byKey(const ValueKey('schedule-form-submit')));

      await submit();
      expect(find.text('Choose a residence and a resident.'), findsOneWidget);

      await _chooseInSheet(
          tester, find.byKey(const ValueKey('schedule-form-residence')), 'Elm House');
      expect(repo.clientQueries.last, 'elm');
      await _chooseInSheet(
          tester, find.byKey(const ValueKey('schedule-form-resident')), 'Ayaan Karim');
      await submit();
      expect(find.text('Give the check a name — a nameless schedule is a row of ids.'),
          findsOneWidget);

      await _enter(tester, const ValueKey('schedule-form-name'), 'Blood pressure');
      await _chooseInSheet(tester, find.byKey(const ValueKey('schedule-form-type')), 'Vital signs');
      await _chooseInSheet(tester, find.byKey(const ValueKey('schedule-form-frequency')),
          'Weekly, on set days');
      expect(find.text('08:00'), findsOneWidget);
      await _tapInSheet(tester, find.byKey(const ValueKey('schedule-form-add-time')));
      expect(find.text('12:00'), findsOneWidget);
      for (final day in [1, 3, 5]) {
        await _tapInSheet(tester, find.byKey(ValueKey('schedule-form-weekday-$day')));
      }
      await submit();
      expect(find.text('Choose at least one day of the week.'), findsOneWidget);
      await _tapInSheet(tester, find.byKey(const ValueKey('schedule-form-weekday-2')));

      await _tapInSheet(tester, find.byKey(const ValueKey('schedule-form-alert')));
      expect(find.textContaining('Any one of these is enough to raise it'), findsOneWidget);
      await _chooseInSheet(tester, find.byKey(const ValueKey('rule-field-0')), 'Systolic (mmHg)');
      await _enter(tester, const ValueKey('rule-value-0'), '140');
      await _chooseInSheet(tester, find.byKey(const ValueKey('rule-severity-0')), 'Urgent');
      await _tapInSheet(tester, find.byKey(const ValueKey('rule-incident-0')));
      await _tapInSheet(tester, find.byKey(const ValueKey('schedule-form-notify-nurse')));
      await _chooseInSheet(tester, find.byKey(const ValueKey('schedule-form-role')), 'Nurse');

      await submit();
      expect(repo.created.single, {
        'clientId': 'c1',
        'residenceId': 'elm',
        'name': 'Blood pressure',
        'checkType': 'vital_signs',
        'frequency': 'weekly',
        'timesOfDay': [480, 720],
        'weekdays': [2],
        'assignedRole': 'nurse',
        'alertEnabled': true,
        'alertRules': {
          'rules': [
            {
              'field': 'systolic',
              'operator': 'gt',
              'value': 140,
              'severity': 'urgent',
              'raiseIncident': true,
            },
          ],
          'notifyRoles': ['nurse'],
        },
      });
      expect(find.text('Recurring check created'), findsOneWidget);
    });

    testWidgets('Edit prefills the schedule and saves without the resident', (tester) async {
      final repo = await _openChecks(tester);
      await _tap(tester, find.byKey(const ValueKey('schedule-edit-s2')));

      expect(find.text('Edit recurring check'), findsOneWidget);
      expect(find.text('Ayaan Karim · Elm House'), findsWidgets);
      expect(find.text('Weekly, on set days'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('22/09/2026'), findsNothing);
      expect(find.text('21/09/2026'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);

      await _tapInSheet(tester, find.byKey(const ValueKey('schedule-form-submit')));
      final (id, body) = repo.scheduleUpdates.single;
      expect(id, 's2');
      expect(body.containsKey('clientId'), isFalse);
      expect(body['timesOfDay'], [480, 1200]);
      expect(body['weekdays'], [1, 3]);
      expect(body['assignedStaffId'], 'staff-maya');
      expect(body['alertRules'], {
        'rules': [
          {
            'field': 'systolic',
            'operator': 'gt',
            'value': 140,
            'severity': 'urgent',
            'raiseIncident': false,
          },
        ],
        'notifyRoles': ['nurse'],
      });
      expect(body['effectiveFrom'], DateTime(2026, 9, 21).toUtc().toIso8601String());
      expect(find.text('Check updated'), findsOneWidget);
    });

    testWidgets('Checks tab shows recorded checks with the web pills', (tester) async {
      final repo = _FakeChecksRepo()
        ..entryItems = [
          CheckEntry(
            id: 'e1',
            checkName: 'Blood pressure',
            note: 'Headache',
            staffName: 'Jamal Uddin',
            checkedAt: DateTime(2026, 9, 29, 9, 5),
            outcome: 'urgent',
            recordedOnDuty: false,
            coveredForName: 'Maya Rahman',
            takeoverReason: 'On her break',
            result: const {'systolic': 150, 'systolicUnit': 'mmHg'},
          ),
        ];
      await _openChecks(tester, repo: repo);
      await _tap(tester, find.byKey(const ValueKey('checks-tab-checks')));

      expect(repo.entryQueries.last,
          {'day': today, 'residenceId': null, 'outcome': null, 'mine': false});
      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('Off duty'), findsOneWidget);
      expect(find.text('Covered for Maya Rahman'), findsOneWidget);
      expect(find.text('Jamal Uddin · 29/09/2026 09:05'), findsOneWidget);
      expect(find.text('systolic: 150 · systolicUnit: mmHg'), findsOneWidget);
      expect(find.text('Taken over: On her break'), findsOneWidget);

      repo.entryItems = [];
      await _choose(tester, find.byKey(const ValueKey('checks-status-filter')), 'Completed');
      expect(repo.entryQueries.last['outcome'], 'completed');
      expect(find.text('No checks were recorded for these filters.'), findsOneWidget);
    });
  });

  group('BUG13 Daily Logs', () {
    final now = DateTime.now();
    final today = DailyLogsController.dayKey(now);
    final weekAgo = DailyLogsController.dayKey(now.subtract(const Duration(days: 6)));
    String shown(String key) => WebFormat.date(DateTime.parse(key));
    Finder inKey(String key, Finder matching) =>
        find.descendant(of: find.byKey(ValueKey(key)), matching: matching);

    test('mapper reads the live payloads; window label and default time match the web', () {
      expect(DailyLogsMapper.dayFrom({'success': true, 'data': null}), isNull);
      final day = DailyLogsMapper.dayFrom({
        'data': {
          'entries': [
            {
              'id': 'e1',
              'body': 'Hi',
              'occurredAt': '2026-08-27T04:33:06.745Z',
              'author': {'name': 'Jamal Uddin'},
              'isSuperseded': true,
              'observations': null,
              'wellnessCheckCompleted': false,
              'attachments': [
                {'id': 'a', 'fileUrl': 'https://x/uploads/chart.pdf'},
              ],
              'flag': {'category': 'medical', 'raisedAt': '2026-08-27T05:00:00Z'},
            },
          ],
          'checks': [
            {
              'id': 'k',
              'checkedAt': '2026-08-27T08:33:06.745Z',
              'note': 'ok',
              'result': null,
              'outcome': 'normal',
              'recordedBy': 'Jamal Uddin',
            },
          ],
        },
      })!;
      final e = day.entries.single;
      expect(e.authorName, 'Jamal Uddin');
      expect(e.isSuperseded, isTrue);
      expect(e.observations, isEmpty);
      expect(e.wellnessCheckCompleted, isFalse);
      expect(e.attachments.single.fileName, 'chart.pdf');
      expect(e.flag!.category, 'medical');
      expect(day.checks.single.recordedBy, 'Jamal Uddin');

      final review = DailyLogsMapper.reviewFrom({
        'data': [
          {'id': 'd', 'clientId': 'c', 'clientName': 'A', 'logDate': '2026-08-27T00:00:00.000Z', 'entriesCount': 2},
        ],
        'meta': {'total': 9, 'totalPages': 1},
      });
      expect(review.items.single.logDate, '2026-08-27');
      expect(review.total, 9);

      final flags = DailyLogsMapper.flagsFrom({
        'data': [
          {'id': 'f', 'category': 'medical', 'raisedAt': '2026-09-29T08:15:27.567Z', 'source': null},
        ],
        'meta': {'total': 3},
      });
      expect(flags.items.single.source, isNull);
      expect(flags.total, 3);

      expect(DailyLogLabels.window('2026-09-17', '2026-09-23'), 'Sep 17 – Sep 23');
      expect(DailyLogLabels.window('2026-09-23', '2026-09-23'), 'Sep 23');
      final clock = DateTime(2026, 9, 29, 9, 41);
      expect(NewLogEntrySheet.defaultOccurredAt('2026-09-29', now: clock), clock);
      expect(NewLogEntrySheet.defaultOccurredAt('2026-08-27', now: clock), DateTime(2026, 8, 27, 12));
    });

    testWidgets('starts on "Choose a residence to begin" with Residence*, Resident and '
        'From / To defaulting to the last seven days', (tester) async {
      final (repo, _) = await _openLogs(tester);

      expect(find.text('Daily Logs'), findsOneWidget);
      expect(_label('Residence *'), findsOneWidget);
      expect(find.text('Choose a residence'), findsOneWidget);
      expect(find.text('Choose a residence first'), findsOneWidget);
      expect(inKey('dl-from', find.text(shown(weekAgo))), findsOneWidget);
      expect(inKey('dl-to', find.text(shown(today))), findsOneWidget);
      for (final tab in ['To review', 'Missing', 'Resident day view', 'House activity']) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(find.text('Choose a residence to begin'), findsOneWidget);
      expect(find.text('Daily logs are read one residence at a time.'), findsOneWidget);
      expect(find.byKey(const ValueKey('dl-kpi-entries')), findsNothing);
      expect(find.byKey(const ValueKey('dl-shift-docs')), findsNothing);
      expect(repo.queueQueries, isEmpty);
      expect(repo.flagQueries, [null]);

      await tester.tap(find.byKey(const ValueKey('dl-from')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('choosing a residence loads both queues, the KPIs and the resident list; '
        'Resident filters and a new residence clears it', (tester) async {
      final (repo, _) = await _openLogs(tester);
      await _pickResidence(tester);

      Map<String, Object?> q(String status, {String r = 'elm', String? c}) => {
            'status': status,
            'residenceId': r,
            'clientId': c,
            'from': weekAgo,
            'to': today,
            'page': 1,
            'limit': 20,
          };
      expect(repo.queueQueries, [q('review'), q('missing')]);
      expect(repo.clientQueries, ['elm']);
      expect(repo.shiftQueries, [
        {'residenceId': 'elm', 'logDate': today},
      ]);
      expect(repo.flagQueries, [null, 'elm']);

      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      String md(String key) {
        final d = DateTime.parse(key);
        return '${months[d.month - 1]} ${d.day}';
      }

      expect(inKey('dl-kpi-entries', find.text('5')), findsOneWidget);
      expect(inKey('dl-kpi-entries', find.text('ENTRIES LOGGED')), findsOneWidget);
      expect(inKey('dl-kpi-entries', find.text('${md(weekAgo)} – ${md(today)}')), findsOneWidget);
      expect(inKey('dl-kpi-review', find.text('7')), findsOneWidget);
      expect(inKey('dl-kpi-review', find.text('Resident-days with entries on them')), findsOneWidget);
      expect(inKey('dl-kpi-missing', find.text('4')), findsOneWidget);
      expect(inKey('dl-kpi-missing', find.text('Resident-days with nothing written')), findsOneWidget);
      expect(inKey('dl-kpi-flags', find.text('2')), findsOneWidget);
      expect(inKey('dl-kpi-flags', find.text('Raised and not yet resolved')), findsOneWidget);

      expect(inKey('dl-review-c1-2026-08-27', find.text('Ayaan Karim')), findsOneWidget);
      expect(inKey('dl-review-c1-2026-08-27', find.text('2026-08-27')), findsOneWidget);
      expect(inKey('dl-review-c1-2026-08-27', find.text('2')), findsOneWidget);
      expect(find.text('Open day'), findsNWidgets(2));

      await _choose(tester, find.byKey(const ValueKey('dl-resident')), 'Nadia Islam');
      expect(repo.queueQueries.sublist(2), [q('review', c: 'c2'), q('missing', c: 'c2')]);

      await _pickResidence(tester, 'Oak Lodge');
      expect(find.text('Choose a resident'), findsOneWidget);
      expect(repo.queueQueries.sublist(4), [q('review', r: 'oak'), q('missing', r: 'oak')]);
      expect(repo.clientQueries, ['elm', 'oak']);
    });

    testWidgets('From after To (or To before From) collapses both, as the web does', (tester) async {
      final (repo, c) = await _openLogs(tester);
      await _pickResidence(tester);

      c.setFrom('2099-01-01');
      expect((c.from.value, c.to.value), ('2099-01-01', '2099-01-01'));
      c.setTo('2000-01-01');
      expect((c.from.value, c.to.value), ('2000-01-01', '2000-01-01'));
      c.setFrom('2026-09-17');
      c.setTo('2026-09-23');
      await tester.pumpAndSettle();
      expect((c.from.value, c.to.value), ('2026-09-17', '2026-09-23'));
      expect(repo.queueQueries.last['from'], '2026-09-17');
      expect(repo.queueQueries.last['to'], '2026-09-23');
      expect(inKey('dl-kpi-entries', find.text('Sep 17 – Sep 23')), findsOneWidget);
      expect(inKey('dl-from', find.text('17/09/2026')), findsOneWidget);
      expect(inKey('dl-to', find.text('23/09/2026')), findsOneWidget);
    });

    testWidgets('Missing tab "Write entry" opens that resident-day with a Date picker and '
        'Add Entry', (tester) async {
      final (repo, c) = await _openLogs(tester);
      await _pickResidence(tester);

      await _tap(tester, find.byKey(const ValueKey('dl-tab-day')));
      expect(find.text('A day view is one resident on one date.'), findsOneWidget);
      expect(find.byKey(const ValueKey('dl-add-entry')), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('dl-tab-missing')));
      expect(find.text('DAY WITH NO LOG'), findsOneWidget);
      expect(inKey('dl-missing-c2-2026-08-28', find.text('2026-08-28')), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('dl-write-c2-2026-08-28')));
      expect(c.tab.value, DailyLogsTab.day);
      expect(repo.dayQueries.last, {'clientId': 'c2', 'residenceId': 'elm', 'logDate': '2026-08-28'});
      expect(repo.shiftQueries.last, {'residenceId': 'elm', 'logDate': '2026-08-28'});
      expect(inKey('dl-date', find.text('28/08/2026')), findsOneWidget);
      expect(find.byKey(const ValueKey('dl-from')), findsNothing);
      expect(find.byKey(const ValueKey('dl-kpi-entries')), findsNothing);
      expect(inKey('dl-resident', find.text('Nadia Islam')), findsOneWidget);
      expect(find.byKey(const ValueKey('dl-add-entry')), findsOneWidget);
    });

    testWidgets('a resident outside the client list keeps the queue row name', (tester) async {
      final repo = _FakeDailyLogsRepo()..clientRows = const [];
      await _openLogs(tester, repo: repo);
      await _pickResidence(tester);

      await _tap(tester, find.byKey(const ValueKey('dl-open-day-c1-2026-08-27')));
      expect(inKey('dl-resident', find.text('Ayaan Karim')), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('dl-add-entry')));
      expect(find.text('Care documentation for Ayaan Karim on 2026-08-27.'), findsOneWidget);
    });

    testWidgets('day timeline: entries and checks by time with every web pill', (tester) async {
      final (repo, _) = await _openLogs(tester);
      await _pickResidence(tester);
      await _tap(tester, find.byKey(const ValueKey('dl-open-day-c1-2026-08-27')));
      expect(repo.dayQueries.last, {'clientId': 'c1', 'residenceId': 'elm', 'logDate': '2026-08-27'});

      double top(String key) => tester.getTopLeft(find.byKey(ValueKey(key))).dy;
      expect(top('dl-entry-e1') < top('dl-entry-e2'), isTrue);
      expect(top('dl-entry-e2') < top('dl-check-k1'), isTrue);
      expect(top('dl-check-k1') < top('dl-entry-e3'), isTrue);

      Finder e3(String text) => inKey('dl-entry-e3', find.text(text));
      expect(e3('Maya Rahman'), findsOneWidget);
      expect(e3('27/08/2026 14:05'), findsOneWidget);
      expect(e3('afternoon'), findsOneWidget);
      expect(e3('medical · flagged'), findsOneWidget);
      expect(e3('Mood: settled'), findsOneWidget);
      expect(e3('Community outing: yes'), findsOneWidget);
      expect(e3('Outing notes: Park'), findsOneWidget);
      expect(e3('Wellness check done'), findsOneWidget);
      expect(e3('Bed check not done'), findsOneWidget);
      expect(e3('Reminder 27/08/2026 18:00'), findsOneWidget);
      expect(e3('chart.pdf'), findsOneWidget);

      expect(inKey('dl-entry-e1', find.text('Superseded')), findsOneWidget);
      final struck = tester.widget<Text>(inKey('dl-entry-e1', find.text('Left for school on time.')));
      expect(struck.style!.decoration, TextDecoration.lineThrough);
      expect(find.byKey(const ValueKey('dl-entry-amend-e1')), findsNothing);
      expect(find.byKey(const ValueKey('dl-entry-delete-e1')), findsOneWidget);

      expect(inKey('dl-entry-e2', find.text('Correction')), findsOneWidget);
      expect(
        inKey('dl-entry-e2', find.text('Reason for correction: Time was recorded incorrectly.')),
        findsOneWidget,
      );
      expect(inKey('dl-entry-e2', find.textContaining('Wellness check')), findsNothing);

      Finder k1(String text) => inKey('dl-check-k1', find.text(text));
      expect(k1('Check'), findsOneWidget);
      expect(k1('Blood pressure'), findsOneWidget);
      expect(k1('27/08/2026 10:00 · Jamal Uddin'), findsOneWidget);
      expect(k1('needs review'), findsOneWidget);
      expect(k1('Slightly high'), findsOneWidget);
      expect(k1('systolic: 150 mmHg'), findsOneWidget);
    });

    testWidgets('View opens the entry with its correction history; Amend and Delete call '
        'the API', (tester) async {
      final (repo, _) = await _openLogs(tester);
      await _pickResidence(tester);
      await _tap(tester, find.byKey(const ValueKey('dl-open-day-c1-2026-08-27')));

      await _tap(tester, find.byKey(const ValueKey('dl-entry-view-e2')));
      expect(find.text('Log entry'), findsOneWidget);
      expect(find.text('27/08/2026 08:33'), findsWidgets);
      expect(find.text('Sleep_mood'), findsOneWidget);
      for (final text in [
        'AUTHOR',
        'OCCURRED AT',
        'WRITTEN AT',
        'REMINDER',
        'REASON FOR CORRECTION',
        'Observations',
        'MOOD',
        'Settled',
        'COMMUNITY OUTING',
        'Yes',
        'Wellness check completed',
        'Bed check not completed',
        'Correction history',
        'Original',
        'Correction 1',
        'This entry',
        'Reason: Time was recorded incorrectly.',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(find.byKey(const ValueKey('dl-detail-close')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('dl-detail-amend')));
      await tester.pumpAndSettle();
      expect(find.text('Amend entry'), findsOneWidget);
      expect(find.text('The original stays on the record; this correction is added beside it.'),
          findsOneWidget);
      expect(find.text('ORIGINAL ENTRY'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dl-amend-save')));
      await tester.pumpAndSettle();
      expect(find.text('Both the corrected entry and a reason are required.'), findsOneWidget);
      expect(repo.amended, isEmpty);

      await _enter(tester, const ValueKey('dl-amend-body'), 'Left 25 minutes late.');
      await _enter(tester, const ValueKey('dl-amend-reason'), 'Checked the transport log.');
      final dayLoads = repo.dayQueries.length;
      await tester.tap(find.byKey(const ValueKey('dl-amend-save')));
      await tester.pumpAndSettle();
      expect(repo.amended, [
        ['e2', 'Left 25 minutes late.', 'Checked the transport log.'],
      ]);
      expect(find.text('Correction recorded'), findsOneWidget);
      expect(repo.dayQueries.length, greaterThan(dayLoads));

      await _tap(tester, find.byKey(const ValueKey('dl-entry-delete-e3')));
      expect(find.text('Delete this entry?'), findsOneWidget);
      expect(
        find.text("It leaves the day's log. A correction to a note is an amendment, not this — "
            'what was written is kept either way, so it can be restored.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('dl-delete-confirm')));
      await tester.pumpAndSettle();
      expect(repo.deleted, ['e3']);
      expect(find.text('Entry deleted'), findsOneWidget);
    });

    testWidgets('Add Entry wizard: 3 steps, completion, summary, validation that jumps to '
        'the failing step, attachments and the web request body', (tester) async {
      final (repo, _) = await _openLogs(
        tester,
        pickFiles: () async => [('/tmp/chart.png', 'chart.png'), ('/tmp/letter.png', 'letter.png')],
      );
      await _pickResidence(tester);
      await _tap(tester, find.byKey(const ValueKey('dl-open-day-c1-2026-08-27')));
      await _tap(tester, find.byKey(const ValueKey('dl-add-entry')));

      expect(find.text('New Log Entry'), findsOneWidget);
      expect(find.text('Care documentation for Ayaan Karim on 2026-08-27.'), findsOneWidget);
      expect(find.text('DAILY LOG WORKFLOW'), findsOneWidget);
      for (final text in [
        'Who this is about, and when',
        'What happened, and how they were',
        'Checks, attachments and flags',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      Finder completion(String text) => inKey('dl-completion', find.text(text));
      expect(completion('Step 0 of 3'), findsOneWidget);
      expect(completion('0% complete'), findsOneWidget);
      expect(inKey('dl-new-occurred', find.text('27/08/2026 12:00')), findsOneWidget);
      expect(find.text('Defaults to now for today, and midday for a day being filled in.'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('dl-new-back')), findsNothing);
      expect(inKey('dl-entry-summary', find.text('None recorded')), findsOneWidget);
      expect(inKey('dl-entry-summary', find.text('NONE')), findsOneWidget);

      await _chooseInSheet(tester, find.byKey(const ValueKey('dl-new-shift')), 'Morning');
      await _chooseInSheet(tester, find.byKey(const ValueKey('dl-new-log-type')), 'Behaviour');
      expect(completion('Step 1 of 3'), findsOneWidget);
      expect(completion('33% complete'), findsOneWidget);
      expect(inKey('dl-entry-summary', find.text('Morning')), findsOneWidget);

      await _tapInSheet(tester, find.byKey(const ValueKey('dl-step-notesChecklist')));
      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-save')));
      expect(find.text('Write what happened'), findsOneWidget);
      expect(find.byKey(const ValueKey('dl-new-body')), findsOneWidget);
      expect(repo.created, isEmpty);

      await _enter(tester, const ValueKey('dl-new-body'), 'Ate breakfast');
      await _chooseInSheet(tester, find.byKey(const ValueKey('dl-new-mood')), 'Settled');
      await _enter(tester, const ValueKey('dl-new-meals'), 'Full');
      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-outing')));
      expect(find.byKey(const ValueKey('dl-new-outing-notes')), findsOneWidget);
      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-next')));
      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-flag')));
      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-save')));
      expect(find.text('Say where they went — the switch on its own records nothing'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('dl-new-outing-notes')), findsOneWidget);

      await _enter(tester, const ValueKey('dl-new-outing-notes'), 'Park');
      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-next')));
      await _enter(tester, const ValueKey('dl-new-behaviour'), 'Calm');
      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-wellness')));
      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-bed')));
      expect(completion('Step 3 of 3'), findsOneWidget);
      expect(completion('100% complete'), findsOneWidget);
      expect(inKey('dl-entry-summary', find.text('Wellness · Bed')), findsOneWidget);
      expect(inKey('dl-entry-summary', find.text('CATEGORY NEEDED')), findsOneWidget);

      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-save')));
      expect(find.text('Say what kind of concern this is'), findsOneWidget);
      expect(find.text('Say what needs attention'), findsOneWidget);
      await _chooseInSheet(tester, find.byKey(const ValueKey('dl-new-flag-category')), 'Medical');
      expect(inKey('dl-entry-summary', find.text('MEDICAL')), findsOneWidget);
      await _enter(tester, const ValueKey('dl-new-flag-note'), 'Cough');

      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-attach')));
      expect(repo.uploads, ['/tmp/chart.png', '/tmp/letter.png']);
      expect(find.text('letter.png'), findsOneWidget);
      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-attach-remove-1')));
      expect(find.text('letter.png'), findsNothing);

      await _tapInSheet(tester, find.byKey(const ValueKey('dl-new-save')));
      expect(repo.created, [
        {
          'clientId': 'c1',
          'residenceId': 'elm',
          'logDate': '2026-08-27',
          'body': 'Ate breakfast',
          'occurredAt': DateTime(2026, 8, 27, 12).toUtc().toIso8601String(),
          'shift': 'morning',
          'logType': 'behaviour',
          'observations': {
            'mood': 'settled',
            'meals': 'Full',
            'outingNotes': 'Park',
            'behaviorNotes': 'Calm',
            'communityOuting': true,
          },
          'wellnessCheckCompleted': true,
          'bedCheckCompleted': true,
          'attachments': [
            {'fileUrl': 'https://files/uploads/chart.png', 'fileType': 'image/png'},
          ],
          'flagForAttention': {'category': 'medical', 'note': 'Cough'},
        },
      ]);
      expect(find.text('Entry added'), findsOneWidget);
      expect(find.text('New Log Entry'), findsNothing);
    });

    testWidgets('Shift documentation saves, completes and signs off like the web', (tester) async {
      final (repo, _) = await _openLogs(tester);
      await _pickResidence(tester);

      Finder docs(String text) => inKey('dl-shift-docs', find.text(text));
      expect(docs('Shift documentation'), findsOneWidget);
      expect(docs('1 not started'), findsOneWidget);
      expect(inKey('dl-shift-sl1', find.text('Day shift')), findsOneWidget);
      expect(inKey('dl-shift-sl1', find.text('Not started')), findsOneWidget);
      expect(inKey('dl-shift-sl2', find.text('morning · 07:00–15:00')), findsOneWidget);
      expect(inKey('dl-shift-sl2', find.text('Completed')), findsOneWidget);
      expect(inKey('dl-shift-sl2', find.text('Completed by Jamal Uddin')), findsOneWidget);
      expect(find.byKey(const ValueKey('dl-shift-complete-sl2')), findsNothing);

      HandoverButton button(String key) => tester.widget<HandoverButton>(find.byKey(ValueKey(key)));
      expect(button('dl-shift-save-sl1').onPressed, isNull);
      expect(button('dl-shift-complete-sl1').onPressed, isNull);

      await _enter(tester, const ValueKey('dl-shift-summary-sl1'), 'All calm');
      await _tap(tester, find.byKey(const ValueKey('dl-shift-save-sl1')));
      expect(find.text('Summary saved'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('dl-shift-complete-sl1')));
      expect(find.text('Shift completed'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('dl-shift-signoff-sl2')));
      expect(find.text('Shift signed off'), findsOneWidget);
      expect(repo.shiftUpdates, [
        ['sl1', {'summary': 'All calm'}],
        ['sl1', {'summary': 'All calm', 'status': 'completed'}],
        ['sl2', {'status': 'locked'}],
      ]);
    });

    testWidgets('Shift documentation without write or review shows the summary read-only',
        (tester) async {
      await _openLogs(tester, denied: {'daily-logs:write', 'daily-logs:review'});
      await _pickResidence(tester);

      expect(find.byKey(const ValueKey('dl-shift-summary-sl2')), findsNothing);
      expect(inKey('dl-shift-sl2', find.text('Settled day.')), findsOneWidget);
      for (final key in ['dl-shift-save-sl1', 'dl-shift-complete-sl1', 'dl-shift-signoff-sl2']) {
        expect(find.byKey(ValueKey(key)), findsNothing, reason: key);
      }
    });

    testWidgets('Priority Notes list the open flags and Resolve records the note', (tester) async {
      final (repo, _) = await _openLogs(tester);
      await _pickResidence(tester);

      Finder f1(String text) => inKey('dl-flag-f1', find.text(text));
      expect(inKey('dl-priority-notes', find.text('2 open')), findsOneWidget);
      expect(f1('Medical'), findsOneWidget);
      expect(f1('29 Sep, 08:15'), findsOneWidget);
      expect(f1('Handover · 2026-09-29'), findsOneWidget);
      expect(f1('Coughing through the night'), findsOneWidget);
      expect(f1('Rafi Ahmed · Elm House'), findsOneWidget);
      expect(inKey('dl-flag-f2', find.text('Unsettled after the evening visit')), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('dl-flag-resolve-f1')));
      expect(find.text('Resolve flag'), findsWidgets);
      expect(find.text('Say what was done about it — the flag stays on the record with your note.'),
          findsOneWidget);
      expect(find.text('MEDICAL'), findsOneWidget);
      expect(find.text('Coughing through the night'), findsNWidgets(2));
      await _enter(tester, const ValueKey('dl-resolve-note'), 'GP called');
      final flagLoads = repo.flagQueries.length;
      await tester.tap(find.byKey(const ValueKey('dl-resolve-save')));
      await tester.pumpAndSettle();
      expect(find.text('Flag resolved'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('dl-flag-resolve-f2')));
      await tester.tap(find.byKey(const ValueKey('dl-resolve-save')));
      await tester.pumpAndSettle();
      expect(repo.resolved, [
        ['f1', 'GP called'],
        ['f2', null],
      ]);
      expect(repo.flagQueries.length, flagLoads + 2);
    });

    testWidgets('no care-flags:resolve hides Resolve; no daily-logs:write hides Add Entry, '
        'Amend and Delete', (tester) async {
      await _openLogs(tester, denied: {'care-flags:resolve', 'daily-logs:write'});
      await _pickResidence(tester);
      expect(find.byKey(const ValueKey('dl-flag-resolve-f1')), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('dl-open-day-c1-2026-08-27')));
      expect(find.byKey(const ValueKey('dl-add-entry')), findsNothing);
      expect(find.byKey(const ValueKey('dl-entry-view-e3')), findsOneWidget);
      expect(find.byKey(const ValueKey('dl-entry-amend-e3')), findsNothing);
      expect(find.byKey(const ValueKey('dl-entry-delete-e3')), findsNothing);
    });

    testWidgets('House activity: module pills, staff · residence and Open only where the '
        'app has that module', (tester) async {
      final (repo, _) = await _openLogs(tester);
      await _pickResidence(tester);
      await _tap(tester, find.byKey(const ValueKey('dl-tab-activity')));

      expect(repo.activityQueries, [
        {'residenceId': 'elm', 'from': weekAgo, 'to': today, 'page': 1, 'limit': 20},
      ]);
      expect(find.byKey(const ValueKey('dl-kpi-entries')), findsOneWidget);
      Finder a1(String text) => inKey('dl-activity-a1', find.text(text));
      expect(a1('16:20'), findsOneWidget);
      expect(a1('28/09/2026'), findsOneWidget);
      expect(a1('Handover acknowledged'), findsOneWidget);
      expect(a1('Ayaan Karim'), findsOneWidget);
      expect(a1('Handover acknowledged by Priya'), findsOneWidget);
      expect(a1('Priya Das · Elm House'), findsOneWidget);
      expect(inKey('dl-activity-a2', find.text('Stock low')), findsOneWidget);
      expect(find.byKey(const ValueKey('dl-activity-open-a1')), findsOneWidget);
      expect(find.byKey(const ValueKey('dl-activity-open-a2')), findsNothing);
    });

    testWidgets('empty states match the web', (tester) async {
      final repo = _FakeDailyLogsRepo()
        ..reviewRows = const []
        ..missingRows = const []
        ..activityRows = const []
        ..flagRows = const []
        ..shiftRows = const []
        ..dayData = null;
      await _openLogs(tester, repo: repo);
      await _pickResidence(tester);

      expect(find.text('Nothing waiting to be reviewed.'), findsOneWidget);
      expect(
        find.text('No shift is running for this home today, so there is nothing to document '
            'yet. A record appears for each resident when a shift starts.'),
        findsOneWidget,
      );
      expect(find.text('No priority notes right now.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('dl-tab-missing')));
      expect(find.text('Every resident has a log for this period.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('dl-tab-activity')));
      expect(find.text('Nothing recorded for this home in the period chosen.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('dl-tab-day')));
      await _choose(tester, find.byKey(const ValueKey('dl-resident')), 'Ayaan Karim');
      expect(find.text('Nothing recorded for this day'), findsOneWidget);
      expect(find.text('Entries added for this resident and date will appear here.'), findsOneWidget);
    });

    test('the Manager menu keeps Daily Logs', () {
      Get.put<UserSession>(_Session());
      final logs = managerDestinations().firstWhere((d) => d.title == 'Daily Logs');
      expect(logs.subtitle, 'Review queue, missing logs & resident days');
    });
  });
}
