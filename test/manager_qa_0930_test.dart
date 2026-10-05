import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/data/mappers/scheduling_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/create_shift_draft.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/scheduling_enums.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/scheduling_overview.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/shift_residence_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/shift_staff_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/presentation/controllers/scheduling_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/presentation/pages/create_shift_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/presentation/pages/scheduling_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/presentation/widgets/create_shift/create_shift_header.dart';
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

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// A `GET /shifts/{id}` body shaped like the live API.
Map<String, dynamic> _shiftJson() {
  final day = _today();
  return {
    'id': 'shift-1',
    'residenceId': 'elm',
    'startsAt': DateTime(day.year, day.month, day.day, 19, 30)
        .toUtc()
        .toIso8601String(),
    'endsAt': DateTime(day.year, day.month, day.day, 23, 0)
        .toUtc()
        .toIso8601String(),
    'shiftType': null,
    'breakMinutes': null,
    'requiredStaffCount': null,
    'title': 'Day shift',
    'notes': 'Standard day cover.',
    'status': 'published',
    'biddingConfig': null,
    'reminderMinutesBefore': 60,
    'staff': [
      {'id': 'staff-shakib', 'name': 'Shakib Hasan', 'status': 'assigned'},
    ],
  };
}

class _FakeSchedulingRepo implements SchedulingRepository {
  final List<String> loaded = [];
  final List<(String, Map<String, dynamic>, List<String>)> updates = [];

  @override
  Future<Result<SchedulingOverview>> getOverview({
    DateTime? weekOf,
    DateTime? selectedDay,
    String? residenceId,
    ShiftStatusFilter? status,
    bool mine = false,
  }) async =>
      Result.success(
        SchedulingMapper.compose(
          weekBody: {
            'data': [_shiftJson()],
          },
          openBody: const {'data': []},
          pendingSwapsBody: const {'data': []},
          approvedSwapsBody: const {'data': []},
          declinedSwapsBody: const {'data': []},
          weekOf: weekOf,
          selectedDay: selectedDay ?? _today(),
        ),
      );

  @override
  Future<Result<List<ShiftResidenceOption>>> getResidences() async =>
      Result.success(const [
        ShiftResidenceOption(id: 'elm', name: 'Elm House'),
      ]);

  @override
  Future<Result<List<ShiftStaffOption>>> getStaffOptions() async =>
      Result.success(const [
        ShiftStaffOption(
          id: 'staff-shakib',
          name: 'Shakib Hasan',
          detail: 'Care Worker · Elm House',
          initials: 'SH',
          role: 'Care Worker',
          residenceLabel: 'Elm House',
        ),
      ]);

  @override
  Future<Result<int>> createShift(Map<String, dynamic> payload) async =>
      Result.success(1);

  @override
  Future<Result<CreateShiftDraft>> getShiftDraft(String shiftId) async {
    loaded.add(shiftId);
    return Result.success(SchedulingMapper.draftFromShift(_shiftJson()));
  }

  @override
  Future<Result<void>> updateShift({
    required String shiftId,
    required Map<String, dynamic> payload,
    required List<String> staffIds,
  }) async {
    updates.add((shiftId, payload, staffIds));
    return Result.success(null);
  }

