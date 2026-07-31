import '../../../core/constants/app_assets.dart';

/// Icon paths used by the "Team & Reports" feature (Team, Reports and
/// Messages tabs).
///
/// Most icons needed by this screen are already covered by an existing
/// exported SVG under `assets/icons/dashboard`, `assets/icons/nav` or
/// `assets/icons/common` (see [AppAssets]), so this file mostly gives each
/// reused icon a name scoped to this feature's own vocabulary, mirroring
/// the shape of [AppAssets] without editing that shared file. A handful of
/// icons have no matching exported asset (hamburger menu, a generic
/// document glyph, a bar-chart/sparkline glyph, a person-add glyph and a
/// graduation-cap glyph) - those are rendered with `Icons.*` Material
/// glyphs directly at the call site instead (see the final report for the
/// full list), since no new SVGs could be downloaded from Figma this round.
abstract final class TeamReportsAssets {
  // Header
  static const String composeMessage = AppAssets.notePencil;
  static const String search = AppAssets.search;
  static const String filter = AppAssets.filter;

  // Messages tab
  static const String unreadMessages = AppAssets.messageCircle;
  static const String groupAvatar = AppAssets.users;

  // Team tab
  static const String totalStaff = AppAssets.users;
  static const String onDutyNow = AppAssets.checkCircle;
  static const String openShifts = AppAssets.navCalendar;
  static const String scheduled = AppAssets.navCalendar;
  static const String pendingReview = AppAssets.clock;
  static const String critical = AppAssets.alertTriangle;
  static const String incidentAnalysis = AppAssets.alertTriangle;
  static const String medicationCompliance = AppAssets.pill;
  static const String staffAttendance = AppAssets.users;
  static const String urgentMessages = AppAssets.alertTriangle;
  static const String updatedCaptionClock = AppAssets.clock;
  static const String dateCaptionCalendar = AppAssets.navCalendar;

  // Shared chrome
  static const String chevronRight = AppAssets.chevronRight;

  const TeamReportsAssets._();
}
