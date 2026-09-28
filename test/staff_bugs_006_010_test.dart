import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/api_endpoints.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/network/tenant_store.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/presentation/widgets/staff_attendance_filters_bar.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/presentation/widgets/staff_attendance_header.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/domain/entities/staff_attendance_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/domain/repositories/staff_attendance_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/presentation/pages/staff_manual_attendance_entry_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/attendance/domain/entities/manual_entry_options.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/entities/staff_residence.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/entities/staff_shift_handover.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/repositories/staff_extras_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/presentation/pages/staff_recurring_checks_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/presentation/pages/staff_shift_handovers_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/presentation/pages/staff_more_menu_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/conversation_preview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/message_contact.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/message_thread.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/recurring_check_instance.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/staff_task.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/staff_task_detail.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/task_creation_options.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/task_stats.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/tasks_messages_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/repositories/staff_tasks_messages_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/presentation/pages/staff_create_task_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/presentation/widgets/tasks_messages_header.dart';
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

Future<void> _loadOutfitFont() async {
  final data = await rootBundle.load('assets/fonts/outfit/Outfit-Variable.ttf');
  final loader = FontLoader('Outfit')..addFont(Future.value(data));
  await loader.load();
}

Future<AppApiClient> _handoverDialogApiClient() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tenant = TenantStore(prefs);
  await tenant.load();
  return _FakeHandoverApiClient(
    ApiService(const ApiConfig(baseUrl: 'http://test')),
    tenant,
  );
}

class _FakeHandoverApiClient extends AppApiClient {
  _FakeHandoverApiClient(super.api, super.tenant);

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) async {
    if (path == ApiEndpoints.residences) {
      return Result.success([
        {'id': 'res-1', 'name': 'Sunrise Home'},
      ]);
    }
    if (path == ApiEndpoints.clients) {
      return Result.success([
        {
          'id': 'client-1',
          'firstName': 'Alex',
          'lastName': 'Brown',
        },
      ]);
    }
    return Result.failure(ApiError(message: 'unexpected GET $path'));
  }
}

class _FakeExtrasRepo implements StaffExtrasRepository {
  @override
  Future<Result<List<StaffShiftHandover>>> getHandovers({
    String? residenceId,
    DateTime? from,
    DateTime? to,
    String? status,
  }) async => Result.success(const []);

  @override
  Future<Result<StaffShiftHandover>> getHandoverDetail(
    String handoverId,
  ) async => Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<String>> createHandover({
    required String residenceId,
    required String summary,
    bool submit = true,
    String? fromShiftId,
    String? toShiftId,
    List<Map<String, dynamic>> pendingActions = const [],
    List<Map<String, dynamic>> clientUpdates = const [],
    Map<String, dynamic>? flagForAttention,
  }) async => Result.success('');

  @override
  Future<Result<void>> acknowledgeHandover({
    required String handoverId,
    String? note,
  }) async => Result.success(null);

  @override
  Future<Result<void>> deleteHandover(String handoverId) async =>
      Result.success(null);

  @override
  Future<Result<List<Map<String, String>>>> getClientActivities({
    required String clientId,
  }) async => Result.success(const []);

  @override
  Future<Result<void>> recordClientActivity({
    required String clientId,
    required String activityType,
    required String status,
    String? notes,
  }) async => Result.success(null);

  @override
  Future<Result<List<Map<String, String>>>> getInventoryItems({
    int page = 1,
    int limit = 50,
  }) async => Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getReferrals() async =>
      Result.success(const []);

  @override
  Future<Result<Map<String, dynamic>>> getCourseQuiz(String courseId) async =>
      Result.success(const {});

  @override
  Future<Result<Map<String, dynamic>>> submitQuizAttempt({
    required String courseId,
    required List<Map<String, dynamic>> answers,
  }) async => Result.success(const {});

  @override
  Future<Result<List<Map<String, String>>>> getTrainingCertificates() async =>
      Result.success(const []);

  @override
  Future<Result<List<StaffResidence>>> getResidences() async =>
      Result.success(const []);