  @override
  Future<Result<void>> decideShiftSwap({
    required String swapId,
    required bool approve,
  }) async =>
      Result.success(null);
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

void _bigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _tab(String label) => find.descendant(
      of: find.byType(CreateShiftStepTabs),
      matching: find.text(label),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSchedulingRepo repo;

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
    repo = _FakeSchedulingRepo();
    GetIt.I.registerSingleton<SchedulingRepository>(repo);
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets('M01: a Custom shift time is picked and shown with AM/PM',
      (tester) async {
    _bigView(tester);
    await tester.pumpWidget(_app(const CreateShiftPage(initialResidenceId: 'elm')));
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('create-shift-type')));
    await tester.tap(find.text('Custom').last);
    await tester.pumpAndSettle();
    expect(find.text('07:00 AM'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('create-shift-start')));
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    await tester.tap(find.text('PM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('07:00 PM'), findsOneWidget);
  });

  test('M02: GET /shifts/{id} maps to the edit form like shiftToFormValues',
      () {
    final draft = SchedulingMapper.draftFromShift({'data': _shiftJson()});

    expect(draft.residenceId, 'elm');
    expect(draft.shiftType, 'custom');
    expect(draft.shiftDate, _today());
    expect(draft.startMinutes, 19 * 60 + 30);
    expect(draft.endMinutes, 23 * 60);
    expect(draft.breakMinutes, 0);
    expect(draft.requiredStaffCount, '');
    expect(draft.title, 'Day shift');
    expect(draft.notes, 'Standard day cover.');
    expect(draft.isOpenShift, isFalse);
    expect(draft.reminderMinutes, 60);
    expect(draft.assignedStaff.single.staffId, 'staff-shakib');
    expect(draft.assignedStaff.single.staffName, 'Shakib Hasan');

    final body = draft.toUpdateBody();
    expect(body.containsKey('staffIds'), isFalse);
    expect(body.containsKey('recurrence'), isFalse);
    expect(body.containsKey('notifyAssignedStaff'), isFalse);
    expect(body['title'], 'Day shift');
    expect(body['breakMinutes'], 0);
    expect(body['reminderMinutesBefore'], 60);

    final open = SchedulingMapper.draftFromShift({
      ..._shiftJson(),
      'status': 'open',
      'requiredStaffCount': 2,
      'biddingConfig': {'maxBids': 5, 'priority': 'high', 'awardMethod': 'manual'},
    });
    expect(open.isOpenShift, isTrue);
    expect(open.requiredStaffCount, '2');
    expect(open.maxBids, '5');
    expect(open.priority, 'high');
  });

  testWidgets(
      'M02: Edit Shift loads the shift, saves via PATCH + PUT assignments',
      (tester) async {
    _bigView(tester);
    await tester.pumpWidget(_app(const CreateShiftPage(editShiftId: 'shift-1')));
    await tester.pumpAndSettle();

    expect(repo.loaded, ['shift-1']);
    expect(find.text('Edit Shift'), findsOneWidget);
    expect(find.text('Add New Shift'), findsNothing);
    expect(find.text('07:30 PM'), findsOneWidget);
    expect(find.text('11:00 PM'), findsOneWidget);
    expect(find.text('Day shift'), findsOneWidget);

    await _tap(tester, _tab('Staff Assignment'));
    expect(find.text('Shakib Hasan'), findsWidgets);
    expect(find.textContaining('Care Worker'), findsWidgets);

    await _tap(tester, _tab('Notifications'));
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Create shift'), findsNothing);

    await _tap(tester, find.text('Save changes'));
    expect(repo.updates, hasLength(1));
    final (id, payload, staffIds) = repo.updates.single;
    expect(id, 'shift-1');
    expect(staffIds, ['staff-shakib']);
    expect(payload.containsKey('staffIds'), isFalse);
    expect(payload['residenceId'], 'elm');
    expect(payload['title'], 'Day shift');
  });

  testWidgets('M02: tapping a scheduled shift opens Edit Shift (write only)',
      (tester) async {
    _bigView(tester);
    Get.put(
      SchedulingController(
        repository: repo,
        session: UserSession()
          ..applyPermissions(const ['scheduling:read', 'scheduling:write']),
      ),
      permanent: true,
    );
    await tester.pumpWidget(_app(const SchedulingPage()));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('calendar-shift-shift-1'));
    expect(row, findsOneWidget);
    await _tap(tester, row);
    expect(repo.loaded, ['shift-1']);
    expect(find.text('Edit Shift'), findsOneWidget);
  });

  testWidgets('M02: without scheduling:write a shift does not open',
      (tester) async {
    _bigView(tester);
    Get.put(
      SchedulingController(
        repository: repo,
        session: UserSession()..applyPermissions(const ['scheduling:read']),
      ),
      permanent: true,
    );
    await tester.pumpWidget(_app(const SchedulingPage()));
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('calendar-shift-shift-1')));
    expect(repo.loaded, isEmpty);
    expect(find.text('Edit Shift'), findsNothing);
  });
}
