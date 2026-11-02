import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/create_shift_draft.dart';
import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/scheduling_overview.dart';
import 'package:comprehensive_hr_and_ops/core/time/tenant_clock.dart';
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

    test('bidding deadline uses the tenant timezone, not the phone clock', () {
      TenantClock.use('America/Vancouver');
      addTearDown(() => TenantClock.use(null));

      final draft = CreateShiftDraft(
        residenceId: 'r1',
        shiftDate: DateTime(2026, 12, 15),
      )
        ..shiftType = 'custom'
        ..startMinutes = 60
        ..endMinutes = 90
        ..isOpenShift = true
        ..biddingDeadlineDate = DateTime(2026, 12, 15)
        ..biddingDeadlineMinutes = 30;

      final body = draft.toCreateBody();
      final starts = DateTime.parse(body['startsAt'] as String).toUtc();
      final deadline = DateTime.parse(
        (body['biddingConfig'] as Map)['biddingClosesAt'] as String,
      ).toUtc();
      expect(deadline, DateTime.utc(2026, 12, 15, 7, 30));
      expect(starts, DateTime.utc(2026, 12, 15, 8));
      expect(deadline.isBefore(starts), isTrue);
      expect(
        draft.validate().containsKey(CreateShiftField.biddingDeadline),
        isFalse,
      );

      draft.biddingDeadlineMinutes = 120;
      expect(
        draft.validate()[CreateShiftField.biddingDeadline],
        'Bidding deadline cannot be after the shift begins',
      );

      draft
        ..biddingDeadlineDate = DateTime(2026, 10, 30)
        ..biddingDeadlineMinutes = 30;
      expect(
        draft.validate()[CreateShiftField.biddingDeadline],
        'Bidding deadline cannot be in the past',
      );
    });
  });
}
