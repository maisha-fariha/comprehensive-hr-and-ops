import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/attendance/domain/entities/attendance_record.dart';
import 'package:comprehensive_hr_and_ops/features/hr/attendance/domain/entities/attendance_week.dart';
import 'package:comprehensive_hr_and_ops/features/hr/attendance/domain/entities/manual_entry_options.dart';
import 'package:comprehensive_hr_and_ops/features/hr/attendance/domain/repositories/attendance_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/attendance/presentation/controllers/attendance_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/attendance/presentation/pages/attendance_clock_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/attendance/presentation/pages/attendance_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/attendance/presentation/widgets/manual_entry/manual_entry_header.dart';
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

class _TestSession extends UserSession {
  @override
  String? get staffId => 'staff-me';

  @override
  String get displayName => 'Rafi Ahmed';
}

final _pending = AttendanceRecord(
  id: 'r1',
  staffId: 'staff-maya',
  staffName: 'Maya Rahman',
  staffInitials: 'MR',
  staffRole: 'Care Assistant',
  residenceId: 'elm',
  residenceName: 'Elm House',
  checkInAt: DateTime(2026, 9, 29, 8),
  checkOutAt: DateTime(2026, 9, 29, 16),
  breakMinutes: 30,
  workedMinutes: 450,
  status: 'pending_approval',
  isManual: true,
  checkIn: const AttendanceCheckpoint(
    geofenceStatus: 'inside',
    distanceMeters: 12,
    selfieUrl: '/api/v1/files/selfie.jpg',
  ),
  reasonCategory: 'shift_swap',
  evidence: const [
    AttendanceEvidence(fileUrl: '/api/v1/files/rota.png', fileType: 'image/png'),
  ],
  adminNote: 'Checked the rota',
  lateMinutes: 5,
  notes: 'Covered for Priya',
);

final _present = AttendanceRecord(
  id: 'r2',
  staffId: 'staff-jamal',
  staffName: 'Jamal Uddin',
  staffInitials: 'JU',
  residenceId: 'elm',
  residenceName: 'Elm House',
  checkInAt: DateTime(2026, 9, 29, 9),
  status: 'present',
);

class _FakeAttendanceRepo implements AttendanceRepository {
  final List<Map<String, dynamic>> recordQueries = [];
  final List<Map<String, dynamic>> summaryQueries = [];
  final List<String> approved = [];
  final List<String> rejected = [];
  final List<String> deleted = [];
  final Map<String, Map<String, dynamic>> patched = {};
  final List<Map<String, dynamic>> created = [];
  Map<String, dynamic>? clockInBody;
  Map<String, dynamic>? clockOutBody;

  OpenAttendance? open;
  AttendanceShiftWindow? shift;
  int total = 2;

  @override
  Future<Result<AttendanceRecordPage>> getRecords({
    required int page,
    required int limit,
    String? residenceId,
    String? status,
    String? from,
    String? to,
    bool mine = false,
  }) async {
    recordQueries.add({
      'page': page,
      'limit': limit,
      'residenceId': residenceId,
      'status': status,
      'from': from,
      'to': to,
    });
    return Result.success(
      AttendanceRecordPage(
        records: [_pending, _present],
        page: page,
        limit: limit,
        total: total,
        totalPages: (total / limit).ceil(),
      ),
    );
  }

  @override
  Future<Result<AttendanceSummary>> getSummary({
    String? residenceId,
    required String from,
    required String to,
  }) async {
    summaryQueries.add({'residenceId': residenceId, 'from': from, 'to': to});
    return Result.success(
      const AttendanceSummary(
        present: 3,
        late: 2,
        missed: 1,
        pendingApproval: 4,
        averageLateMinutes: 5,
        lateStaffCount: 2,
      ),
    );
  }

  @override
  Future<Result<OpenAttendance?>> getMyOpenAttendance() async =>
      Result.success(open);

  @override
  Future<Result<AttendanceShiftWindow?>> getMyShiftWindow(String staffId) async =>
      Result.success(shift);

  @override
  Future<Result<void>> clockIn(Map<String, dynamic> body) async {
    clockInBody = body;
    return Result.success(null);
  }

  @override
  Future<Result<void>> clockOut(Map<String, dynamic> body) async {
    clockOutBody = body;
    return Result.success(null);
  }

