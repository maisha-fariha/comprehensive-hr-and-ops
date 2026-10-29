import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/create_shift_draft.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/scheduling_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feedback 9–19 scheduling / daily-log helpers', () {
    test('empty week coverage uses nothing-on-roster copy', () {
      expect(
        WeekShiftCoverage.empty.coveredDescription,
        'Nothing on the roster this week yet',
      );
    });

    test('equal start/end times fail validation immediately', () {
      final draft = CreateShiftDraft(
        residenceId: 'r1',
        shiftDate: DateTime(2026, 10, 30),
      )
        ..startMinutes = 9 * 60
        ..endMinutes = 9 * 60;
      expect(
        draft.validate()[CreateShiftField.endTime],
        'A shift cannot end at the moment it starts',
      );
    });

    test('overnight end before start stays valid (rolls +1 day)', () {
      final draft = CreateShiftDraft(
        residenceId: 'r1',
        shiftDate: DateTime(2026, 10, 30),
      )
        ..startMinutes = 23 * 60
        ..endMinutes = 7 * 60;
      expect(draft.validate().containsKey(CreateShiftField.endTime), isFalse);
      final body = draft.toCreateBody();
      final starts = DateTime.parse(body['startsAt'] as String);
      final ends = DateTime.parse(body['endsAt'] as String);
      expect(ends.isAfter(starts), isTrue);
    });

    test('open shift staffing skips assigned-staff requirement', () {
      final draft = CreateShiftDraft(
        residenceId: 'r1',
        shiftDate: DateTime(2026, 10, 30),
      )..isOpenShift = true;
      expect(
        draft.validateStep(CreateShiftStep.staffAssignment),
        isEmpty,
      );
      expect(draft.isStepComplete(CreateShiftStep.staffAssignment), isTrue);
      expect(draft.isStepComplete(CreateShiftStep.openShift), isTrue);
    });

    test('assign staffing still requires at least one staff member', () {
      final draft = CreateShiftDraft(
        residenceId: 'r1',
        shiftDate: DateTime(2026, 10, 30),
      );
      expect(
        draft.validateStep(CreateShiftStep.staffAssignment),
        containsPair(
          CreateShiftField.assignedStaff,
          'Assign at least one staff member',
        ),
      );
    });

    test('open shift create body includes bidding + notify flag', () {
      final draft = CreateShiftDraft(
        residenceId: 'r1',
        shiftDate: DateTime(2026, 10, 30),
      )
        ..isOpenShift = true
        ..notifyAssignedStaff = true
        ..requiredStaffCount = '2'
        ..maxBids = '8'
        ..priority = 'high'
        ..awardMethod = 'manual';
      final body = draft.toCreateBody();
      expect(body['open'], isTrue);
      expect(body['notifyAssignedStaff'], isTrue);
      expect(body['requiredStaffCount'], 2);
      expect(body['biddingConfig'], isA<Map>());
      expect((body['biddingConfig'] as Map)['maxBids'], 8);
    });
  });
}
