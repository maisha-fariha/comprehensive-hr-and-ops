import 'package:gems_core/gems_core.dart';

import '../../domain/entities/board_overview.dart';
import '../../domain/entities/board_shift.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/calendar_schedule.dart';
import '../../domain/entities/calendar_shift.dart';
import '../../domain/entities/coverage_summary.dart';
import '../../domain/entities/open_position.dart';
import '../../domain/entities/requests_overview.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../../domain/entities/shift_request.dart';
import '../../domain/entities/staff_avatar.dart';
import '../../domain/repositories/scheduling_repository.dart';

/// Local implementation of [SchedulingRepository].
///
/// There is no backend endpoint for Scheduling yet, so this returns the
/// exact static content shown in the Figma design (see the "Scheduling"
/// group's Calendar/Board/Requests frames). Replace the body of
/// [getOverview] with a real `ApiService`/`BaseRepository` call once an API
/// contract exists — the domain layer and every widget above it will keep
/// working unchanged.
class SchedulingRepositoryImpl implements SchedulingRepository {
  @override
  Future<Result<SchedulingOverview>> getOverview() async {
    return Result.success(
      const SchedulingOverview(
        calendar: CalendarSchedule(
          monthLabel: 'May 2025',
          days: [
            CalendarDay(dayLabel: 'Mon', dayNumber: '12', hasShiftIndicator: true),
            CalendarDay(dayLabel: 'Tue', dayNumber: '13', isSelected: true, hasShiftIndicator: false),
            CalendarDay(dayLabel: 'Wed', dayNumber: '14', hasShiftIndicator: false),
            CalendarDay(dayLabel: 'Thu', dayNumber: '15', hasShiftIndicator: false),
            CalendarDay(dayLabel: 'Fri', dayNumber: '16', hasShiftIndicator: false),
            CalendarDay(dayLabel: 'Sat', dayNumber: '17', hasShiftIndicator: false),
            CalendarDay(dayLabel: 'Sun', dayNumber: '18', hasShiftIndicator: false),
          ],
          selectedDateLabel: 'Tuesday, May 13',
          shiftsSummaryLabel: '3 shifts scheduled',
          openShiftsLabel: '3 open',
          shifts: [
            CalendarShift(
              id: 'cal-morning',
              startTime: '7:00',
              startPeriod: 'AM',
              name: 'Morning Shift',
              timeRange: '7:00 AM – 3:00 PM',
              filled: 8,
              total: 10,
              status: CoverageStatus.almostFull,
              avatars: [StaffAvatar('SJ'), StaffAvatar('MT'), StaffAvatar('PK')],
              namesSummary: 'Sarah, Mike +6',
              openPositionsLabel: '2 open · RN',
            ),
            CalendarShift(
              id: 'cal-afternoon',
              startTime: '3:00',
              startPeriod: 'PM',
              name: 'Afternoon Shift',
              timeRange: '3:00 PM – 11:00 PM',
              filled: 6,
              total: 9,
              status: CoverageStatus.needsAttention,
              avatars: [StaffAvatar('JL'), StaffAvatar('NP')],
              namesSummary: 'James, Nina +4',
              openPositionsLabel: '3 open · CNA',
            ),
            CalendarShift(
              id: 'cal-night',
              startTime: '11:00',
              startPeriod: 'PM',
              name: 'Night Shift',
              timeRange: '11:00 PM – 7:00 AM',
              filled: 7,
              total: 8,
              status: CoverageStatus.almostFull,
              avatars: [StaffAvatar('TM'), StaffAvatar('DS')],
              namesSummary: 'Tyler, Dana +5',
              showTimelineDivider: false,
            ),
          ],
        ),
        board: BoardOverview(
          coverageSummaries: [
            CoverageSummary(
              periodLabel: 'Morning',
              ratioLabel: '8/10',
              status: CoverageStatus.almostFull,
              statusLabel: 'Almost Full',
            ),
            CoverageSummary(
              periodLabel: 'Evening',
              ratioLabel: '6/9',
              status: CoverageStatus.needsAttention,
              statusLabel: 'Needs Attention',
            ),
            CoverageSummary(
              periodLabel: 'Night',
              ratioLabel: '7/8',
              status: CoverageStatus.almostFull,
              statusLabel: 'Almost Full',
            ),
          ],
          shifts: [
            BoardShift(
              id: 'board-morning',
              periodLabel: 'Morning',
              timeRange: '7:00 AM – 3:00 PM',
              filled: 8,
              total: 10,
              status: CoverageStatus.almostFull,
              statusLabel: 'Almost Full',
              avatars: [StaffAvatar('SJ'), StaffAvatar('MT'), StaffAvatar('PK')],
              extraStaffCount: 5,
              roleChips: ['RN', 'CNA', 'Caregiver'],
              neededLabel: '2 RN needed',
            ),
            BoardShift(
              id: 'board-evening',
              periodLabel: 'Evening',
              timeRange: '3:00 PM – 11:00 PM',
              filled: 6,
              total: 9,
              status: CoverageStatus.needsAttention,
              statusLabel: 'Needs Attention',
              avatars: [StaffAvatar('JL'), StaffAvatar('NP')],
              extraStaffCount: 4,
              roleChips: ['RN', 'CNA'],
              neededLabel: '2 CNA needed',
            ),
            BoardShift(
              id: 'board-night',
              periodLabel: 'Night',
              timeRange: '11:00 PM – 7:00 AM',
              filled: 7,
              total: 8,
              status: CoverageStatus.almostFull,
              statusLabel: 'Almost Full',
              avatars: [StaffAvatar('TM'), StaffAvatar('DS')],
              extraStaffCount: 5,
              roleChips: ['RN', 'CNA'],
              neededLabel: '1 RN needed',
            ),
          ],
          openPositions: [
            OpenPosition(
              id: 'open-rn',
              roleTitle: 'RN Needed',
              urgency: OpenPositionUrgency.urgent,
              subtitle: 'Morning Shift · Pinecrest Manor',
            ),
            OpenPosition(
              id: 'open-cna',
              roleTitle: 'CNA Needed',
              urgency: OpenPositionUrgency.open,
              subtitle: 'Evening Shift · Oakwood Heights',
            ),
          ],
        ),
        requests: RequestsOverview(
          pendingRequests: [
            ShiftRequest(
              id: 'req-sarah',
              staffName: 'Sarah J.',
              staffInitials: 'SJ',
              status: RequestStatus.pending,
              timingLabel: 'Requested 2h ago',
              givingLabel: 'Tue May 13 · Morning',
              receivingLabel: 'Wed May 14 · Morning',
            ),
            ShiftRequest(
              id: 'req-nina',
              staffName: 'Nina P.',
              staffInitials: 'NP',
              status: RequestStatus.pending,
              timingLabel: 'Requested 5h ago',
              givingLabel: 'Thu May 15 · Evening',
              receivingLabel: 'Fri May 16 · Evening',
            ),
          ],
          approvedRequests: [
            ShiftRequest(
              id: 'req-james',
              staffName: 'James L.',
              staffInitials: 'JL',
              status: RequestStatus.approved,
              timingLabel: 'Approved yesterday',
              givingLabel: 'Mon May 12 · Night',
              receivingLabel: 'Tue May 13 · Night',
            ),
          ],
        ),
      ),
    );
  }
}
