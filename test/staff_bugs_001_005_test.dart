import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/daily_logs/presentation/widgets/staff_clients_toolbar.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/domain/entities/staff_dashboard_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/domain/entities/today_shift_summary.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/presentation/widgets/staff_dashboard_header.dart';
import 'package:comprehensive_hr_and_ops/features/staff/dashboard/presentation/widgets/today_shift_card.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/entities/staff_residence.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/entities/staff_shift_handover.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/repositories/staff_extras_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/presentation/pages/staff_residence_detail_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/presentation/pages/staff_residences_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/presentation/open_staff_profile.dart';
import 'package:comprehensive_hr_and_ops/features/staff/presentation/pages/staff_more_menu_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/profile_settings/domain/entities/staff_preference_item.dart';
import 'package:comprehensive_hr_and_ops/features/staff/profile_settings/domain/entities/staff_profile.dart';
import 'package:comprehensive_hr_and_ops/features/staff/profile_settings/domain/entities/staff_profile_settings_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/profile_settings/domain/repositories/staff_profile_settings_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/profile_settings/presentation/controllers/staff_profile_settings_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/profile_settings/presentation/pages/staff_profile_detail_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/profile_settings/presentation/pages/staff_profile_settings_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/profile_settings/presentation/widgets/staff_profile_card.dart';
import 'package:comprehensive_hr_and_ops/features/staff/scheduling/domain/entities/staff_schedule_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/scheduling/domain/entities/staff_shift.dart';
import 'package:comprehensive_hr_and_ops/features/staff/scheduling/domain/entities/staff_shift_form_option.dart';
import 'package:comprehensive_hr_and_ops/features/staff/scheduling/domain/repositories/staff_schedule_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/scheduling/presentation/pages/staff_create_shift_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/scheduling/presentation/widgets/staff_schedule_header.dart';
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

class _FakeProfileRepo implements StaffProfileSettingsRepository {
  @override
  Future<Result<StaffProfileSettingsOverview>> getOverview() async {
    return Result.success(
      const StaffProfileSettingsOverview(
        profile: StaffProfile(
          initials: 'SJ',
          name: 'Sam Jones',
          role: 'Caregiver',
          email: 'sam@example.com',
        ),
        linkedItems: [],
        preferenceItems: [
          StaffPreferenceItem(
            type: StaffPreferenceType.notifications,
            label: 'Notification Preferences',
          ),
        ],
        pushNotificationsEnabled: true,
        darkModeEnabled: false,
      ),
    );
  }

  @override
  Future<Result<void>> createSupportTicket({
    required String subject,
    required String body,
  }) async =>
      Result.success(null);

  @override
  Future<Result<Map<String, bool>>> getNotificationPreferences() async =>
      Result.success(const {'email': true});

  @override
  Future<Result<void>> updateNotificationPreferences(
    Map<String, bool> values,
  ) async =>
      Result.success(null);

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      Result.success(null);
}

class _FakeExtrasRepo implements StaffExtrasRepository {
  @override
  Future<Result<List<StaffResidence>>> getResidences() async =>
      Result.success(const [
        StaffResidence(
          id: 'res-1',
          name: 'Sunrise Home',
          status: 'active',
          residenceType: 'group_home',
          serviceType: 'Residential care',
          addressLine1: '12 Elm Road',
          city: 'Dhaka',
          stateProvince: 'Dhaka',
          postalCode: '1207',
          bedCapacity: 8,
          occupiedBeds: 0,
          availableBeds: 8,
          geofenceRadiusMeters: 150,
          primaryManager: StaffResidencePerson(
            id: 'mgr-1',
            name: 'bilkiss Preston',
            role: 'primary_manager',
          ),
          assignedStaff: [
            StaffResidencePerson(id: 's1', name: 'Maya Rahman', role: 'staff'),
          ],
        ),
      ]);

  @override
  Future<Result<StaffResidence>> getResidenceDetail(String residenceId) async =>
      Result.success(
        const StaffResidence(
          id: 'res-1',
          name: 'Sunrise Home',
          status: 'active',
          residenceType: 'group_home',
          serviceType: 'Residential care',
          addressLine1: '12 Elm Road',
          city: 'Dhaka',
          bedCapacity: 8,
          occupiedBeds: 0,
          geofenceRadiusMeters: 150,
          primaryManager: StaffResidencePerson(
            id: 'mgr-1',
            name: 'bilkiss Preston',
            role: 'primary_manager',
          ),
          assignedStaff: [
            StaffResidencePerson(id: 's1', name: 'Maya Rahman', role: 'staff'),
          ],
        ),
      );

