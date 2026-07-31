import '../../../core/constants/app_assets.dart';

/// Icon asset paths used by the Scheduling feature (Calendar / Board /
/// Requests tabs). Mirrors the shape of `AppAssets`.
///
/// Every icon below is reused from an existing exported Figma SVG in
/// `assets/icons/dashboard`, `assets/icons/nav` or `assets/icons/common`
/// (see [AppAssets]) because its glyph is a plausible visual match. No new
/// SVGs were exported for this feature — the Figma MCP asset-export quota
/// was exhausted before this feature's icons could be downloaded (see the
/// final report for the full list of Material Icon stand-ins used instead
/// where no existing SVG was a reasonable match).
abstract final class SchedulingAssets {
  /// Reused for the "open positions" warning glyph on calendar shift cards
  /// (e.g. "2 open · RN").
  static const String openPositionWarning = AppAssets.alertCircle;

  /// Reused (rotated 180° for "previous") for the month navigator chevrons.
  static const String monthChevron = AppAssets.chevronRight;

  const SchedulingAssets._();
}
