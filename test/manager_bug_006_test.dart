import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/create_shift_draft.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/scheduling_enums.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/scheduling_overview.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/shift_residence_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/shift_staff_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/shift_type_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/presentation/pages/create_shift_page.dart';
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

class _FakeSchedulingRepo implements SchedulingRepository {
  final List<Map<String, dynamic>> created = [];

  @override
  Future<Result<SchedulingOverview>> getOverview({
    DateTime? weekOf,
    DateTime? selectedDay,
    String? residenceId,
    ShiftStatusFilter? status,
    bool mine = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<List<ShiftResidenceOption>>> getResidences() async =>
      Result.success(const [
        ShiftResidenceOption(id: 'elm', name: 'Elm House'),
        ShiftResidenceOption(id: 'oak', name: 'Oak Lodge'),
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
        ShiftStaffOption(
          id: 'staff-teagan',
          name: 'Teagan Wolfe',
          detail: 'Dhaka',
          initials: 'TW',
          residenceLabel: 'Dhaka',
        ),
      ]);

  @override
  Future<Result<int>> createShift(Map<String, dynamic> payload) async {
    created.add(payload);
    final recurrence = payload['recurrence'];
    return Result.success(
      recurrence is Map ? recurrence['occurrences'] as int : 1,
    );
  }

  @override
  Future<Result<CreateShiftDraft>> getShiftDraft(String shiftId) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> updateShift({
    required String shiftId,
    required Map<String, dynamic> payload,
    required List<String> staffIds,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> decideShiftSwap({
    required String swapId,
    required bool approve,
  }) async =>
      Result.success(null);
}

class _Host extends StatefulWidget {
  final String? residenceId;

  const _Host({this.residenceId});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  Object? result = 'none';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('result: $result'),
            ElevatedButton(
              onPressed: () async {
                final value = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CreateShiftPage(
                      initialResidenceId: widget.residenceId,
                      initialShiftDate: DateTime(2026, 10, 5),
                    ),
                  ),
                );
                setState(() => result = value);
              },
              child: const Text('Open wizard'),
            ),
          ],
        ),
      ),
    );
  }
}

late _FakeSchedulingRepo _repo;

