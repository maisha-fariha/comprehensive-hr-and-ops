import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../staff_medication_constants.dart';

/// The small glyph + "Tablet · Oral" / "Capsule · Oral" / "Injection ·
/// Subcut." caption shown under a dose card's medication name.
class MedicationRouteRow extends StatelessWidget {
  final MedicationRoute route;

  const MedicationRouteRow({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final icon = StaffMedicationConstants.routeIcon(route);
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 12);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon.svgAsset != null
            ? AppSvgIcon(icon.svgAsset!, size: 12, color: AppColors.textFaint)
            : Icon(icon.materialIcon, size: iconSize, color: AppColors.textFaint),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
        Flexible(
          child: Text(
            StaffMedicationConstants.routeLabel(route),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
