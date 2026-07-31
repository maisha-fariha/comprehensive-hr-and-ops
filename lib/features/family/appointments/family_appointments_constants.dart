/// Design/content tokens used by the Family "Appointments" feature that are
/// not already covered by `lib/core/constants/app_colors.dart`/
/// `app_dimens.dart`. Kept local to this feature per the module boundary
/// rules; centralize into the shared constants later if other features end
/// up needing the same values.
abstract final class FamilyAppointmentsConstants {
  /// Character limit shown by the "Add a Note" textarea's counter on the
  /// Create Appointment form (e.g. "63/250").
  static const int noteMaxLength = 250;

  /// Pre-filled note text shown when the "Visit" request-type segment is
  /// active, per the Figma "Request Visit - Appointments" screenshot.
  static const String visitPresetNote = "I'd like to celebrate John's birthday and have some family time.";

  const FamilyAppointmentsConstants._();
}
