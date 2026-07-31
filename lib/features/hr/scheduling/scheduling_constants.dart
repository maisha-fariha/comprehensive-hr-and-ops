/// Spacing/sizing tokens for the Scheduling feature (Calendar / Board /
/// Requests tabs) that are measurably different from the shared tokens in
/// `lib/core/constants/app_dimens.dart` and therefore don't belong there
/// (see the feature's final report for the full list, in case any of these
/// should be centralized later).
///
/// Every other value used by this feature (radii, card padding, badge
/// shapes, status colors, etc.) reuses `AppDimens`/`AppColors` directly
/// because the Figma values matched an existing token.
abstract final class SchedulingDimens {
  /// The Scheduling screens use an 18px horizontal screen margin, whereas
  /// the Dashboard screen (`AppDimens.screenPaddingHorizontal`) uses 20px.
  static const double screenPaddingHorizontal = 18;

  /// Width of a single day cell in the week strip ("Mon 12", "Tue 13", ...).
  static const double calendarDayCellWidth = 48;

  /// Diameter of the small shift/day indicator dot under each day number.
  static const double calendarDayIndicatorSize = 5;

  /// Diameter of a facepile avatar circle on a Calendar shift card.
  static const double calendarAvatarSize = 34;

  /// Diameter of a facepile avatar circle on a Board coverage card.
  static const double boardAvatarSize = 38;

  /// Diameter of the single (non-facepile) avatar circle on a Request card.
  static const double requestAvatarSize = 44;

  /// Height of the linear staff-fill progress bar on shift cards.
  static const double progressBarHeight = 5;

  /// Height of a single segmented-tab pill inside the tab track.
  static const double segmentedTabHeight = 37;

  /// Height of the segmented-tab track (Calendar | Board | Requests).
  static const double segmentedTabTrackHeight = 45;

  const SchedulingDimens._();
}