Future<void> _pumpWizard(WidgetTester tester, {String? residenceId}) async {
  tester.view.physicalSize = const Size(375, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  _repo = _FakeSchedulingRepo();
  GetIt.I.registerSingleton<SchedulingRepository>(_repo);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(
        ResponsiveHelper.baseWidth,
        ResponsiveHelper.baseHeight,
      ),
      minTextAdapt: true,
      builder: (_, _) => GetMaterialApp(
        home: _Host(residenceId: residenceId),
        theme: ThemeData(
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open wizard'));
  await tester.pumpAndSettle();
}

Finder _label(String text) => find.textContaining(text, findRichText: true);

Finder _tab(String label) => find.descendant(
      of: find.byType(CreateShiftStepTabs),
      matching: find.text(label),
    );

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pickResidence(WidgetTester tester, String name) async {
  await _tap(tester, find.byKey(const ValueKey('create-shift-residence')));
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _addStaff(WidgetTester tester, String name) async {
  await _tap(tester, find.byKey(const ValueKey('create-shift-add-staff')));
  await tester.enterText(
    find.byKey(const ValueKey('create-shift-staff-search')),
    name.split(' ').first.toLowerCase(),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(CheckboxListTile, name));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
}

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

  testWidgets('BUG06: Shift Information has exactly the web fields',
      (tester) async {
    await _pumpWizard(tester);

    for (final field in const [
      'Residence',
      'Shift Type',
      'Shift Date',
      'Start Time',
      'End Time',
      'Break Duration',
      'Title',
      'Shift Notes',
    ]) {
      expect(_label(field), findsWidgets, reason: field);
    }
    for (final removed in const [
      'Required Qualification',
      'Coverage Level',
      'People needed',
    ]) {
      expect(_label(removed), findsNothing, reason: removed);
    }
    expect(find.text('Morning (07:00 – 15:00)'), findsOneWidget);
    expect(find.text('07:00 AM'), findsOneWidget);
    expect(find.text('03:00 PM'), findsOneWidget);
    expect(find.text('30 minutes'), findsOneWidget);
    expect(find.text('Oct 5, 2026'), findsOneWidget);
    expect(find.text('Select residence'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('BUG06/BUG07: completion counts completed steps, not tabs',
      (tester) async {
    await _pumpWizard(tester);

    expect(find.text('STEP 0 OF 5'), findsOneWidget);
    expect(find.text('0% complete'), findsOneWidget);

    await _tap(tester, _tab('Recurring'));
    await _tap(tester, _tab('Notifications'));
    expect(find.text('0% complete'), findsOneWidget);

    await _tap(tester, _tab('Shift Information'));
    await _pickResidence(tester, 'Elm House');
    expect(find.text('STEP 1 OF 5'), findsOneWidget);
    expect(find.text('20% complete'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create-shift-step-done-shiftInformation')),
      findsOneWidget,
    );

    await _tap(tester, _tab('Staff Assignment'));
    await _addStaff(tester, 'Shakib Hasan');
    expect(find.text('STEP 2 OF 5'), findsOneWidget);
    expect(find.text('40% complete'), findsOneWidget);
  });

  testWidgets('BUG06: Next validates step 1 and Back returns', (tester) async {
    await _pumpWizard(tester);

    await _tap(tester, find.text('Next'));
    expect(find.text('Select a residence'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await _pickResidence(tester, 'Elm House');
    expect(find.text('Select a residence'), findsNothing);

    await _tap(tester, find.text('Next'));
    expect(_label('Assigned Staff'), findsWidgets);
    expect(find.text('Back'), findsOneWidget);

    await _tap(tester, find.text('Back'));
    expect(find.text('Elm House'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('BUG06: staff picker, task card and checklist', (tester) async {
    await _pumpWizard(tester, residenceId: 'elm');
    await _tap(tester, _tab('Staff Assignment'));

    expect(find.text('Assigned Staff (0)'), findsOneWidget);
    expect(
      find.text(
        'No staff assigned yet. Select above to add someone, or leave this shift open in the next step.',
      ),
      findsOneWidget,
    );

    await _tap(tester, find.byKey(const ValueKey('create-shift-add-staff')));
    expect(find.text('Search staff…'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Teagan Wolfe'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('create-shift-staff-search')),
      'shak',
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Teagan Wolfe'), findsNothing);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Shakib Hasan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Assigned Staff (1)'), findsOneWidget);
    expect(find.text('Care Worker · Elm House'), findsOneWidget);
    expect(find.text('Task Assignment'), findsOneWidget);
    expect(_label('Task Title'), findsOneWidget);
    expect(_label('Task Description'), findsOneWidget);
    expect(_label('Task Checklist'), findsOneWidget);
    expect(find.text('Leave empty to assign the shift without a task.'),
        findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('checklist-input-staff-shakib')),
      'Give 8am meds',
    );
    await _tap(tester, find.byKey(const ValueKey('checklist-add-staff-shakib')));
    expect(find.text('Give 8am meds'), findsOneWidget);
    expect(find.text('1 step'), findsOneWidget);

    await _tap(tester, find.byTooltip('Remove checklist item'));
    expect(find.text('Give 8am meds'), findsNothing);
    expect(find.text('1 step'), findsNothing);

    await _tap(
      tester,
      find.byKey(const ValueKey('assigned-staff-toggle-staff-shakib')),
    );
    expect(find.text('Task Assignment'), findsNothing);

    await _addStaff(tester, 'Teagan Wolfe');
    expect(find.text('Assigned Staff (2)'), findsOneWidget);
    expect(find.text('Dhaka'), findsOneWidget);

    await _tap(tester, find.byTooltip('Remove Shakib Hasan'));
    expect(find.text('Assigned Staff (1)'), findsOneWidget);
    expect(find.text('Shakib Hasan'), findsNothing);
  });

  testWidgets('BUG06: open shift and recurring reveal their full settings',
      (tester) async {
    await _pumpWizard(tester, residenceId: 'elm');

    await _tap(tester, _tab('Open Shift'));
    expect(_label('People needed'), findsNothing);
    await _tap(tester, find.byKey(const ValueKey('create-shift-open-toggle')));
    for (final field in const [
      'People needed',
      'Bidding Deadline',
      'Deadline Time',
      'Maximum Bids',
      'Priority',
      'Award Method',
      'Note to Bidders',
    ]) {
      expect(_label(field), findsWidgets, reason: field);
    }
    expect(find.text('06:00 PM'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Manager selects winner'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('create-shift-award-method')));
    await tester.tap(find.text('First come, first served'));
    await tester.pumpAndSettle();
    expect(find.text('First come, first served'), findsOneWidget);

    await _tap(tester, _tab('Recurring'));
    await _tap(
      tester,
      find.byKey(const ValueKey('create-shift-recurring-toggle')),
    );
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Leave empty to repeat purely on the frequency above.'),
        findsOneWidget);
    expect(
      find.textContaining('This will create 4 shifts.'),
      findsOneWidget,
    );

    await _tap(tester, find.byKey(const ValueKey('create-shift-weekday-1')));
    expect(
      find.textContaining('The frequency becomes the gap between weeks'),
      findsOneWidget,
    );

    await _tap(tester, find.byKey(const ValueKey('create-shift-ends-on_date')));
    expect(_label('End Date'), findsOneWidget);
    expect(
      find.text(
        'Pick a shift date and an end rule to see how many shifts this creates.',
      ),
      findsOneWidget,
    );

    await _tap(
      tester,
      find.byKey(const ValueKey('create-shift-ends-after_count')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('create-shift-occurrences')),
      '6',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('This will create 6 shifts.'), findsOneWidget);

    await _tap(tester, find.text('Next'));
    expect(find.text('Create 6 shifts'), findsOneWidget);
  });

  testWidgets('BUG06: notifications step matches the web', (tester) async {
    await _pumpWizard(tester, residenceId: 'elm');
    await _tap(tester, _tab('Notifications'));

    expect(find.text('Notify assigned staff'), findsOneWidget);
    expect(find.text('Select an option'), findsOneWidget);
    expect(
      find.text('A second notification this long before the shift starts.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Quiet hours, digesting and which channels'),
      findsOneWidget,
    );
    expect(find.text('Create shift'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('create-shift-reminder')));
    await tester.tap(find.text('24 hours before'));
    await tester.pumpAndSettle();
    expect(find.text('24 hours before'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('create-shift-reminder')));
    await tester.tap(find.text('No reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Select an option'), findsOneWidget);
  });

  testWidgets('BUG06: submit posts the web body and returns true',
      (tester) async {
    await _pumpWizard(tester, residenceId: 'elm');

    await tester.enterText(
      find.byKey(const ValueKey('create-shift-title')),
      '  Weekend cover ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create-shift-notes')),
      'Hand over keys',
    );
    await _tap(tester, _tab('Staff Assignment'));
    await _addStaff(tester, 'Shakib Hasan');
    await tester.enterText(
      find.byKey(const ValueKey('task-title-staff-shakib')),
      'Morning medication round',
    );
    await _tap(tester, _tab('Open Shift'));
    await _tap(tester, find.byKey(const ValueKey('create-shift-open-toggle')));
    await tester.enterText(
      find.byKey(const ValueKey('create-shift-people-needed')),
      '2',
    );
    await _tap(tester, _tab('Recurring'));
    await _tap(
      tester,
      find.byKey(const ValueKey('create-shift-recurring-toggle')),
    );
    await _tap(tester, find.byKey(const ValueKey('create-shift-weekday-5')));
    await _tap(tester, find.byKey(const ValueKey('create-shift-weekday-1')));
    await _tap(tester, _tab('Notifications'));
    await _tap(tester, find.byKey(const ValueKey('create-shift-reminder')));
    await tester.tap(find.text('1 hour before'));
    await tester.pumpAndSettle();

    await _tap(tester, find.text('Create 4 shifts'));

    expect(_repo.created, hasLength(1));
    final body = _repo.created.single;
    expect(body, {
      'residenceId': 'elm',
      'startsAt': DateTime(2026, 10, 5, 7).toUtc().toIso8601String(),
      'endsAt': DateTime(2026, 10, 5, 15).toUtc().toIso8601String(),
      'staffIds': ['staff-shakib'],
      'shiftType': 'morning',
      'breakMinutes': 30,
      'requiredStaffCount': 2,
      'reminderMinutesBefore': 60,
      'notifyAssignedStaff': true,
      'title': 'Weekend cover',
      'notes': 'Hand over keys',
      'biddingConfig': {
        'maxBids': 10,
        'priority': 'medium',
        'awardMethod': 'manual',
      },
      'recurrence': {
        'occurrences': 4,
        'intervalDays': 7,
        'weekdays': [1, 5],
      },
    });
    expect(find.text('result: true'), findsOneWidget);
    expect(find.text('4 shifts created'), findsOneWidget);
  });

  testWidgets('BUG06: submit jumps to the step with a validation error',
      (tester) async {
    await _pumpWizard(tester);
    await _tap(tester, _tab('Notifications'));
    await _tap(tester, find.text('Create shift'));

    expect(_repo.created, isEmpty);
    expect(find.text('Select a residence'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('BUG06: closing with edits asks to discard', (tester) async {
    await _pumpWizard(tester, residenceId: 'elm');

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('result: null'), findsOneWidget);

    await tester.tap(find.text('Open wizard'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('create-shift-title')),
      'Draft',
    );
    await _tap(tester, find.text('Cancel'));
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    expect(
      find.text(
        "You have unsaved edits on this form. If you leave now, they'll be lost.",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateShiftPage), findsOneWidget);

    await _tap(tester, find.text('Cancel'));
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateShiftPage), findsNothing);
  });

  group('CreateShiftDraft (web parity)', () {
    CreateShiftDraft draft() =>
        CreateShiftDraft(residenceId: 'elm', shiftDate: DateTime(2026, 10, 5));

    test('overnight end rolls to the next day', () {
      final d = draft()
        ..applyShiftType(
          ShiftTypeOption.predefined.firstWhere((o) => o.id == 'night'),
        );
      final body = d.toCreateBody();
      expect(body['startsAt'], DateTime(2026, 10, 5, 23).toUtc().toIso8601String());
      expect(body['endsAt'], DateTime(2026, 10, 6, 7).toUtc().toIso8601String());
      expect(body['biddingConfig'], isNull);
      expect(body.containsKey('requiredStaffCount'), isFalse);
      expect(body.containsKey('recurrence'), isFalse);
      expect(body['reminderMinutesBefore'], isNull);
    });

    test('same start and end is rejected', () {
      final d = draft()
        ..startMinutes = 480
        ..endMinutes = 480;
      expect(
        d.validate()[CreateShiftField.endTime],
        'A shift cannot end at the moment it starts',
      );
    });

    test('recurring rules report their own errors', () {
      final d = draft()
        ..isRecurring = true
        ..ends = ShiftRecurrenceEnd.onDate;
      expect(d.validate()[CreateShiftField.endDate], 'Pick the date it stops');
      d
        ..ends = ShiftRecurrenceEnd.afterCount
        ..occurrenceCount = '';
      expect(
        d.validate()[CreateShiftField.occurrenceCount],
        'Say how many shifts to create',
      );
    });

    test('plannedOccurrences follows the web maths', () {
      final d = draft()..isRecurring = true;
      d.occurrenceCount = '80';
      expect(d.plannedOccurrences(), 52);

      d
        ..ends = ShiftRecurrenceEnd.onDate
        ..endDate = DateTime(2026, 11, 1);
      // 28 days, weekly, no weekdays: ceil(28 / 7).
      expect(d.plannedOccurrences(), 4);

      // Mon + Fri every week across 5 Oct – 1 Nov: 4 Mondays + 4 Fridays.
      d.repeatOnDays.addAll({1, 5});
      expect(d.plannedOccurrences(), 8);

      // Bi-weekly keeps weeks 0 and 2 only.
      d.recurrenceFrequency = 14;
      expect(d.plannedOccurrences(), 4);

      d.endDate = DateTime(2026, 10, 1);
      expect(d.plannedOccurrences(), 0);
    });

    test('step completion only counts steps with required fields', () {
      final d = CreateShiftDraft(shiftDate: DateTime(2026, 10, 5));
      expect(d.completionPercent, 0);
      d.residenceId = 'elm';
      expect(d.completionPercent, 20);
      d.assignedStaff.add(
        AssignedShiftStaff(staffId: 's1', staffName: 'Shakib Hasan'),
      );
      d
        ..isOpenShift = true
        ..isRecurring = true;
      expect(d.completedSteps, 2);
      expect(d.completionPercent, 40);
    });
  });
}
