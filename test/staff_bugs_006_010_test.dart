import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/presentation/widgets/staff_attendance_filters_bar.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/presentation/widgets/staff_attendance_header.dart';
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
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/task_stats.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/tasks_messages_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/repositories/staff_tasks_messages_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/presentation/widgets/tasks_messages_header.dart';
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

class _FakeExtrasRepo implements StaffExtrasRepository {
  @override
  Future<Result<List<StaffShiftHandover>>> getHandovers({
    String? residenceId,
    DateTime? from,
    DateTime? to,
    String? status,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<StaffShiftHandover>> getHandoverDetail(String handoverId) async =>
      Result.failure(const ApiError(message: 'unused'));

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
  }) async =>
      Result.success('');

  @override
  Future<Result<void>> acknowledgeHandover({
    required String handoverId,
    String? note,
  }) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteHandover(String handoverId) async =>
      Result.success(null);

  @override
  Future<Result<List<Map<String, String>>>> getClientActivities({
    required String clientId,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<void>> recordClientActivity({
    required String clientId,
    required String activityType,
    required String status,
    String? notes,
  }) async =>
      Result.success(null);

  @override
  Future<Result<List<Map<String, String>>>> getInventoryItems({
    int page = 1,
    int limit = 50,
  }) async =>
      Result.success(const []);

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
  }) async =>
      Result.success(const {});

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
  }) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<StaffResidence>> deactivateResidence(String residenceId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<List<Map<String, String>>>> getResidenceClients(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceRooms(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceStaffMembers(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceShifts(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceDailyLogs(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<StaffResidencePerson>>> getStaffDirectoryOptions() async =>
      Result.success(const []);
}

class _FakeTasksRepo implements StaffTasksMessagesRepository {
  String? createdTitle;
  String? createdDescription;
  String? createdPriority;

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
  Future<Result<void>> createTask({
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueAt,
  }) async {
    createdTitle = title;
    createdDescription = description;
    createdPriority = priority;
    return Result.success(null);
  }

  @override
  Future<Result<void>> addTaskNote({
    required String taskId,
    required String body,
  }) async =>
      Result.success(null);

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
  }) async =>
      Result.success(null);

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
  }) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<MessageThread>> getThread({
    required String conversationId,
    String? contactName,
  }) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<void>> sendMessage({
    required String conversationId,
    required String body,
    String priority = 'general',
  }) async =>
      Result.success(null);

  @override
  Future<Result<void>> markConversationRead(String conversationId) async =>
      Result.success(null);

  @override
  Future<Result<void>> markAllConversationsRead() async =>
      Result.success(null);
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

  testWidgets(
    'BUG_Report005: Attendance Manual Entry button is available',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: StaffAttendanceHeader(
              onManualEntryTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staff-attendance-manual-entry')), findsOneWidget);
      expect(find.text('Manual Entry'), findsOneWidget);
      await tester.tap(find.byKey(const Key('staff-attendance-manual-entry')));
      expect(tapped, isTrue);
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

      expect(find.byKey(const Key('staff-attendance-date-picker')), findsOneWidget);
      expect(find.byKey(const Key('staff-attendance-status-dropdown')), findsOneWidget);
      expect(find.text('All dates'), findsOneWidget);
      expect(find.text('All status'), findsOneWidget);
    },
  );

  testWidgets(
    'BUG_Report007: Handover date picker and status dropdown exist',
    (tester) async {
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
      expect(find.byKey(const Key('staff-recurring-checks-page')), findsOneWidget);
      expect(find.text('Room check — Sunrise'), findsOneWidget);
    },
  );

  testWidgets(
    'BUG_Report009: New Task button is available in Task section',
    (tester) async {
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
    },
  );

  test(
    'BUG_Report009: createTask records title and priority on repository',
    () async {
      final repo = _FakeTasksRepo();
      final result = await repo.createTask(
        title: 'Restock gloves',
        description: 'Nurse station',
        priority: 'high',
      );
      expect(result.isSuccess, isTrue);
      expect(repo.createdTitle, 'Restock gloves');
      expect(repo.createdDescription, 'Nurse station');
      expect(repo.createdPriority, 'high');
    },
  );
}

void _noopDate(DateTime? _) {}
void _noopStatus(String _) {}
