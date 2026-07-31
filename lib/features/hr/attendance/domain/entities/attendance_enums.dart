/// Which segmented tab is currently selected on the Attendance screen.
enum AttendanceTab { today, late, missed, ot }

/// Color/semantic grouping for a single [AttendanceStat] tile - drives the
/// icon tint and background of the small stat tiles shown at the top of
/// every Attendance tab.
enum AttendanceStatTone { positive, warning, critical, info }

/// Clock-in outcome for a row in the "Today" tab's Staff Status list.
enum StaffAttendanceStatus { onTime, late, missed }

/// Overtime severity for a row in the "OT" tab's tracking list.
enum OvertimeStatus { exceeded, approaching }
