import 'package:gems_core/gems_core.dart';

import '../../../staff_core_constants.dart';
import '../../domain/entities/shift_avatar.dart';
import '../../domain/entities/staff_schedule_overview.dart';
import '../../domain/entities/staff_shift.dart';
import '../../domain/entities/week_day.dart';
import '../../domain/repositories/staff_schedule_repository.dart';

/// Local implementation of [StaffScheduleRepository].
///
/// There is no backend endpoint for the staff schedule yet, so this
/// returns the exact static content shown in the reference screenshot.
/// Replace the body of [getOverview] with a real
/// `ApiService`/`BaseRepository` call once an API contract exists — the
/// domain layer and every widget above it will keep working unchanged.
class StaffScheduleRepositoryImpl implements StaffScheduleRepository {
  @override
  Future<Result<StaffScheduleOverview>> getOverview() async {
    return Result.success(
      const StaffScheduleOverview(
        weekRangeLabel: 'May 12 – May 18, 2025',
        weekDays: [
          WeekDay(dayLabel: 'Mon', dayNumber: '12'),
          WeekDay(dayLabel: 'Tue', dayNumber: '13', isSelected: true),
          WeekDay(dayLabel: 'Wed', dayNumber: '14'),
          WeekDay(dayLabel: 'Thu', dayNumber: '15'),
          WeekDay(dayLabel: 'Fri', dayNumber: '16'),
          WeekDay(dayLabel: 'Sat', dayNumber: '17'),
          WeekDay(dayLabel: 'Sun', dayNumber: '18'),
        ],
        shiftsThisWeekLabel: '3 this week',
        shifts: [
          StaffShift(
            id: 'morning-tue-13',
            title: 'Morning Shift',
            isToday: true,
            dateTimeLabel: 'Tue, May 13 · 7:00 AM – 3:00 PM (8h)',
            location: 'Sunrise Home',
            avatars: [ShiftAvatar('SJ'), ShiftAvatar('MT'), ShiftAvatar('PK')],
            extraStaffCount: 5,
            filled: 8,
            total: 10,
            roleTag: 'RN',
            statusLabel: 'Confirmed',
            staffingLevel: StaffingLevel.medium,
          ),
          StaffShift(
            id: 'evening-wed-14',
            title: 'Evening Shift',
            isToday: false,
            dateTimeLabel: 'Wed, May 14 · 3:00 PM – 11:00 PM (8h)',
            location: 'Sunrise Home',
            avatars: [ShiftAvatar('JL'), ShiftAvatar('NP')],
            extraStaffCount: 7,
            filled: 9,
            total: 10,
            roleTag: 'CNA',
            statusLabel: 'Confirmed',
            staffingLevel: StaffingLevel.high,
          ),
          StaffShift(
            id: 'morning-fri-16',
            title: 'Morning Shift',
            isToday: false,
            dateTimeLabel: 'Fri, May 16 · 7:00 AM – 3:00 PM (8h)',
            location: 'Sunrise Home',
            avatars: [ShiftAvatar('RA'), ShiftAvatar('DW')],
            extraStaffCount: 4,
            filled: 6,
            total: 10,
            roleTag: 'RN',
            statusLabel: 'Confirmed',
            staffingLevel: StaffingLevel.low,
          ),
        ],
      ),
    );
  }
}
