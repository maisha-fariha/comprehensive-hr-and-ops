import 'package:gems_core/gems_core.dart';

import '../../attendance_assets.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_overview.dart';
import '../../domain/entities/attendance_stat.dart';
import '../../domain/entities/late_arrival_entry.dart';
import '../../domain/entities/missed_clock_in_entry.dart';
import '../../domain/entities/overtime_entry.dart';
import '../../domain/entities/staff_status_entry.dart';
import '../../domain/repositories/attendance_repository.dart';

/// Local implementation of [AttendanceRepository].
///
/// There is no backend endpoint for attendance yet, so this returns static
/// content reproduced from the reference "Today / Late / Missed / OT -
/// Attendance" screenshots. A couple of rows that were cropped off the
/// bottom edge of the source screenshots (the 3rd "Late Arrivals" card and
/// the 3rd "Overtime Tracking" card) have their schedule/OT figures
/// estimated by extrapolating from the fully-visible rows so the header
/// stat counts ("Affected: 3", "Approaching: 2") stay internally
/// consistent; replace them with exact values once the real Figma file is
/// reachable again.
class AttendanceRepositoryImpl implements AttendanceRepository {
  @override
  Future<Result<AttendanceOverview>> getOverview() async {
    return Result.success(
      const AttendanceOverview(
        lateCount: 3,
        missedCount: 1,
        otCount: 2,
        todayStats: [
          AttendanceStat(
            id: 'on-time',
            value: '14',
            label: 'On Time',
            tone: AttendanceStatTone.positive,
            iconAsset: AttendanceAssets.onTime,
          ),
          AttendanceStat(
            id: 'late',
            value: '3',
            label: 'Late',
            tone: AttendanceStatTone.warning,
            iconAsset: AttendanceAssets.late,
          ),
          AttendanceStat(
            id: 'missed',
            value: '1',
            label: 'Missed',
            tone: AttendanceStatTone.critical,
            iconAsset: AttendanceAssets.missed,
          ),
          AttendanceStat(
            id: 'on-duty',
            value: '17',
            label: 'On Duty',
            tone: AttendanceStatTone.info,
            iconAsset: AttendanceAssets.onDuty,
          ),
        ],
        staffOnDutyLabel: '17 on duty',
        staffStatus: [
          StaffStatusEntry(
            id: 'sarah-j',
            name: 'Sarah J.',
            initials: 'SJ',
            avatarPaletteIndex: 0,
            status: StaffAttendanceStatus.onTime,
            secondaryText: 'On Site · 200 ft',
            timeLabel: '7:01 AM',
          ),
          StaffStatusEntry(
            id: 'mike-t',
            name: 'Mike T.',
            initials: 'MT',
            avatarPaletteIndex: 1,
            status: StaffAttendanceStatus.late,
            secondaryText: 'On Site · 350 ft',
            timeLabel: '7:12 AM',
          ),
          StaffStatusEntry(
            id: 'priya-k',
            name: 'Priya K.',
            initials: 'PK',
            avatarPaletteIndex: 0,
            status: StaffAttendanceStatus.onTime,
            secondaryText: 'On Site · 120 ft',
            timeLabel: '7:03 AM',
          ),
          StaffStatusEntry(
            id: 'james-l',
            name: 'James L.',
            initials: 'JL',
            avatarPaletteIndex: 4,
            status: StaffAttendanceStatus.missed,
            secondaryText: 'No clock in',
          ),
          StaffStatusEntry(
            id: 'nina-p',
            name: 'Nina P.',
            initials: 'NP',
            avatarPaletteIndex: 2,
            status: StaffAttendanceStatus.onTime,
            secondaryText: 'On Site · 180 ft',
            timeLabel: '7:08 AM',
          ),
        ],
        lateStats: [
          AttendanceStat(
            id: 'late-today',
            value: '3',
            label: 'Late Today',
            tone: AttendanceStatTone.warning,
            iconAsset: AttendanceAssets.late,
          ),
          AttendanceStat(
            id: 'avg-delay',
            value: '14m',
            label: 'Avg Delay',
            tone: AttendanceStatTone.warning,
            iconAsset: AttendanceAssets.avgDelay,
          ),
          AttendanceStat(
            id: 'affected',
            value: '3',
            label: 'Affected',
            tone: AttendanceStatTone.info,
            iconAsset: AttendanceAssets.onDuty,
          ),
        ],
        lateArrivals: [
          LateArrivalEntry(
            id: 'mike-t',
            name: 'Mike T.',
            role: 'Caregiver',
            avatarPaletteIndex: 3,
            lateLabel: '18 min late',
            scheduledRange: '7:00 AM – 3:00 PM',
            clockedInTime: '7:18 AM',
            distanceLabel: 'On Site · 350 ft',
          ),
          LateArrivalEntry(
            id: 'dana-s',
            name: 'Dana S.',
            role: 'RN',
            avatarPaletteIndex: 2,
            lateLabel: '11 min late',
            scheduledRange: '7:00 AM – 3:00 PM',
            clockedInTime: '7:11 AM',
            distanceLabel: 'On Site · 220 ft',
          ),
          LateArrivalEntry(
            id: 'lee-w',
            name: 'Lee W.',
            role: 'CNA',
            avatarPaletteIndex: 0,
            lateLabel: '13 min late',
            // Cropped off the bottom of the reference screenshot; estimated
            // from the same shift pattern as the other rows.
            scheduledRange: '7:00 AM – 3:00 PM',
            clockedInTime: '7:13 AM',
            distanceLabel: 'On Site · 150 ft',
          ),
        ],
        missedStats: [
          AttendanceStat(
            id: 'missed-today',
            value: '1',
            label: 'Missed Today',
            tone: AttendanceStatTone.critical,
            iconAsset: AttendanceAssets.missedToday,
          ),
          AttendanceStat(
            id: 'critical',
            value: '1',
            label: 'Critical',
            tone: AttendanceStatTone.critical,
            iconAsset: AttendanceAssets.critical,
          ),
          AttendanceStat(
            id: 'needs-review',
            value: '1',
            label: 'Needs Review',
            tone: AttendanceStatTone.info,
            iconData: AttendanceMaterialIconFallback.needsReview,
          ),
        ],
        missedClockIns: [
          MissedClockInEntry(
            id: 'james-l',
            name: 'James L.',
            roleShiftLabel: 'RN · 7:00 AM – 3:00 PM',
            avatarPaletteIndex: 4,
            reasonLabel: 'Not recorded',
          ),
          MissedClockInEntry(
            id: 'omar-f',
            name: 'Omar F.',
            roleShiftLabel: 'Caregiver · 3:00 PM – 11:00 PM',
            avatarPaletteIndex: 4,
            reasonLabel: 'Shift missed',
          ),
        ],
        otStats: [
          AttendanceStat(
            id: 'total-ot-hours',
            value: '18.5h',
            label: 'Total OT Hours',
            tone: AttendanceStatTone.warning,
            iconAsset: AttendanceAssets.late,
          ),
          AttendanceStat(
            id: 'over-limit',
            value: '1',
            label: 'Over Limit',
            tone: AttendanceStatTone.critical,
            iconAsset: AttendanceAssets.critical,
          ),
          AttendanceStat(
            id: 'approaching',
            value: '2',
            label: 'Approaching',
            tone: AttendanceStatTone.warning,
            iconAsset: AttendanceAssets.approachingLimit,
          ),
        ],
        overtimeEntries: [
          OvertimeEntry(
            id: 'tyler-m',
            name: 'Tyler M.',
            roleShiftLabel: 'RN · 7:00 AM – 3:00 PM',
            avatarPaletteIndex: 1,
            status: OvertimeStatus.exceeded,
            otTodayLabel: '2h 30m',
            weeklyTotalLabel: '46.5h',
            progress: 0.97,
            limitCaption: 'Limit 48h · exceeded',
          ),
          OvertimeEntry(
            id: 'nina-p',
            name: 'Nina P.',
            roleShiftLabel: 'CNA · 3:00 PM – 11:00 PM',
            avatarPaletteIndex: 1,
            status: OvertimeStatus.approaching,
            otTodayLabel: '2h 00m',
            weeklyTotalLabel: '42.5h',
            progress: 0.885,
            limitCaption: 'Limit 48h · approaching',
          ),
          OvertimeEntry(
            id: 'chris-b',
            name: 'Chris B.',
            roleShiftLabel: 'Caregiver · 11:00 PM – 7:00 AM',
            avatarPaletteIndex: 3,
            status: OvertimeStatus.approaching,
            // Cropped off the bottom of the reference screenshot; estimated
            // to keep the "Approaching: 2" header stat consistent.
            otTodayLabel: '1h 45m',
            weeklyTotalLabel: '40.0h',
            progress: 0.833,
            limitCaption: 'Limit 48h · approaching',
          ),
        ],
      ),
    );
  }
}