  @override
  Future<Result<StaffResidence>> getResidenceDetail(String residenceId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<int>> getActiveResidentCount() async => Result.success(0);

  @override
  Future<Result<StaffResidence>> updateResidence({
    required String residenceId,
    required Map<String, dynamic> fields,
  }) async => Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<StaffResidence>> deactivateResidence(
    String residenceId,
  ) async => Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<List<Map<String, String>>>> getResidenceClients(
    String residenceId,
  ) async => Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceRooms(
    String residenceId,
  ) async => Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceStaffMembers(
    String residenceId,
  ) async => Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceShifts(
    String residenceId,
  ) async => Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceDailyLogs(
    String residenceId,
  ) async => Result.success(const []);

  @override
  Future<Result<List<StaffResidencePerson>>> getStaffDirectoryOptions() async =>
      Result.success(const []);
}

class _FakeTasksRepo implements StaffTasksMessagesRepository {
  String? createdTitle;
  String? createdDescription;
  String? createdPriority;
  String? createdTaskType;
  String? createdShiftId;
  String? createdResidenceId;
  List<String> createdAssignedStaffIds = const [];

  @override
  Future<Result<TasksMessagesOverview>> getOverview() async => Result.success(
    const TasksMessagesOverview(
      tasks: [],
      conversations: [],
      stats: TaskStats(),
    ),
  );

  @override
  Future<Result<List<StaffTask>>> getMyTasks() async =>
      Result.success(const []);

  @override
  Future<Result<TaskStats>> getTaskStats() async =>
      Result.success(const TaskStats());

  @override
  Future<Result<StaffTaskDetail>> getTaskDetail(String taskId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<void>> completeTask(String taskId) async =>
      Result.success(null);

  @override
  Future<Result<TaskCreationOptions>> getTaskCreationOptions() async =>
      Result.success(
        const TaskCreationOptions(
          shifts: [TaskCreationOption(id: 'shift-1', label: 'Morning shift')],
          residences: [TaskCreationOption(id: 'res-1', label: 'Sunrise Home')],
          staff: [TaskCreationOption(id: 'staff-1', label: 'Sam Jones')],
          defaultResidenceId: 'res-1',
          defaultStaffId: 'staff-1',
        ),
      );

  @override
  Future<Result<void>> createTask({
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueAt,
    required String taskType,
    required String shiftId,
    required String residenceId,
    List<String> assignedStaffIds = const [],
  }) async {
    createdTitle = title;
    createdDescription = description;
    createdPriority = priority;
    createdTaskType = taskType;
    createdShiftId = shiftId;
    createdResidenceId = residenceId;
    createdAssignedStaffIds = assignedStaffIds;
    return Result.success(null);
  }

  @override
  Future<Result<void>> addTaskNote({
    required String taskId,
    required String body,
  }) async => Result.success(null);

  @override
  Future<Result<List<RecurringCheckInstance>>> getMyRecurringChecks() async =>
      Result.success(const [
        RecurringCheckInstance(
          id: 'rc-1',
          title: 'Room check — Sunrise',
          statusRaw: 'pending',
          dueLabel: 'Today',
          location: 'Sunrise Home',
        ),
      ]);

  @override
  Future<Result<void>> updateRecurringCheck({
    required String instanceId,
    required String status,
    String? statusNote,
  }) async => Result.success(null);

  @override
  Future<Result<List<Map<String, String>>>> getTrainingAssignments() async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getDocuments() async =>
      Result.success(const []);

  @override
  Future<Result<List<ConversationPreview>>> getConversations() async =>
      Result.success(const []);

  @override
  Future<Result<List<MessageContact>>> getContacts() async =>
      Result.success(const []);

  @override
  Future<Result<ConversationPreview>> startConversation({
    required String title,
    required List<String> memberUserIds,
  }) async => Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<MessageThread>> getThread({
    required String conversationId,
    String? contactName,
  }) async => Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<void>> sendMessage({
    required String conversationId,
    required String body,
    String priority = 'general',
  }) async => Result.success(null);

  @override
  Future<Result<void>> markConversationRead(String conversationId) async =>
      Result.success(null);

  @override
  Future<Result<void>> markAllConversationsRead() async => Result.success(null);
}

class _FakeAttendanceRepo implements StaffAttendanceRepository {
  @override
  Future<Result<StaffAttendanceOverview>> getOverview() async => Result.success(
    const StaffAttendanceOverview(
      isOnShift: false,
      shiftStartedLabel: 'Not clocked in',
      shiftLocationName: 'Sunrise Home',
      shiftTimeRange: 'No shift assigned',
      elapsedTimeLabel: '00:00:00',
      isWithinGeofence: true,
      geofenceStatusLabel: 'Within Geofence',
      geofenceAddress: 'Sunrise Home',
      isSelfieVerified: false,
      selfieVerifiedLabel: 'Selfie not captured',
      isOnBreak: false,
      breakStatusLabel: 'Not on break',
    ),
  );

