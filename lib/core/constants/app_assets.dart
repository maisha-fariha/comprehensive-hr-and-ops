/// Paths to vector icon assets exported directly from Figma. Keeping every
/// path in one place avoids typo-prone magic strings scattered across
/// feature modules.
abstract final class AppAssets {
  static const String _dashboard = 'assets/icons/dashboard';
  static const String _nav = 'assets/icons/nav';
  static const String _common = 'assets/icons/common';

  // Dashboard / status card icons
  static const String alertTriangle = '$_dashboard/alert_triangle.svg';
  static const String clock = '$_dashboard/clock.svg';
  static const String users = '$_dashboard/users.svg';
  static const String alertCircle = '$_dashboard/alert_circle.svg';
  static const String pill = '$_dashboard/pill.svg';
  static const String clipboardCheck = '$_dashboard/clipboard_check.svg';
  static const String calendarCheck = '$_dashboard/calendar_check.svg';
  static const String flag = '$_dashboard/flag.svg';
  static const String calendarPlus = '$_dashboard/calendar_plus.svg';
  static const String checkCircle = '$_dashboard/check_circle.svg';
  static const String notePencil = '$_dashboard/note_pencil.svg';
  static const String messageCircle = '$_dashboard/message_circle.svg';
  static const String approaching = '$_dashboard/approaching.svg';
  static const String circleError = '$_dashboard/circle_error.svg';
  static const String crossCircle = '$_dashboard/cross_circle.svg';
  static const String timer = '$_dashboard/timer.svg';

  // Bottom navigation icons
  static const String navHome = '$_nav/nav_home.svg';
  static const String navCalendar = '$_nav/nav_calendar.svg';
  static const String navChecklist = '$_nav/nav_checklist.svg';
  static const String navBell = '$_nav/nav_bell.svg';
  static const String navMore = '$_nav/nav_more.svg';

  // Shared / common icons
  static const String search = '$_common/search.svg';
  static const String filter = '$_common/filter.svg';
  static const String bell = '$_common/bell.svg';
  static const String homeSmall = '$_common/home_small.svg';
  static const String chevronDown = '$_common/chevron_down.svg';
  static const String chevronRight = '$_common/chevron_right.svg';

  const AppAssets._();
}
