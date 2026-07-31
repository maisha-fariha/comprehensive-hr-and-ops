import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_incidents_enums.dart';

/// The leading glyph on an incident card / details header: a warning
/// triangle for physical/behavioral incidents or an info circle for
/// care-related ones. Its color is passed in by the caller (driven by the
/// incident's severity, per the Figma screenshots) rather than owned here.
///
/// Icon note: [StaffIncidentIconKind.warning] reuses the existing
/// `alert_triangle.svg` (an exact visual match). No plain info-circle SVG
/// exists in `assets/icons/*` yet - `alert_circle.svg` turns out to be the
/// same rounded-triangle glyph at a different size (not a real circle), so
/// using it here would visually duplicate the warning icon. This uses the
/// Material `Icons.info_outline_rounded` as a temporary stand-in instead,
/// flagged in the feature's final report.
class StaffIncidentTypeIcon extends StatelessWidget {
  final StaffIncidentIconKind kind;
  final double size;
  final Color color;

  const StaffIncidentTypeIcon({super.key, required this.kind, required this.color, this.size = 21});

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case StaffIncidentIconKind.warning:
        return AppSvgIcon(AppAssets.alertTriangle, size: size, color: color);
      case StaffIncidentIconKind.info:
        return Icon(Icons.info_outline_rounded, size: ResponsiveHelper.getResponsiveSize(context, size), color: color);
    }
  }
}