  @override
  Future<Result<void>> checkIn({
    String? shiftId,
    String? residenceId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? selfieUrl,
  }) async => Result.success(null);

  @override
  Future<Result<void>> checkOut({
    String? shiftId,
    String? residenceId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? selfieUrl,
  }) async => Result.success(null);

  @override
  Future<Result<String>> uploadAttendanceSelfie({
    required String localPath,
    required String fileName,
  }) async => Result.success('');

  @override
  Future<Result<void>> startBreak({String? residenceId}) async =>
      Result.success(null);

  @override
  Future<Result<void>> endBreak({String? residenceId}) async =>
      Result.success(null);

  @override
  Future<Result<List<ManualEntryResidenceOption>>> getResidences() async =>
      Result.success(const [
        ManualEntryResidenceOption(id: 'res-1', name: 'Sunrise Home'),
        ManualEntryResidenceOption(id: 'res-2', name: 'Moonlight House'),
      ]);

  @override
  Future<Result<List<ManualEntryShiftOption>>> getRosteredShifts({
    String? residenceId,
    DateTime? around,
  }) async => Result.success([
    ManualEntryShiftOption(
      id: 'shift-1',
      label: 'Morning · 8:00 AM – 4:00 PM',
      startsAt: DateTime(2026, 1, 1, 8),
      endsAt: DateTime(2026, 1, 1, 16),
    ),
  ]);

  @override
  Future<Result<ManualEntryEvidenceFile>> uploadEvidenceFile(
    ManualEntryEvidenceFile file,
  ) async =>
      Result.success(file.copyWith(fileUrl: 'https://example.com/file.pdf'));