  @override
  Future<Result<int>> getActiveResidentCount() async => Result.success(1);

  @override
  Future<Result<StaffResidence>> updateResidence({
    required String residenceId,
    required Map<String, dynamic> fields,
  }) async =>
      getResidenceDetail(residenceId);

  @override
  Future<Result<StaffResidence>> deactivateResidence(String residenceId) async =>
      Result.success(
        const StaffResidence(
          id: 'res-1',
          name: 'Sunrise Home',
          status: 'archived',
        ),
      );

  @override
  Future<Result<List<Map<String, String>>>> getResidenceClients(
    String residenceId,
  ) async =>
      Result.success(const [
        {
          'id': 'c1',
          'title': 'Ayaan Karim',
          'subtitle': 'High',
          'status': 'active',
        },
      ]);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceRooms(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceStaffMembers(
    String residenceId,
  ) async =>
      Result.success(const [
        {
          'id': 's1',
          'title': 'Maya Rahman',
          'subtitle': 'staff',
          'status': 'active',
        },
      ]);

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
      Result.success(const [
        StaffResidencePerson(
          id: 'mgr-1',
          name: 'bilkiss Preston',
          role: 'primary_manager',
        ),
        StaffResidencePerson(id: 's1', name: 'Maya Rahman', role: 'staff'),
      ]);

  @override
  Future<Result<List<StaffShiftHandover>>> getHandovers({
    String? residenceId,
    DateTime? from,
    DateTime? to,
    String? status,
    String? authorId,
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
}

class _FakeScheduleRepo implements StaffScheduleRepository {
  @override
  Future<Result<StaffScheduleOverview>> getOverview({
    DateTime? weekStart,
    DateTime? selectedDate,
  }) async =>
      Result.success(
        const StaffScheduleOverview(
          weekRangeLabel: 'Sep 28 – Oct 4',
          weekDays: [],
          shiftsThisWeekLabel: '0 shifts',
          shifts: [],
        ),
      );

  @override
  Future<Result<StaffShift>> getShiftDetail(String shiftId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<void>> bidOnShift(String shiftId, {String? note}) async =>
      Result.success(null);

  @override
  Future<Result<void>> requestSwap({
    required String fromShiftId,
    String? note,
    String? targetStaffId,
    String? toShiftId,
  }) async =>
      Result.success(null);

  @override
  Future<Result<void>> respondToSwap({
    required String swapId,
    required bool accepted,
    String? note,
  }) async =>
      Result.success(null);

  @override
  Future<Result<void>> cancelSwap(String swapId) async =>
      Result.success(null);

  @override
  Future<Result<String>> createShift(Map<String, dynamic> payload) async =>
      Result.success('shift-created');

  @override
  Future<Result<List<StaffShiftResidenceOption>>> getResidences() async =>
      Result.success(const [
        StaffShiftResidenceOption(id: 'res-1', name: 'Sunrise Home'),
      ]);

  @override
  Future<Result<List<StaffShiftStaffOption>>> searchStaff({
    String? search,
    String? residenceId,
  }) async =>
      Result.success(const [
        StaffShiftStaffOption(
          id: 'staff-1',
          name: 'Sam Jones',
          detail: 'PSW',
          initials: 'SJ',
        ),
      ]);
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
        ),
      permanent: true,
    );
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets(
    'BUG_Report001: Profile card tap opens My Profile detail',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Get.put(
        StaffProfileSettingsController(repository: _FakeProfileRepo()),
        permanent: true,
      );

      const overview = StaffDashboardOverview(
        organizationName: 'Sunrise Care',
        dateLabel: 'Mon · Sep 28',
        greetingLine: 'Good morning, Sam',
        greetingSubtitle: 'Ready for your shift',
        unreadNotificationCount: 0,
        todayShift: TodayShiftSummary(
          statusLabel: 'Scheduled',
          dateLabel: 'Mon, Sep 28',
          timeRange: '8:00 AM – 4:00 PM',
        ),
        overviewStats: [],
        alertCount: 0,
        alertLabel: '',
        quickActions: [],
      );

      var avatarTapped = false;

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                StaffDashboardHeader(
                  overview: overview,
                  onAvatarTap: () {
                    avatarTapped = true;
                    openStaffProfile();
                  },
                ),
                const Positioned(
                  left: 20,
                  right: 20,
                  bottom: -70,
                  child: IgnorePointer(
                    child: TodayShiftCard(
                      shift: TodayShiftSummary(
                        statusLabel: 'Scheduled',
                        dateLabel: 'Mon, Sep 28',
                        timeRange: '8:00 AM – 4:00 PM',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final avatar = find.byKey(const Key('staff-home-profile-avatar'));
      expect(avatar, findsOneWidget);
      await tester.tap(avatar);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(avatarTapped, isTrue);
      expect(find.byType(StaffProfileSettingsPage), findsOneWidget);
      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('Sam Jones'), findsOneWidget);
      expect(find.text('sam@example.com'), findsOneWidget);

      final profileCard = find.byKey(const Key('staff-profile-upper-card'));
      expect(profileCard, findsOneWidget);
      expect(find.byType(StaffProfileCard), findsOneWidget);
      await tester.ensureVisible(profileCard);
      await tester.tap(profileCard);
      await tester.pumpAndSettle();

      expect(find.byType(StaffProfileDetailPage), findsOneWidget);
      expect(find.byKey(const Key('staff-profile-detail-page')), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    },
  );

  testWidgets(
    'BUG_Report002: Residence tap opens detail with web-matched fields',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      GetIt.I.registerSingleton<StaffExtrasRepository>(_FakeExtrasRepo());

      await tester.pumpWidget(_wrap(const StaffMoreMenuPage()));
      await tester.pumpAndSettle();

      expect(find.text('Residence'), findsOneWidget);
      await tester.tap(find.text('Residence'));
      await tester.pumpAndSettle();

      expect(find.byType(StaffResidencesPage), findsOneWidget);
      expect(find.text('Residences Management'), findsOneWidget);
      expect(find.text('Homes'), findsOneWidget);
      expect(find.text('Beds free'), findsOneWidget);
      expect(find.text('Residents'), findsOneWidget);
      // Web KPI: active clients count (1), beds free = licensed - residents (8-1=7).
      expect(find.text('1'), findsWidgets);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Sunrise Home'), findsOneWidget);
      expect(find.text('12 Elm Road, Dhaka, Dhaka, 1207'), findsOneWidget);
      expect(find.text('group_home'), findsOneWidget);
      expect(find.text('0 / 8 Beds'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
      expect(find.byKey(const Key('staff-residence-view-res-1')), findsOneWidget);
      expect(find.byKey(const Key('staff-residence-edit-res-1')), findsOneWidget);
      expect(
        find.byKey(const Key('staff-residence-deactivate-res-1')),
        findsOneWidget,
      );
      expect(find.text('Assigned Staff'), findsWidgets);
      expect(find.text('Primary Manager'), findsWidgets);
      expect(find.text('bilkiss Preston'), findsWidgets);
      expect(find.text('150m'), findsOneWidget);

      await tester.tap(find.byKey(const Key('staff-residence-view-res-1')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffResidenceDetailPage), findsOneWidget);
      expect(find.byKey(const Key('staff-residence-detail-page')), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Occupancy'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('Edit Residence'), findsOneWidget);

      await tester.tap(find.byKey(const Key('staff-residence-detail-edit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staff-residence-edit-page')), findsOneWidget);
      expect(find.text('Edit Residence'), findsWidgets);
      expect(find.text('Residence Preview'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('assisted_living_nursing_homes'),
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('staff-residence-edit-page')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('assisted_living_nursing_homes'), findsOneWidget);
      expect(find.text('group_home'), findsWidgets);
      expect(find.text('Active'), findsWidgets);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Address Details'), findsOneWidget);
      expect(find.textContaining('GPS'), findsWidgets);
      expect(find.text('Enable GPS Tracking'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    },
  );

  testWidgets(
    'BUG_Report003: Client search, residence dropdown, and Add Client exist',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var addTapped = false;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StaffClientsToolbar(
                searchQuery: '',
                onSearchChanged: (_) {},
                selectedResidenceId: null,
                residenceOptions: const [
                  (id: 'r1', name: 'Sunrise Home'),
                ],
                onResidenceChanged: (_) {},
                onAddClient: () => addTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staff-clients-search')), findsOneWidget);
      expect(
        find.byKey(const Key('staff-clients-residence-dropdown')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('staff-clients-add-button')), findsOneWidget);
      expect(find.text('Add Client'), findsOneWidget);
      expect(find.text('Search clients'), findsOneWidget);

      await tester.tap(find.byKey(const Key('staff-clients-add-button')));
      await tester.pump();
      expect(addTapped, isTrue);
    },
  );

  testWidgets(
    'BUG_Report004: Schedule Filter and Create Shift buttons exist',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var filterTapped = false;
      var createTapped = false;

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: StaffScheduleHeader(
              onBackTap: () {},
              onFilterTap: () => filterTapped = true,
              onCreateShiftTap: () => createTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Schedule'), findsOneWidget);
      expect(find.byKey(const Key('staff-schedule-filter')), findsOneWidget);
      expect(
        find.byKey(const Key('staff-schedule-create-shift')),
        findsOneWidget,
      );
      expect(find.text('Shift'), findsOneWidget);

      await tester.tap(find.byKey(const Key('staff-schedule-filter')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('staff-schedule-create-shift')));
      await tester.pump();

      expect(filterTapped, isTrue);
      expect(createTapped, isTrue);
    },
  );

  testWidgets(
    'BUG_Report004: Create Shift wizard exposes all nested steps',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      GetIt.I.registerSingleton<StaffScheduleRepository>(_FakeScheduleRepo());

      await tester.pumpWidget(
        _wrap(
          StaffCreateShiftPage(
            repository: GetIt.I<StaffScheduleRepository>(),
            initialDate: DateTime(2026, 9, 28),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staff-create-shift-page')), findsOneWidget);
      expect(find.text('Add New Shift'), findsOneWidget);
      expect(
        find.textContaining('Set the timing, assign staff'),
        findsOneWidget,
      );
      expect(find.textContaining('Shift Information'), findsWidgets);
      expect(find.textContaining('Staff Assignment'), findsWidgets);
      expect(find.textContaining('Open Shift'), findsWidgets);
      expect(find.textContaining('Recurring'), findsWidgets);
      expect(find.textContaining('Notifications'), findsWidgets);
      expect(find.text('COMPLETION'), findsOneWidget);
      expect(
        find.textContaining('Set the timing, residence, and role coverage'),
        findsOneWidget,
      );
      expect(find.textContaining('Sunrise Home'), findsWidgets);
      expect(find.textContaining('Morning'), findsWidgets);
      expect(
        find.textContaining('Earlier than the start means it runs overnight'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Optional — e.g. Weekend cover'),
        findsOneWidget,
      );
      expect(
        find.textContaining('handover notes or special instructions'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('staff-create-shift-title')), findsOneWidget);
      expect(find.byKey(const Key('staff-create-shift-notes')), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('staff-create-shift-step-staff-assignment')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Assigned Staff'), findsWidgets);
      expect(find.text('Add staff...'), findsOneWidget);
      expect(
        find.byKey(const Key('staff-create-shift-add-staff')),
        findsOneWidget,
      );
      expect(
        find.textContaining('No staff assigned yet'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('staff-create-shift-step-open-shift')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('staff-create-shift-step-open-shift')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Make this an open shift'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('staff-create-shift-step-recurring')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('staff-create-shift-step-recurring')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Repeat this shift'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('staff-create-shift-step-notifications')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('staff-create-shift-step-notifications')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notify assigned staff'), findsOneWidget);
      expect(find.text('No reminder'), findsOneWidget);
      expect(
        find.textContaining('A second notification this long before'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Add a note included in the notification'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Settings'),
        findsWidgets,
      );
      expect(
        find.byKey(const Key('staff-create-shift-submit')),
        findsOneWidget,
      );
      expect(find.text('Create shift'), findsOneWidget);
    },
  );
}
