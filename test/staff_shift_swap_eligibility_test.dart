import 'package:comprehensive_hr_and_ops/features/staff/scheduling/domain/entities/staff_shift.dart';
import 'package:comprehensive_hr_and_ops/features/staff/staff_core_constants.dart';
import 'package:flutter_test/flutter_test.dart';

StaffShift _shift({
  required DateTime startAt,
  String apiStatus = 'published',
}) {
  return StaffShift(
    id: 's1',
    title: 'Morning',
    isToday: true,
    dateTimeLabel: 'Today',
    location: 'Home',
    avatars: const [],
    extraStaffCount: 0,
    filled: 1,
    total: 1,
    openSlots: 0,
    roleTag: 'Carer',
    statusLabel: 'Confirmed',
    staffingLevel: StaffingLevel.high,
    apiStatus: apiStatus,
    startAt: startAt,
  );
}

void main() {
  test('canRequestSwap is true only for future non-cancelled shifts', () {
    final future = DateTime.now().add(const Duration(hours: 2));
    final past = DateTime.now().subtract(const Duration(hours: 2));

    expect(_shift(startAt: future).canRequestSwap, isTrue);
    expect(_shift(startAt: past).canRequestSwap, isFalse);
    expect(
      _shift(startAt: future, apiStatus: 'cancelled').canRequestSwap,
      isFalse,
    );
    expect(
      _shift(startAt: future, apiStatus: 'canceled').canRequestSwap,
      isFalse,
    );
  });
}