  @override
  Future<Result<String>> recordManualAttendance({
    required String checkInAtIso,
    String? checkOutAtIso,
    String? residenceId,
    String? staffId,
    String? shiftId,
    int breakMinutes = 0,
    String reasonCategory = 'other',
    String status = 'pending_approval',
    String? notes,
    List<Map<String, dynamic>> evidence = const [],
  }) async => Result.success('attendance-1');
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
          displayName: 'Sam Jones',
          email: 'sam@example.com',
        )
        ..applyStaffContext(
          staffId: 'staff-1',
          residenceId: 'res-1',
          residenceName: 'Sunrise Home',
        ),
      permanent: true,
    );
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets('BUG_Report005: Attendance Manual Entry button is available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: StaffAttendanceHeader(onManualEntryTap: () => tapped = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('staff-attendance-manual-entry')),
      findsOneWidget,
    );
    expect(find.text('Manual Entry'), findsOneWidget);
    await tester.tap(find.byKey(const Key('staff-attendance-manual-entry')));
    expect(tapped, isTrue);
  });

  testWidgets(
    'BUG_Report005: Manual Entry opens nested wizard with required keys',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      GetIt.I.registerSingleton<StaffAttendanceRepository>(
        _FakeAttendanceRepo(),
      );

      await tester.pumpWidget(_wrap(const StaffManualAttendanceEntryPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staff-manual-entry-page')), findsOneWidget);
      expect(
        find.byKey(const Key('staff-manual-entry-submit')),
        findsOneWidget,
      );
      expect(find.text('Attendance Details'), findsWidgets);
      expect(find.text('Time Correction'), findsWidgets);
      expect(find.text('Evidence'), findsWidgets);
      expect(find.text('Approval'), findsWidgets);
      expect(
        find.byKey(const Key('staff-manual-entry-step-attendance-details')),
        findsOneWidget,
      );

      await tester.tap(find.text('Time Correction').first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-manual-entry-step-time-correction')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('staff-manual-entry-check-in')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BUG_Report006: Attendance date picker and status dropdown exist',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: StaffAttendanceFiltersBar(
                selectedDate: null,
                statusFilter: 'all',
                onDateChanged: _noopDate,
                onStatusChanged: _noopStatus,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-attendance-date-picker')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('staff-attendance-status-dropdown')),
        findsOneWidget,
      );
      expect(find.text('All dates'), findsOneWidget);
      expect(find.text('All status'), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);
      expect(find.text('Pending approval'), findsOneWidget);
      expect(find.text('Completed'), findsNothing);
      expect(find.text('In progress'), findsNothing);
    },
  );

  testWidgets('BUG_Report007: Handover date picker and status dropdown exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    GetIt.I.registerSingleton<StaffExtrasRepository>(_FakeExtrasRepo());

    await tester.pumpWidget(_wrap(const StaffShiftHandoversPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staff-handover-date-picker')), findsOneWidget);
    expect(
      find.byKey(const Key('staff-handover-status-dropdown')),
      findsOneWidget,
    );
    expect(find.text('All status'), findsOneWidget);
  });

  testWidgets(
    'BUG_Report007: Record handover dialog shows nested form controls',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      GetIt.I.registerSingleton<AppApiClient>(await _handoverDialogApiClient());
      GetIt.I.registerSingleton<StaffExtrasRepository>(_FakeExtrasRepo());

      await tester.pumpWidget(_wrap(const StaffShiftHandoversPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Record handover'), findsOneWidget);
      expect(find.textContaining('Summary'), findsOneWidget);
      expect(find.text('Outstanding jobs'), findsOneWidget);
      expect(find.text('Client updates'), findsOneWidget);
      expect(find.text('Flag for attention'), findsOneWidget);
      expect(find.text('Save draft'), findsOneWidget);
      expect(find.text('Submit handover'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    },
  );

  testWidgets(
    'BUG_Report008: Recurring Checks module is available from More menu',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      GetIt.I.registerSingleton<StaffTasksMessagesRepository>(_FakeTasksRepo());

      await tester.pumpWidget(_wrap(const StaffMoreMenuPage()));
      await tester.pumpAndSettle();

      expect(find.text('Recurring Checks'), findsOneWidget);
      await tester.tap(find.text('Recurring Checks'));
      await tester.pumpAndSettle();

      expect(find.byType(StaffRecurringChecksPage), findsOneWidget);
      expect(
        find.byKey(const Key('staff-recurring-checks-page')),
        findsOneWidget,
      );
      expect(find.text('Room check — Sunrise'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    },
  );

  testWidgets(
    'BUG_Report009: New Task wizard covers details, assignment, and review',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeTasksRepo();
      await tester.pumpWidget(
        _wrap(
          StaffCreateTaskPage(
            repository: repo,
            options: (await repo.getTaskCreationOptions()).value!,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staff-create-task-page')), findsOneWidget);
      expect(
        find.byKey(const Key('staff-create-task-step-details')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('staff-create-task-title')), findsOneWidget);
      expect(find.byKey(const Key('staff-create-task-type')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('staff-create-task-title')),
        'Restock gloves',
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-create-task-step-assignment')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('staff-create-task-shift')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('staff-create-task-residence')),
        findsOneWidget,
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-create-task-step-review')),
        findsOneWidget,
      );
      expect(find.text('Edit'), findsWidgets);
      expect(
        find.byKey(const Key('staff-create-task-submit')),
        findsOneWidget,
      );
    },
  );

  testWidgets('BUG_Report009: New Task button is available in Task section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: TasksMessagesHeader(
            title: 'Tasks & Messages',
            onNewTaskTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staff-tasks-new-task')), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
    await tester.tap(find.byKey(const Key('staff-tasks-new-task')));
    expect(tapped, isTrue);
  });

  test(
    'BUG_Report009: createTask records title and priority on repository',
    () async {
      final repo = _FakeTasksRepo();
      final result = await repo.createTask(
        title: 'Restock gloves',
        description: 'Nurse station',
        priority: 'high',
        taskType: 'inventory',
        shiftId: 'shift-1',
        residenceId: 'res-1',
        assignedStaffIds: ['staff-1'],
      );
      expect(result.isSuccess, isTrue);
      expect(repo.createdTitle, 'Restock gloves');
      expect(repo.createdDescription, 'Nurse station');
      expect(repo.createdPriority, 'high');
      expect(repo.createdTaskType, 'inventory');
      expect(repo.createdShiftId, 'shift-1');
      expect(repo.createdResidenceId, 'res-1');
      expect(repo.createdAssignedStaffIds, ['staff-1']);
    },
  );
}

void _noopDate(DateTime? _) {}
void _noopStatus(String _) {}