  @override
  Future<Result<String>> uploadSelfie(String localPath, String fileName) async =>
      Result.success('/api/v1/files/attendance-selfies/$fileName');

  @override
  Future<Result<void>> updateAttendance(
    String attendanceId,
    Map<String, dynamic> body,
  ) async {
    patched[attendanceId] = body;
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteAttendance(String attendanceId) async {
    deleted.add(attendanceId);
    return Result.success(null);
  }

  @override
  Future<Result<void>> approveAttendance(String attendanceId) async {
    approved.add(attendanceId);
    return Result.success(null);
  }

  @override
  Future<Result<void>> rejectAttendance(String attendanceId) async {
    rejected.add(attendanceId);
    return Result.success(null);
  }

  @override
  Future<Result<List<ManualEntryResidenceOption>>> getResidences() async =>
      Result.success(const [
        ManualEntryResidenceOption(id: 'elm', name: 'Elm House'),
        ManualEntryResidenceOption(id: 'oak', name: 'Oak Lodge'),
      ]);

  @override
  Future<Result<List<ManualEntryStaffOption>>> searchStaff({
    String? search,
    String? residenceId,
  }) async =>
      Result.success([
        if ((search ?? '').toLowerCase().startsWith('ma'))
          const ManualEntryStaffOption(
            id: 'staff-maya',
            name: 'Maya Rahman',
            detail: 'Care Assistant',
            initials: 'MR',
          ),
      ]);

  @override
  Future<Result<List<ManualEntryShiftOption>>> getRosteredShifts({
    required String staffId,
    String? residenceId,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<ManualEntryEvidenceFile>> uploadEvidenceFile(
    ManualEntryEvidenceFile file,
  ) async =>
      Result.success(file.copyWith(fileUrl: '/api/v1/files/${file.fileName}'));

  @override
  Future<Result<String>> recordManualAttendance(
    Map<String, dynamic> payload,
  ) async {
    created.add(payload);
    return Result.success('new-id');
  }
}

late _FakeAttendanceRepo _repo;

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

void _setUpDeps() {
  _repo = _FakeAttendanceRepo();
  final session = Get.put<UserSession>(_TestSession());
  GetIt.I.registerSingleton<AttendanceRepository>(_repo);
  Get.put(
    AttendanceController(repository: _repo, session: session),
    permanent: true,
  );
}

Future<void> _pumpAttendance(
  WidgetTester tester, {
  void Function(_FakeAttendanceRepo repo)? configure,
}) async {
  tester.view.physicalSize = const Size(375, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  _repo = _FakeAttendanceRepo();
  configure?.call(_repo);
  final session = Get.put<UserSession>(_TestSession());
  GetIt.I.registerSingleton<AttendanceRepository>(_repo);
  Get.put(
    AttendanceController(repository: _repo, session: session),
    permanent: true,
  );
  await tester.pumpWidget(_app(const AttendancePage()));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, Finder field, String option) async {
  await _tap(tester, field);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Finder _stepTab(String label) => find.descendant(
      of: find.byType(ManualEntryStepTabs),
      matching: find.text(label),
    );

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

  testWidgets('BUG08: header row has the web week, residence and status '
      'filters plus Clock in and Manual Entry', (tester) async {
    await _pumpAttendance(tester);

    final week = AttendanceWeek.containing(DateTime.now());
    expect(find.text(week.label), findsOneWidget);
    expect(find.text('All Residences'), findsOneWidget);
    expect(find.text('Any status'), findsOneWidget);
    expect(find.text('Clock in'), findsOneWidget);
    expect(find.text('Manual Entry'), findsOneWidget);

    final first = _repo.recordQueries.first;
    expect(first['page'], 1);
    expect(first['limit'], 20);
    expect(first['from'], week.from);
    expect(first['to'], week.to);
    expect(_repo.summaryQueries.first['from'], week.from);

    await _tap(tester, find.byKey(const ValueKey('attendance-residence-filter')));
    expect(find.text('Oak Lodge'), findsOneWidget);
    await tester.tap(find.text('Elm House').last);
    await tester.pumpAndSettle();
    expect(_repo.recordQueries.last['residenceId'], 'elm');
    expect(_repo.summaryQueries.last['residenceId'], 'elm');

    await _tap(tester, find.byKey(const ValueKey('attendance-status-filter')));
    for (final label in const [
      'Present',
      'Late',
      'Missed',
      'Pending approval',
      'Rejected',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Late').last);
    await tester.pumpAndSettle();
    expect(_repo.recordQueries.last['status'], 'late');
    expect(_repo.recordQueries.last['from'], week.from);
  });

  testWidgets('BUG08: week popover moves by whole weeks', (tester) async {
    await _pumpAttendance(tester);
    final week = AttendanceWeek.containing(DateTime.now());

    await _tap(tester, find.byKey(const ValueKey('attendance-week')));
    expect(find.byTooltip('Previous week'), findsOneWidget);
    expect(find.byTooltip('Next week'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('attendance-week-next')));
    await tester.pumpAndSettle();

    expect(find.text(week.next.label), findsOneWidget);
    expect(_repo.recordQueries.last['from'], week.next.from);
    expect(_repo.recordQueries.last['to'], week.next.to);
    expect(_repo.summaryQueries.last['from'], week.next.from);
  });

  testWidgets('BUG08: KPI cards show summary values and toggle the status '
      'filter; pending ignores the week', (tester) async {
    await _pumpAttendance(tester);

    for (final label in const ['PRESENT', 'LATE', 'MISSED', 'PENDING APPROVAL']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Clocked in on time'), findsOneWidget);
    expect(find.text('5m average delay · 2 people'), findsOneWidget);
    expect(find.text('Rostered, nobody attended'), findsOneWidget);
    expect(find.text('Manual claims awaiting review'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('attendance-kpi-pending_approval')));
    expect(_repo.recordQueries.last['status'], 'pending_approval');
    expect(_repo.recordQueries.last['from'], isNull);
    expect(_repo.recordQueries.last['to'], isNull);
    expect(
      find.text('Showing every claim awaiting a decision, whenever it was '
          'typed — the week above does not apply.'),
      findsOneWidget,
    );

    await _tap(tester, find.byKey(const ValueKey('attendance-kpi-pending_approval')));
    expect(_repo.recordQueries.last['status'], isNull);
    expect(find.textContaining('the week above does not apply'), findsNothing);

    await _tap(tester, find.byKey(const ValueKey('attendance-kpi-missed')));
    expect(_repo.recordQueries.last['status'], 'missed');
    expect(_repo.recordQueries.last['from'], isNotNull);
  });

  testWidgets('BUG08: rows carry web columns and pending-only actions',
      (tester) async {
    await _pumpAttendance(tester);

    expect(find.text('Maya Rahman'), findsOneWidget);
    expect(find.text('29/09/2026'), findsNWidgets(2));
    expect(find.text('08:00 – 16:00'), findsOneWidget);
    expect(find.text('5m late'), findsOneWidget);
    expect(find.text('7h 30m'), findsOneWidget);
    expect(find.text('30m break'), findsOneWidget);
    expect(find.text('On site · 12 m'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);

    expect(find.text('09:00 – Still in'), findsOneWidget);
    expect(find.text('No location'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);

    expect(find.byKey(const ValueKey('attendance-approve-r1')), findsOneWidget);
    expect(find.byKey(const ValueKey('attendance-reject-r1')), findsOneWidget);
    expect(find.byKey(const ValueKey('attendance-approve-r2')), findsNothing);
    expect(find.byKey(const ValueKey('attendance-correct-r2')), findsOneWidget);
    expect(find.byKey(const ValueKey('attendance-delete-r2')), findsOneWidget);

    await _scrollTo(tester, find.text('Showing 1 to 2 of 2 entries'));
    expect(find.text('Showing 1 to 2 of 2 entries'), findsOneWidget);
    expect(find.text('20 / Page'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('attendance-approve-r1')));
    expect(_repo.approved, ['r1']);
    expect(find.text('Attendance approved'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('attendance-reject-r1')));
    expect(_repo.rejected, ['r1']);

    await _tap(tester, find.byKey(const ValueKey('attendance-delete-r2')));
    expect(find.text('Delete this attendance record?'), findsOneWidget);
    expect(
      find.text('It leaves the list and stops counting towards pay. The record '
          'and any approval on it are kept, so it can be restored.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('attendance-delete-confirm')));
    await tester.pumpAndSettle();
    expect(_repo.deleted, ['r2']);
    expect(find.text('Attendance record deleted'), findsOneWidget);
  });

  testWidgets('BUG08: pagination pages and changes page size', (tester) async {
    await _pumpAttendance(tester, configure: (repo) => repo.total = 45);

    await _scrollTo(tester, find.text('Showing 1 to 20 of 45 entries'));
    expect(find.text('Showing 1 to 20 of 45 entries'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('attendance-page-next')));
    expect(_repo.recordQueries.last['page'], 2);
    await _scrollTo(tester, find.text('Showing 21 to 40 of 45 entries'));
    expect(find.text('Showing 21 to 40 of 45 entries'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('attendance-page-size')));
    for (final size in const ['10', '25', '50']) {
      expect(find.text(size), findsWidgets);
    }
    await tester.tap(find.text('50').last);
    await tester.pumpAndSettle();
    expect(_repo.recordQueries.last['limit'], 50);
    expect(_repo.recordQueries.last['page'], 1);
  });

  testWidgets('BUG08: Correct opens the prefilled Edit Attendance Entry '
      'wizard and PATCHes the web body', (tester) async {
    await _pumpAttendance(tester);

    await _tap(tester, find.byKey(const ValueKey('attendance-correct-r1')));
    expect(find.text('Edit Attendance Entry'), findsOneWidget);
    expect(find.text('Save correction'), findsOneWidget);
    expect(find.text('Maya Rahman'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Elm House'), findsOneWidget);
    expect(find.text('STEP 4 OF 4'), findsOneWidget);

    await _tap(tester, _stepTab('Time Correction'));
    expect(find.text('CLOCKED IN'), findsOneWidget);
    expect(find.text('CLOCKED OUT'), findsOneWidget);
    expect(find.text('2026-09-29 08:00'), findsOneWidget);
    expect(
      find.text('Kept by the system when the times are first changed. '
          'Recorded span 8h 0m.'),
      findsOneWidget,
    );
    expect(
      find.text('This entry works out at 7h 30m — 8h 0m less a 30-minute break.'),
      findsOneWidget,
    );

    await _tap(tester, _stepTab('Reason & Evidence'));
    expect(find.text("Covered someone else's shift"), findsOneWidget);
    expect(find.text('Covered for Priya'), findsOneWidget);
    expect(find.text('rota.png'), findsOneWidget);

    await _tap(tester, _stepTab('Approval'));
    expect(find.text("Approver's note", findRichText: true), findsOneWidget);
    expect(find.text('Leave as pending to let someone else weigh it.'),
        findsOneWidget);
    expect(find.text('30 minutes'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('manual-entry-save')));
    final body = _repo.patched['r1']!;
    expect(body.keys.toSet(), {
      'checkInAt',
      'checkOutAt',
      'breakMinutes',
      'status',
      'reasonCategory',
      'notes',
      'evidence',
    });
    expect(body['checkInAt'], DateTime(2026, 9, 29, 8).toUtc().toIso8601String());
    expect(body['breakMinutes'], 30);
    expect(body['status'], 'pending_approval');
    expect(body['reasonCategory'], 'shift_swap');
    expect(body['notes'], 'Covered for Priya');
    expect(body['evidence'], [
      {'fileUrl': '/api/v1/files/rota.png', 'fileType': 'image/png'},
    ]);
    expect(find.text('Correction recorded'), findsOneWidget);
    expect(find.text('Edit Attendance Entry'), findsNothing);
  });

  testWidgets('BUG08: Manual Entry validates with the web messages and '
      'counts completed steps', (tester) async {
    await _pumpAttendance(tester);

    await _tap(tester, find.byKey(const ValueKey('attendance-manual-entry')));
    expect(find.text('Manual Attendance Entry'), findsOneWidget);
    expect(find.text('Save entry'), findsOneWidget);
    expect(find.text('STEP 1 OF 4'), findsOneWidget);

    await _tap(tester, _stepTab('Time Correction'));
    expect(find.text('STEP 1 OF 4'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('manual-entry-save')));
    expect(
      find.text('Fix the highlighted field on "Attendance Details" before saving.'),
      findsOneWidget,
    );
    expect(find.text('Select a staff member'), findsOneWidget);
    expect(find.text('Select a residence'), findsOneWidget);
    expect(_repo.created, isEmpty);
  });

  testWidgets('BUG09: moving between Manual Entry steps never advances the '
      'progress; only filling a step does', (tester) async {
    await _pumpAttendance(tester);
    await _tap(tester, find.byKey(const ValueKey('attendance-manual-entry')));

    // Approval status starts at "Pending approval", which the web counts.
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    for (final tab in const [
      'Time Correction',
      'Reason & Evidence',
      'Approval',
      'Attendance Details',
      'Approval',
    ]) {
      await _tap(tester, _stepTab(tab));
      expect(find.text('STEP 1 OF 4'), findsOneWidget, reason: 'after $tab');
    }

    await _tap(tester, _stepTab('Attendance Details'));
    await _choose(tester, find.text('Select residence'), 'Elm House');
    expect(find.text('STEP 1 OF 4'), findsOneWidget,
        reason: 'residence alone does not complete the details step');

    await tester.enterText(find.byType(TextField).first, 'Ma');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Maya Rahman').last);
    expect(find.text('STEP 2 OF 4'), findsOneWidget);

    await _tap(tester, _stepTab('Reason & Evidence'));
    expect(find.text('STEP 2 OF 4'), findsOneWidget);
    await _choose(
      tester,
      find.text('Why is this being entered by hand?'),
      'Forgot clock-in',
    );
    expect(find.text('STEP 3 OF 4'), findsOneWidget);

    await _tap(tester, _stepTab('Approval'));
    await _tap(tester, _stepTab('Time Correction'));
    expect(find.text('STEP 3 OF 4'), findsOneWidget);
    expect(_repo.created, isEmpty);
  });

  testWidgets('BUG08: Clock in sheet follows the rota and the web copy',
      (tester) async {
    await _pumpAttendance(tester);

    await _tap(tester, find.byKey(const ValueKey('attendance-clock')));
    expect(find.text('Clock in'), findsWidgets);
    expect(
      find.text('The photo and the location are recorded with the time. '
          'Neither is required — without them the record simply says so.'),
      findsOneWidget,
    );
    expect(find.text('You are not rostered on a shift right now'),
        findsOneWidget);
    expect(find.text('Rafi Ahmed'), findsOneWidget);
    expect(find.text('Clocking in as yourself.'), findsOneWidget);
    expect(find.text('Take the photo'), findsOneWidget);
    final submit = tester.widget<FilledButton>(
      find.byKey(const ValueKey('attendance-clock-submit')),
    );
    expect(submit.onPressed, isNull);
  });

  testWidgets('BUG08: Clock out posts location, photo and early-leave reason',
      (tester) async {
    tester.view.physicalSize = const Size(375, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _setUpDeps();
    final now = DateTime.now();
    _repo.shift = AttendanceShiftWindow(
      shiftId: 'shift-1',
      residenceId: 'elm',
      residenceName: 'Elm House',
      startsAt: now.subtract(const Duration(hours: 2)),
      endsAt: now.add(const Duration(hours: 3)),
      isCurrent: true,
    );

    await tester.pumpWidget(
      _app(
        AttendanceClockPage(
          clockOut: true,
          openAttendance: const OpenAttendance(
            id: 'open-1',
            residenceId: 'elm',
            residenceName: 'Elm House',
          ),
          locate: () async => const ClockLocation(
            latitude: 23.8,
            longitude: 90.4,
            accuracyMeters: 9,
          ),
          takePhoto: () async => '/tmp/clock.jpg',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clock out'), findsWidgets);
    expect(find.text('Elm House'), findsOneWidget);
    expect(
      find.text('Where you clocked in — a shift is signed off at the home it '
          'was started at.'),
      findsOneWidget,
    );
    expect(find.textContaining('Your shift runs until'), findsOneWidget);
    expect(find.text('Location found'), findsOneWidget);
    expect(find.text('accurate to about 9 m'), findsOneWidget);

    await _choose(tester, find.text('Choose a reason (optional)'), 'Unwell');
    await _tap(tester, find.byKey(const ValueKey('attendance-clock-photo')));
    expect(find.text('Take another'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('attendance-clock-submit')));
    expect(_repo.clockOutBody, {
      'staffId': 'staff-me',
      'residenceId': 'elm',
      'shiftId': 'shift-1',
      'latitude': 23.8,
      'longitude': 90.4,
      'accuracyMeters': 9,
      'selfieUrl': '/api/v1/files/attendance-selfies/clock-out.jpg',
      'earlyDepartureReason': 'unwell',
    });
  });
}
